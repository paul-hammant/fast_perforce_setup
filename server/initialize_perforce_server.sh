#!/bin/sh

rm -rf depot journal server.locks db.* P4SSLDIR
mkdir P4SSLDIR
export P4SSLDIR=$(pwd)/P4SSLDIR
chmod 700 P4SSLDIR/
echo "Generate SSL keys into P4SSLDIR/ directory using p4d"
p4d -Gc
echo "Start p4d server on *localhost* for next stage"
p4d -p ssl:localhost:1666