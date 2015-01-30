#!/bin/sh 

export P4PORT=ssl:localhost:1666

p4 trust -f

you=$(p4 user -o | grep "^User:" | cut -f 2)

echo "Your perforce username: $you"

p4 user -o | sed '/^#/ d' > .p4_user
p4 user -i < .p4_user
rm .p4_user

echo "Set initial password (you'll have to do it twice). Eight or more chars ((upper case or lower case) and digits)"

p4 passwd 

echo "Use that password to log this shell into Perforce"

p4 -u $you login

p4 client -o | sed '/^#/ d' > .p4_client
p4 client -i < .p4_client
rm .p4_client

p4 protect -o > .p4_protect
p4 protect -i < .p4_protect
rm .p4_protect

p4 configure set security=3
