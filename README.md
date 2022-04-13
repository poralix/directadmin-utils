<p align="center"><a href="https://directadmin.com"><img src="https://directadmin.com/img/logo/logo_directadmin.svg" alt="Directadmin" width="440px"/></a></p>

# directadmin-utils
test
A set of scripts for using on Directadmin servers with CustomBuild 2 or as self-standing solutions. 
If you need custom installation or support please feel free to request it here or on our site https://www.poralix.com/

# Structure

**./nginx/build_nginx** - A script to install either stable or mainline version of NGINX with custombuild2.

- A version number of NGINX mainline is taken from NGINX's trac site.
- A version number of NGINX stable is taken from the official NGINX's repository for CentOS 7

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

# NGINX 1.13.x with TLSv1.3 and Directadmin

Instructions: https://help.poralix.com/articles/nginx-with-tlsv1.3-on-directadmin-server

# Update Directadmin from beta / stable channel per needs

./core/updateda.sh

```
cd /root/
wget https://raw.githubusercontent.com/poralix/directadmin-utils/master/core/updateda.sh
chmod 755 updateda.sh
./updateda.sh beta
```

# Update Evolution skin in Directadmin

```
cd /root/
wget https://raw.githubusercontent.com/poralix/directadmin-utils/master/core/update_evolution.sh -O update_evolution.sh
chmod 755 update_evolution.sh
./update_evolution.sh
```

