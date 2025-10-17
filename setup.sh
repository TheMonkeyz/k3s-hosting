#!/bin/bash

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

# The application will be available at http://localhost
echo "############################################################"
echo "## Your application is now deployed."
echo "## You can access it at: http://localhost:8080"
echo "############################################################"

# Test the application
curl http://localhost:8080