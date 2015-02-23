#!/bin/sh

export P4SSLDIR=$(pwd)/P4SSLDIR
echo "Starting p4d server on ssl:localhost:1666"
p4d -p ssl:localhost:1666