#!/bin/sh

export P4SSLDIR=$(pwd)/P4SSLDIR
a_proper_hostname=$(hostname)
echo "Starting p4d server on ssl:$a_proper_hostname:1666"
p4d -p ssl:$a_proper_hostname:1666