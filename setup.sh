#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Install kubectl if not present ---
if command_exists kubectl; then
    echo "kubectl is already installed."
else
    echo "kubectl not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubectl
fi

# --- Install k3d if not present ---
if command_exists k3d; then
    echo "k3d is already installed."
else
    echo "k3d not found. Installing..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | sudo bash
fi


# Delete old cluster if it exists
sudo k3d cluster delete my-cluster

# Create a k3d cluster and map port 8080 to 80
sudo k3d cluster create my-cluster -p "8080:80@loadbalancer" --timeout 5m

# Give the cluster a moment to initialize before building and importing the image
sleep 10

# Build the custom PHP image
sudo docker build -t php-mysqli:latest ./php

# Import the custom PHP image into the k3d cluster
sudo k3d image import php-mysqli:latest -c my-cluster

# Give the cluster another moment to initialize before getting kubeconfig
sleep 10

# Get the kubeconfig for the new cluster
sudo k3d kubeconfig write my-cluster --output /tmp/kubeconfig

# Wait for the cluster to be ready
echo "Waiting for cluster to be ready..."
sudo kubectl --kubeconfig /tmp/kubeconfig wait --for=condition=ready node --all --timeout=300s

# Wait for the Traefik addon to be installed
echo "Waiting for Traefik addon to be installed..."
sleep 30

# Apply all kubernetes manifests in the k8s directory
sudo kubectl --kubeconfig /tmp/kubeconfig apply -f k8s/

# Wait for the web deployment to be ready
echo "Waiting for web deployment to be ready..."
sudo kubectl --kubeconfig /tmp/kubeconfig wait --for=condition=available --timeout=300s deployment/web

# Wait for the mysql deployment to be ready
echo "Waiting for mysql deployment to be ready..."
sudo kubectl --kubeconfig /tmp/kubeconfig wait --for=condition=available --timeout=300s deployment/mysql

# Create the typo3 database
echo "Creating typo3 database..."
MYSQL_POD=$(sudo kubectl --kubeconfig /tmp/kubeconfig get pods -l app=mysql -o jsonpath="{.items[0].metadata.name}")
sudo kubectl --kubeconfig /tmp/kubeconfig exec -i $MYSQL_POD -- mysql -uroot -ppassword -e "CREATE DATABASE typo3;"

# Pre-configure TYPO3
echo "Pre-configuring TYPO3..."
WEB_POD=$(sudo kubectl --kubeconfig /tmp/kubeconfig get pods -l app=web -o jsonpath="{.items[0].metadata.name}")
sudo kubectl --kubeconfig /tmp/kubeconfig exec -i $WEB_POD -c php -- /var/www/html/vendor/bin/typo3 install:setup \
    --database-driver mysqli \
    --database-host-name mysql \
    --database-user-name root \
    --database-user-password "password" \
    --database-name typo3 \
    --admin-user-name admin \
    --admin-password "Devdev1!" \
    --site-name "My TYPO3 Site" \
    --use-existing-database

# The application will be available at http://localhost
echo "############################################################"
echo "## Your application is now deployed."
echo "## You can access it at: http://localhost:8080"
echo "############################################################"

# Test the application
echo "Testing the application..."
if curl -s -L http://localhost:8080 | grep -q "/typo3/"; then
    echo "Verification successful: Redirect to /typo3/ found."
else
    echo "Verification failed: Did not redirect to /typo3/."
fi