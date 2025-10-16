# k3s-hosting

This project provides a simple Nginx, PHP-FPM, and MySQL web hosting stack for K3s. It includes a script to set everything up.

## Prerequisites

Before you begin, you will need to have the following tools installed:

*   [k3d](https://k3d.io/#installation)
*   [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
*   [Docker](https://docs.docker.com/get-docker/)

## Getting Started

To get started, simply run the `setup.sh` script:

```bash
./setup.sh
```

This script will:

1.  Create a new k3d cluster named `my-cluster`.
2.  Deploy the Nginx, PHP-FPM, and MySQL stack to the cluster.
3.  Wait for the application to be ready.
4.  Print instructions on how to access the application at [http://localhost:8080](http://localhost:8080).

## Project Structure

*   `k8s/`: This directory contains all the Kubernetes manifest files for the application stack. The `ingress.yaml` file defines a Traefik `IngressRoute` to route traffic to the Nginx service.
*   `php/`: This directory contains the `Dockerfile` for the custom PHP image.
*   `setup.sh`: This script automates the setup of the cluster and the deployment of the application.
*   `README.md`: This file.