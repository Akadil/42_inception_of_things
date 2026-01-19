#!/bin/bash

# Uninstall the Docker Engine, CLI, containerd, and Docker Compose Packages
sudo apt purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

# Remove images, containers, volumes, or custom configuraton files
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# Remove source list and Keyrings
sudo rm /etc/apt/sources.list.d/docker.sources
sudo rm /etc/apt/keyrings/docker.asc
