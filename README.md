This script has been developed on a Mac. If it does not work for Linux, please raise a GitHub issue with details.

Setting up Perforce is going to involve two shells.  Open two and cd into 'client' in one, and 'server' in the other.

# 1. Server side - initial p4d boot

If you've run this script once already, and want to wipe out everything on the server side, do:

```bash
rm -rf depot journal server.locks db.* P4SSLDIR
```

Otherwise, the first script to run is:

```
$> ./initialize_perforce_server.sh
Generate SSL keys into P4SSLDIR/ directory using p4d
Start p4d server on *localhost* for next stage
Perforce db files in '.' will be created if missing...
Perforce Server starting...
```

At this stage a ctrl-c won't kill p4d (the perforce daemon). If you really wanted to kill it you'll have do something like:

```
$> ps aux | grep "p4d"
paul            1222019   0.0  0.0  2450180    668 s010  S+    6:59AM   0:00.01 grep p4d
paul            1222002   0.0  0.0  2475160   1780 s011  S     6:58AM   0:00.02 p4d -p ssl:localhost:1666
$> kill 1222002
```

# 2. Client side - population of admin account and setup

```
$> ./create-admin-account-and-more-security-stuff.sh 
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

You have to type 'yes' to get the client to accept the PKI fingerprint. Your key will be different to mine, and you're not 'paul' (most likely).