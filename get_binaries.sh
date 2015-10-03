#!/bin/sh

set -e 

echo "Some of these command under sudo, be prepared to enter your password...."
echo "========================================================================"
# The Perforce people didn't release Mac binaries for 15.2 and 15.3 for some reason
version=$(curl -s -l ftp://ftp.perforce.com/perforce/ | egrep '(r15|r16)' | cut -c 2-5 | sort -r -n | sed "/15.3/d" | sed "/15.2/d" | head -n 1)
echo "Download files from perforce for release ${version}."
curl -sS ftp://ftp.perforce.com/perforce/r${version}/bin.darwin90x86_64/p4 > p4 
curl -sS ftp://ftp.perforce.com/perforce/r${version}/bin.darwin90x86_64/p4d > p4d
echo "Move them to /usr/bin with the right permissions"
sudo mv p4 /usr/bin/
sudo mv p4d /usr/bin/
sudo chown root /usr/bin/p4*
sudo chmod 755 /usr/bin/p4*
echo "Done. p4 and p4d are in /usr/bin"

