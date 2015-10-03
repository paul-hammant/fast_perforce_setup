This script has been developed on a Mac. If it does not work for Linux, please raise a GitHub issue with details.

Three things going on here:

1.  Getting the essential Perforce binaries and putting them in the path.
2.  Setting up a perforce server and 
3.  Using it from a perforce client

There's a bonus about copying subversion history into perforce, but it is not really covered in this readme, see the accompanying blog entry: TODO.

# 1. Getting the perforce binaries.

There's a shell script adjacent to this README that goes and gets the latest 2015/2016 binaries for Perforce.  Both the Server (p4d) and the client (p4). It places them in /usr/bin. Lots of command live there, but many would suggest that it's not good practice to install things there yourself. 

For the 64bit Mac binaries:

```
$> path/to/get_binaries.sh

.. note the FTP traffic

```

For Linux or BSD, change one path element inside that with one of bin.freebsd100x86_64, bin.freebsd70x86_64 or bin.linux26x86_64.

This will put p4 and p4d in /usr/bin 

There are homebrew installs for Perforce server and client, but they're not up to date.

# 2. Server side - launching the Perforce daemon 'p4d'

Perhaps do this in a fresh directory - /Users/you/p4Server/

If you've run this script once already, and want to wipe out everything on the server side, do:

```bash
$> rm -rf depot journal server.locks db.* P4SSLDIR
```

Otherwise, the first script to run is the one to make PKI keys for the Perforce server:

```
$> path/to/make_perforce_server_ssl_keys.sh
Generate SSL keys into P4SSLDIR/ directory using p4d
Start p4d server on *localhost* for next stage
Perforce db files in '.' will be created if missing...
Perforce Server starting...
```

Second is launching the Perforce daemon on localhost:

```
$> path/to/run_perforce_server_localhost.sh
Start p4d server on *localhost* for next stage
Perforce db files in '.' will be created if missing...
Perforce Server starting...
```

Or, if you prefer, bound to your machine's hostname:

```
$> path/to/run_perforce_server_hostname.sh
Start p4d server on <yourHostName> for next stage
Perforce db files in '.' will be created if missing...
Perforce Server starting...
```

## killing p4d (if you need to)

The correct way to halt the Perforce daemon (running as a background process via the above):

```
export P4PORT=ssl:localhost:1666
p4 -u operator admin stop
p4 -u super admin stop
```

If that is not working, you can kill p4d by doing something like the following:

```
$> ps aux | grep "p4d"
paul            1222019   0.0  0.0  2450180    668 s010  S+    6:59AM   0:00.01 grep p4d
paul            1222002   0.0  0.0  2475160   1780 s011  S     6:58AM   0:00.02 p4d -p ssl:localhost:1666
$> kill 1222002
```
or run the scipt stop_perforce_server.sh that is in the same directory

# 3. Client side - population of admin account and setup

Again, perhaps in a fresh directory /Users/you/p4Client/

```
$> path/to/create-admin-account-and-more-security-stuff.sh 
******* WARNING P4PORT IDENTIFICATION HAS CHANGED! *******
It is possible that someone is intercepting your connection
to the Perforce P4PORT '127.0.0.1:1666'
If this is not a scheduled key change, then you should contact
your Perforce administrator.
The fingerprint for the mismatched key sent to your client is
63:BD:E5:63:43:E3:EA:54:6B:18:0F:B8:99:90:43:C5:5A:A2:74:3D
Are you sure you want to establish trust (yes/no)? yes
Added trust for P4PORT 'ssl:localhost:1666' (127.0.0.1:1666)
Your perforce username: paul
User paul not changed.
Set initial password (you'll have to do it twice). Eight or more chars ((upper case or lower case) and digits)
Enter new password: 
Re-enter new password: 
Password updated.
Use that password to log this shell into Perforce
Enter password: 
User paul logged in.
Client pauls-mba.local saved.
Protections saved.
For server 'any', configuration variable 'security' set to '3'
```

You have to type 'yes' to get the client to accept the PKI fingerprint. Your key will be different to mine, and you're not "paul" (most likely).

This has made you a working copy in a 'wc' directory, and a 'trunk' within that.

## Testing a commit

From the client directory, it is quite easy:

```
$> cd wc/trunk/
$> echo "hello world" > initial_perforce_file_that_can_be_deleted_later.txt
$> p4 add initial_perforce_file_that_can_be_deleted_later.txt 
//depot/trunk/initial_perforce_file_that_can_be_deleted_later.txt#1 - opened for add
$> p4 submit -d "test"
Submitting change 1.
Locking 1 files ...
add //depot/trunk/initial_perforce_file_that_can_be_deleted_later.txt#1
Change 1 submitted.
```
