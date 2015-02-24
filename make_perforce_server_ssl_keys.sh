#!/bin/sh

mkdir P4SSLDIR
export P4SSLDIR=$(pwd)/P4SSLDIR
chmod 700 P4SSLDIR/
echo "Generate SSL keys into P4SSLDIR/ directory using p4d"
p4d -Gc