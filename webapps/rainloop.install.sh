#!/usr/bin/env bash
#############################################################################
#
# A script to install/upgrade Rainloop on Directadmin server
#   Written by Alex S Grebenschikov (support@poralix.com)
#   Version: v.0.2.1 $ Thu Aug  1 18:56:02 +07 2019
#
#   Versions:
#           - v.0.2.1 $ Thu Aug  1 18:56:02 +07 2019
#           - v.0.2.0 $ Thu Aug  9 16:00:01 +07 2018
#           - v.0.1.1 $ Tue Aug  8 10:45:20 +07 2017
#           - v.0.1 $ Wed Jul 12 15:49:10 +07 2017
#
# TO DO:
#   - autoconfigure new installation
#
#############################################################################
# set -x

#URL="https://www.rainloop.net/repository/webmail/rainloop-community-latest.zip";
#SOURCE="rainloop-community-latest.zip"
URL="https://www.rainloop.net/repository/webmail/rainloop-latest.zip";
SOURCE="rainloop-latest.zip"
MYSQL_DB="da_rainloop";
MYSQL_USER="da_rainloop";
MYSQL_HOST="localhost";
MYSQL_PASSWORD="";
MYSQL_ACCESS_HOST="localhost";

die()
{
    echo "$1"; exit $2;
}

genpass()
{
    tr -cd 'a-zA-Z0-9' < /dev/urandom 2>/dev/null | head -c${1:-`perl -le 'print int rand(7) + 10'`}
}

genhtaccess()
{
    HTAF="/var/www/html/rainloop/data/.htaccess";
    if [ -f "${HTAF}" ]; then
        echo "[OK] Found ${HTAF} file. Make sure it blocks access to the data folder over HTTP/HTTPS (Apache and NGINX/Apache only)...";
        grep -m1 -q "^Deny from all" "${HTAF}" || echo -e "\nDeny from all" >> "${HTAF}";
    else
        echo "[OK] Creating ${HTAF} file to block access to the data folder over HTTP/HTTPS (Apache and NGINX/Apache only)...";
        touch "${HTAF}";
        chown webapps:webapps "${HTAF}";
        echo "Deny from all" > "${HTAF}";
        echo "<IfModule mod_autoindex.c>" >> "${HTAF}";
        echo "	Options -Indexes" >> "${HTAF}";
        echo "</ifModule>" >> "${HTAF}";
    fi;
}

MYSQL="/usr/local/bin/mysql";
[ -x "${MYSQL}" ] || MYSQL="/usr/bin/mysql";
[ -x "${MYSQL}" ] || die "Could not find MySQL bin! Terminating..." 1;
MYSQL_OPT="--defaults-extra-file=/usr/local/directadmin/conf/my.cnf";
[ -f "/usr/local/directadmin/conf/my.cnf" ] || die "Could find MySQL settings for Directadmin! Terminating..." 1;

# DOWNLOAD SOURCE FILE
cd /var/www/html || die "Directory /var/www/html does not exist! Terminating..." 1;
wget -O "${SOURCE}" "${URL}";

# UNPACK SOURCE FILE
[ -s "${SOURCE}" ] || die "Download failed or file is corrupted! Terminating..." 1;
[ -x "/usr/bin/unzip" ] || die "Unzip is not installed on your server! Terminating...";
/usr/bin/unzip -o "${SOURCE}" -d rainloop;

# GENERATE HTACCESS FILE
genhtaccess;

# SET CORRECT PERMISSIONS
[ -d "/var/www/html/rainloop" ] || die "Rainloop failed to unpack! Terminating...";
echo "[OK] Setting correct permissions on folders of RainLoop...";
find /var/www/html/rainloop/ -type d -exec chmod 755 {} \;
echo "[OK] Setting correct permissions on files of RainLoop...";
find /var/www/html/rainloop/ -type f -exec chmod 644 {} \;
echo "[OK] Settings correct owner of RainLoop files and folders...";
chown -R webapps:webapps /var/www/html/rainloop/;

# PROTECT DATA FOLDER
echo "[OK] Protecting RainLoop data files and folders...";
chmod 700 /var/www/html/rainloop/data;

# UPDATE ALIASES WITH CUSTOMBUILD
[ -d "/usr/local/directadmin/custombuild" ] || die "CustomBuild not found! Terminating...";
[ -d "/usr/local/directadmin/custombuild/custom/" ] || mkdir "/usr/local/directadmin/custombuild/custom/"
[ -f "/usr/local/directadmin/custombuild/custom/webapps.list" ] || touch "/usr/local/directadmin/custombuild/custom/webapps.list";
c=$(grep -c "rainloop=rainloop" /usr/local/directadmin/custombuild/custom/webapps.list);
if [ "$c" == "0"  ]; then
    echo "[OK] Updating web-server configuration for RainLoop...";
    echo "rainloop=rainloop" >> /usr/local/directadmin/custombuild/custom/webapps.list;
    cd /usr/local/directadmin/custombuild;
    ./build rewrite_confs;
fi;

# CREATE MYSQL DB
if [ ! -f "/var/www/html/rainloop/data/INSTALLED" ]; then
    ${MYSQL} ${MYSQL_OPT} -e "USE ${MYSQL_DB};" --host=${MYSQL_HOST} 2>/dev/null;
    RETVAL=$?;

    echo "";
    echo "[OK] Go to http://$(hostname)/rainloop/?admin to complete and configure installation!";
    echo "  Default username/password for admin access:";
    echo "  - admin";
    echo "  - 12345";

    if [ "${RETVAL}" == "1" ]; then
        MYSQL_PASSWORD=$(genpass 16);
        ${MYSQL} ${MYSQL_OPT} -e "CREATE DATABASE ${MYSQL_DB};" --host=${MYSQL_HOST} 2>&1;
        ${MYSQL} ${MYSQL_OPT} -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,LOCK TABLES,INDEX ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'${MYSQL_ACCESS_HOST}' IDENTIFIED BY '${MYSQL_PASSWORD}';" --host=${MYSQL_HOST} 2>&1;
        echo "";
        echo "[OK] Database created: ";
        echo "  - MySQL user: ${MYSQL_USER}";
        echo "  - MySQL password: ${MYSQL_PASSWORD}";
        echo "  - MySQL DB name: ${MYSQL_DB}";
        echo "  - MySQL host: ${MYSQL_HSOT}";
    fi;

    die "[OK] Installation completed!" 0;
fi;

# EXIT
echo "";
die "[OK] Upgrade completed!" 0;
