#!/bin/bash

# Install Go programming language
# Arguments:
#   Version: The version of Go to install (e.g., 1.16.5)
# Example usage:
#   ./install-go.sh 1.16.5

# Check if version argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 1.25.1"
  exit 1
fi

VERSION=$1

wget https://go.dev/dl/go${VERSION}.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go${VERSION}.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
rm go${VERSION}.linux-amd64.tar.gz
source ~/.bashrc

# Verify installation
go version