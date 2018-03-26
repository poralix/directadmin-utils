# Script nginx-apache-fix-ips.sh:

A script to add all IPs from Directadmin config into Apache
to address a bug with detecting a real IP in Apache behind Nginx
A bug introduced since Apache 2.4.33. It fails to read IPs from the file, as per instruction:

```
RemoteIPInternalProxyList /usr/local/directadmin/data/admin/ip.list
```

# Installation guide:

```
cd ~
wget -O nginx-apache-fix-ips.sh https://raw.githubusercontent.com/poralix/directadmin-utils/master/apache/nginx-apache-fix-ips.sh
chmod 755 nginx-apache-fix-ips.sh
./nginx-apache-fix-ips.sh
```
