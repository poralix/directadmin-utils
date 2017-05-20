# OpenSSL

A script to update OpenSSL version on CentOS servers to the latest 1.0.1 version.

```
cd /usr/local/directadmin/scripts/
wget https://raw.githubusercontent.com/poralix/directadmin-utils/master/openssl/openssl.install-1.0.1-primary.sh
chmod 755 openssl.install-1.0.1-primary.sh
./openssl.install-1.0.1-primary.sh
```

# Lock the rpm-package:

```
yum -y install yum-plugin-versionlock
yum versionlock openssl-*
```

to keep the openssl version away from rpm/yum updates.

# Error building curl 7.54.0 on Directadmin server against OpenSSL 1.0.2

Related: https://help.poralix.com/articles/error-building-curl-7.54.0-on-directadmin-with-openssl-1.0.2
