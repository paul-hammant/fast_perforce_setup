#!/bin/sh
echo "Some of these command under sudo, be prepared to enter your password...."
echo "========================================================================"
version=$(curl -l ftp://ftp.perforce.com/perforce/ | egrep '(r15|r16)' | cut -c 2-5 | sort -r -n | head -n 1)
echo "Download files from perforce for release ${version}"
ftp ftp://ftp.perforce.com/perforce/r${version}/bin.darwin90x86_64/p4 . 
ftp ftp://ftp.perforce.com/perforce/r${version}/bin.darwin90x86_64/p4d . 
echo "Move them to /usr/bin with the right permissions"
sudo mv p4 /usr/bin/
sudo mv p4d /usr/bin/
sudo chown root /usr/bin/p4*
sudo chmod 755 /usr/bin/p4*
echo "Done. p4 and p4d are in /usr/bin"