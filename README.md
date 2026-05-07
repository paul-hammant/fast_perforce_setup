This script has been developed on a Mac. If it does not work for Linux, please raise a GitHub issue with details.

Three things going on here:

1.  Getting the essential Perforce binaries and putting them in the path.
2.  Setting up a perforce server and
3.  Using it from a perforce client

There's a bonus about copying subversion history into perforce, but it is not really covered in this readme, see the accompanying blog entry: TODO.

# 1. Getting the perforce binaries.

For Mac, the client comes via homebrew-cask, but the server doesn't have a recipe yet:

```
$> brew install --cask p4
$> curl -sS https://ftp.perforce.com/perforce/r24.2/bin.macosx12u_arm64/p4d > /usr/local/bin/p4d
$> chmod +x /usr/local/bin/p4d
```

For Intel Macs, swap `bin.macosx12u_arm64` for `bin.macosx12u_x86_64` in the URL above.

## Linux

On Debian / Ubuntu, Perforce ships an APT repository with both the `p4` client and the `p4d` server:

```
$> curl -fsSL https://package.perforce.com/perforce.pubkey | sudo gpg --dearmor -o /usr/share/keyrings/perforce.gpg
$> echo "deb [signed-by=/usr/share/keyrings/perforce.gpg] https://package.perforce.com/apt/ubuntu noble release" | sudo tee /etc/apt/sources.list.d/perforce.list
$> sudo apt update
$> sudo apt install helix-cli helix-p4d
```

Substitute `noble` for the codename matching your distro — currently Perforce publishes `bionic`, `focal`, `jammy`, and `noble` (check https://package.perforce.com/apt/ubuntu/dists/ for the live list). If you're on a release newer than the latest published LTS (e.g. Ubuntu 25.10 "questing"), pinning to `noble` works fine — the binaries are self-contained.

The package installs `p4` to `/usr/bin/p4` and `p4d` to `/usr/sbin/p4d`. `/usr/sbin` isn't always on a non-root user's PATH, so if `which p4d` comes up empty, either add it to PATH or invoke `p4d` by full path. The package also enables a `p4dctl.service` systemd unit for managing server instances — the scripts in this repo run `p4d` directly as your user instead, so you can ignore `p4dctl` and skip the `configure-p4d.sh` step the package suggests.

On RHEL / Rocky / Fedora:

```
$> sudo rpm --import https://package.perforce.com/perforce.pubkey
$> sudo tee /etc/yum.repos.d/perforce.repo <<'EOF'
[perforce]
name=Perforce
baseurl=https://package.perforce.com/yum/rhel/9/x86_64
enabled=1
gpgcheck=1
EOF
$> sudo dnf install helix-cli helix-p4d
```

(Adjust the `9` to `7` or `8` to match your RHEL major version.)

If you'd rather grab the raw binaries (e.g. for BSD, Alpine, or an air-gapped box), they live under https://ftp.perforce.com/perforce/ — pick the latest release directory and the `bin.linux26x86_64/` (or matching arch) folder, then drop `p4` and `p4d` into `/usr/local/bin` and `chmod +x` them.

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
