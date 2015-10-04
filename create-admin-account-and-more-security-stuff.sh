#!/bin/sh 

export P4PORT=ssl:localhost:1666

set -e

p4 trust -f

you=$(p4 user -o | grep "^User:" | cut -f 2)

echo "Your perforce username: $you"

p4 user -o | sed '/^#/ d' > .p4_user
more .p4_user
p4 user -i < .p4_user
rm .p4_user

echo "Set initial password (you'll have to do it twice)."
echo "EIGHT or more chars ((upper case or lower case) and digits)."

p4 passwd 

echo "Use that password to log this shell into Perforce"

p4 -u $you login

p4 client -o 2>&1 | sed '/^#/ d' > .p4_client
p4 client -i < .p4_client
rm .p4_client

p4 protect -o > .p4_protect
p4 protect -i < .p4_protect
rm .p4_protect

p4 configure set security=3

p4 client -o 2> err.txt > /dev/null
if [[ ! -z $(grep "The security level of this server requires the password to be reset" "err.txt") ]]; then echo "Your Perforce password not is secure enough for the server. Exiting"; exit 1; fi
rm err.txt

mkdir wc

p4 client -o | sed '/^#/ d' > .p4_client
yourClient=$(cat .p4_client | grep "^Client:" | cut -f 2)
echo "Your Perforce client name: $yourClient"
yourWorkingCopyDirectory=$(cat .p4_client | grep "^Root:" | cut -f 2)/wc
echo "Your working copy directory: $yourWorkingCopyDirectory"
cat .p4_client | sed '/^Root:/ d' | sponge .p4_client
echo "\n\nRoot: ${yourWorkingCopyDirectory}" >>  .p4_client
p4 client -i < .p4_client
rm .p4_client

#p4 fstat -Olhp -Dl -F ^headAction=delete & ^headAction=move/delete //depot/* //depot/myTrunk/*
mkdir ${yourWorkingCopyDirectory}/trunk
echo "hello" > ${yourWorkingCopyDirectory}/trunk/initial_perforce_file_that_can_be_deleted_later.txt
p4 add -d ${yourWorkingCopyDirectory}/trunk/initial_perforce_file_that_can_be_deleted_later.txt
p4 submit -d "first commit"

p4 configure set server.allowfetch=3
p4 configure set server.allowpush=3
p4 configure set server.allowrewrite=0

echo "Your Perforce Client: ${yourClient}, and it's working copy dir: ${yourWorkingCopyDirectory}"
