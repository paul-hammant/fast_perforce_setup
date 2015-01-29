#!/bin/sh 

you=$(p4 -p localhost:1666 user -o | grep "^User:" | cut -f 2)

echo "Hi " $you " (your perforce username)"

p4 -p ssl:localhost:1666 user -o | sed '/^#/ d' > .p4_user
p4 -p ssl:localhost:1666 user -i < .p4_user
rm .p4_user

echo "Set initial password (you'll have to do it twice). Eight or more upper case and lower case and digits"

p4 -p ssl:localhost:1666 passwd 

echo "Use that password to log this shell into Perforce"

p4 -p ssl:localhost:1666 -u $you login

p4 -p ssl:localhost:1666 client -o | sed '/^#/ d' > .p4_client
p4 -p ssl:localhost:1666 client -i < .p4_client
rm .p4_client

p4 -p ssl:localhost:1666 protect -o > .p4_protect
p4 -p ssl:localhost:1666 protect -i < .p4_protect
rm .p4_protect

p4 -p ssl:localhost:1666 configure set security=3
