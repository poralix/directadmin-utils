# A simple script to update Directadmin from beta/stable channel per your needs:

**updateda.sh**

# Installation

Install it:

```
cd /root/
wget https://raw.githubusercontent.com/poralix/directadmin-utils/master/core/updateda.sh
chmod 755 updateda.sh
```

# Usage

Run to install a pre-release version of Directadmin:

```
./updateda.sh beta
```

Run to install a stable version of Directadmin:

```
./updateda.sh stable
```

The script will try and auto-detect UID and LID. If it fails then you will need to run 
the script with options --lid=1234 and --uid=567

```
./updateda.sh beta --lid=1234 --uid=567
```

or

```
./updateda.sh stable --lid=1234 --uid=567
```

where you will need to use 

- a real License ID instead of 1234
- a real Client ID instead of 567

You can find License ID and Client ID on a page "Licensing/Updates" in Directadmin at admin level.

# Override OS 

run the command to list supported OS with codes:

```
./updateda.sh list_os
```

Example of usage:

```
./updateda.sh beta --os=c9
```

you can find codes for OS below.

# Supported OS with their codes

```
====================  ======
RedHat                Code
====================  ======
RedHat_7.2            a1
RedHat_7.3            a2
RedHat_8.0            a3
RedHat_9.0            a4
====================  ======
Fedora                Code
====================  ======
Fedora_1.0            b1
Fedora_3              b2
Fedora_4              b3
Fedora_5              b4
Fedora_7              b5
Fedora_9              b6
====================  ======
CentOS                Code
====================  ======
ES_3.0                c1
ES_4.0                c2
ES_4.4                c3
ES_4.1_64             c4
ES_5.0                c5
ES_5.0_64             c6
ES_6.0                c7
ES_6.0_64             c8
ES_7.0_64             c9
====================  ======
FreeBSD               Code
====================  ======
FreeBSD_4.8           d1
FreeBSD_5.1           d2
FreeBSD_5.3           d3
FreeBSD_6.0           d4
FreeBSD_7.0           d5
FreeBSD_7.1_64        d6
FreeBSD_8.0_64        d7
FreeBSD_9.1_32        d8
FreeBSD_9.0_64        d9
FreeBSD_11.0_64       d10
====================  ======
Debian                Code
====================  ======
Debian_3.1            e1
Debian_5              e2
Debian_5_64           e3
Debian_6              e4
Debian_6_64           e5
Debian_7              e6
Debian_7_64           e7
Debian_8_64           e8
Debian_9_64           e9
```

# History of changes

- Version: 0.4-beta (Tue May 22 12:53:02 +07 2018): Read LID/UID from Directadmin binary, other fixes
- Version: 0.3 (Wed Mar 14 17:49:04 +07 2018): added detection of os_override in directadmin
