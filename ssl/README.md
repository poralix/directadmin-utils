# Script install_server_wide_cert.sh

This script is written to be used on a directadmin powered server and can
be used to do a quick installation of a SSL cert/key for server-wide usage
i.e. SSL cert used by default (on hostname) in Apache/Nginx, Exim/Dovecot.

# Installation

```
cd /usr/local/directadmin/scripts/custom
wget -O ./install_server_wide_cert.sh https://raw.githubusercontent.com/poralix/directadmin-utils/master/ssl/install_server_wide_cert.sh
chmod 700 ./install_server_wide_cert.sh
```

# Usage

```
cd /usr/local/directadmin/scripts/custom
./install_server_wide_cert.sh <PATH_TO_CERT> <PATH_TO_KEY> [<PATH_TO_CACERT>]
```

- PATH_TO_CERT    - a full or relative path to a CERT you want to install
- PATH_TO_KEY     - a full or relative path to a KEY you want to install
- PATH_TO_CACERT  - a full or relative path to a CACERT you want to install

# CACERT

The cacerts file is a collection of trusted certificate authority (CA) certificates. They are Intermediate/chain certificates.

# Author

Alex S Grebenschikov
