# directadmin-utils

A set of scripts for using on Directadmin servers with CustomBuild 2 or as self-standing solutions. 
If you need custom installation or support please feel free to request it here or on our site http://www.poralix.com/

# Structure

**./nginx/build_nginx** - A script to install a mainline version of NGINX with custombuild2. 
A version number of NGINX mainline is taken from NGINX's trac site.

**./nginx/build_nginx2** - A script to install a mainline version of NGINX with custombuild2. 
A version number of NGINX mainline is taken from versions.txt of Directadmin.

# Installation of script for NGINX mainline

for version 1:

```
cd /usr/local/directadmin/custombuild/
wget https://raw.githubusercontent.com/poralix/directadmin-utils/master/nginx/build_nginx -O /usr/local/directadmin/custombuild/build_nginx
chmod 755 ./build_nginx
./build_nginx
```

for version 2:

```
cd /usr/local/directadmin/custombuild/
wget https://raw.githubusercontent.com/poralix/directadmin-utils/master/nginx/build_nginx2 -O /usr/local/directadmin/custombuild/build_nginx2
chmod 755 ./build_nginx2
./build_nginx2
```
