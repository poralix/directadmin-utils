#!/usr/bin/env bash
#############################################################################
#
# A script to install/upgrade Rainloop on Directadmin server
#   Written by Alex S Grebenschikov (support@poralix.com)
#   Version: v.0.3.0 $ Wed JUN  14 18:56:02 +07 2019
#
#   Versions:
#           - v.0.3.0 $ Wed JUN  1 21:22:02 +07 2023 # mean-cj Automation install directadmin-change-password plugin, Auto setup mysql, imap, admin password
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

DATE=$(date +"%F-%H-%M-%S")
color_reset=$(printf '\033[0m')
color_green=$(printf '\033[32m')
color_red=$(printf '\033[01;31m')
echo_green () { echo "${color_green}$*${color_reset}"; }
echo_red () { echo "${color_red}$*${color_reset}"; }

echo_green "------------------------------------------------------------------"
echo_green "[RUN]           Setup Rainloop for Directadmin"
echo_green "------------------------------------------------------------------"

URL="https://www.rainloop.net/repository/webmail/rainloop-latest.zip";
SOURCE="rainloop-latest.zip"
MYSQL_DB="da_rainloop";
MYSQL_USER="da_rainloop";
MYSQL_HOST="localhost";
MYSQL_PASSWORD="";
MYSQL_ACCESS_HOST="localhost";
RAINLOOP_ADMIN_PASSWORD="";

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

        webapps:webapps "${HTAF}";
        echo "Deny from all" > "${HTAF}";
        echo "<IfModule mod_autoindex.c>" >> "${HTAF}";
        echo "	Options -Indexes" >> "${HTAF}";
        echo "</ifModule>" >> "${HTAF}";
    fi;
}

yesno=""
while [  "$yesno" != "yes" ]; do
  read -erp "Enter rainloop \"admin\" password: " RAINLOOP_ADMIN_PASSWORD </dev/tty
  echo "================================================================"
  echo "----------- Rainloop admin password is:  ${color_green}${RAINLOOP_ADMIN_PASSWORD}${color_reset} "
  echo "================================================================"
  read -erp "Please confirm ? [yes,no]: " yesno </dev/tty
done

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
rm -f "${SOURCE}"

# GENERATE HTACCESS FILE
genhtaccess;

echo "[OK] Create a configs & domains directory";
mkdir -p /var/www/html/rainloop/data/_data_/_default_/domains/
mkdir -p /var/www/html/rainloop/data/_data_/_default_/configs/

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

echo "[OK] Protecting anothers domain @gmail , @yaho, @outlook.com ...";
echo "outlook.com,qq.com,yahoo.com,gmail.com,hotmail.com,live.com" > /var/www/html/rainloop/data/_data_/_default_/domains/disabled

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

# MYSQL DB
${MYSQL} ${MYSQL_OPT} -e "USE ${MYSQL_DB};" --host=${MYSQL_HOST} 2>/dev/null;
RETVAL=$?;
MYSQL_PASSWORD=$(genpass 16);

if [ "${RETVAL}" == "1" ]; then
    echo_green "[OK] Created new database $MYSQL_DB ";
    ${MYSQL} ${MYSQL_OPT} -e "CREATE DATABASE ${MYSQL_DB};" --host=${MYSQL_HOST} 2>&1;
    echo "";
    echo "[OK] Database created: ";
    echo "  - MySQL user: ${MYSQL_USER}";
    echo "  - MySQL password: ${MYSQL_PASSWORD}";
    echo "  - MySQL DB name: ${MYSQL_DB}";
    echo "  - MySQL host: ${MYSQL_HSOT}";
else
    echo "[OK] Change exists database $MYSQL_DB password $MYSQL_PASSWORD ";
fi;

echo "[OK] Grant and upadte database password of ${MYSQL_DB}";
${MYSQL} ${MYSQL_OPT} -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,LOCK TABLES,INDEX ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'${MYSQL_ACCESS_HOST}' IDENTIFIED BY '${MYSQL_PASSWORD}';" --host=${MYSQL_HOST} 2>&1;

# fix bug rainloop v1.7.0
if [ -d "/var/www/html/rainloop/rainloop/v/1.17.0" ]; then
    sed -ie 's/private $sLogginedUser;/private $sLogginedUser;\n        private $bResponseBufferChanged;/' \
        /var/www/html/rainloop/rainloop/v/1.17.0/app/libraries/MailSo/Imap/ImapClient.php
    sed -ie 's/private $sUpdateAuthToken;/private $sUpdateAuthToken;\n        private $bIsAjax;/' \
        /var/www/html/rainloop/rainloop/v/1.17.0/app/libraries/RainLoop/Actions.php
    sed -ie 's/private $aAdditionalParts;/private $aAdditionalParts;\n        private $aAjaxFilters;/' \
        /var/www/html/rainloop/rainloop/v/1.17.0/app/libraries/RainLoop/Plugins/Manager.php
fi

echo "";
echo_green "[OK] Rainloop - Starting configuration"
php -d error_reporting=32757 -r "$(tr -d "\n" <<EOF
    \$_ENV['RAINLOOP_INCLUDE_AS_API'] = true;
    include '/var/www/html/rainloop/index.php';

    \$oConfig = \RainLoop\Api::Config();
    \$oConfig->SetPassword('$RAINLOOP_ADMIN_PASSWORD');

    echo "[OK] Rainloop - Config database [$MYSQL_DB, $MYSQL_USER, $MYSQL_PASSWORD] to rainloop\n";
    \$oConfig->set('contacts','enable',true);
    \$oConfig->set('contacts','pdo_dsn', 'mysql:host=localhost;port=3306;dbname=$MYSQL_DB');
    \$oConfig->set('contacts','pdo_user','$MYSQL_USER');
    \$oConfig->set('contacts','pdo_password','$MYSQL_PASSWORD');

    echo  \$oConfig->Save() ? '[OK] Rainloop - Custom config save. ' : '[ERROR] Cannot save custom config.';
    echo "\\n";

    \$oActions = \RainLoop\Actions::NewInstance();
    \$oActions->SetActionParams([
        'Login' => 'admin',
        'Password' => '$RAINLOOP_ADMIN_PASSWORD',
    ],'DoAdminLogin');
    echo \$oActions->DoAdminLogin() ? '[OK] Rainloop - Admin Logined.' : '[ERROR] Admin cannot login';
    echo "\\n";

    /*app/libraries/RainLoop/Model/Domain.php*/
    \$oDomain = \RainLoop\Model\Domain::NewInstance(
        '*',  /*name*/
        '127.0.0.1', 993, 1, 0, /*imap  [host,port,secure,shortlogin]*/
        0 , 0 , 4190 , 0, /*Sieve configuration*/
        '127.0.0.1', 465, 1, 0 , 1, /*smtp [host,port,secure,shortlogin,authentication]*/
        false, ''
    );
    \$oDomainProvider = \$oActions->DomainProvider();
    echo \$oDomainProvider->Save(\$oDomain) ? '[OK] Rainloop - IMAP config save.' : '[ERROR] Cannot save IMAP config';
    echo "\\n";

    \$plugin_packages = (\$plugin_packages = \$oActions->DoAdminPackagesList()) ? \$plugin_packages['Result']['List'] : [];
    \$plugin_installed = \$oActions->Plugins()->InstalledPlugins();

    \$plugin_installation = array('directadmin-change-password','add-x-originating-ip-header');
    foreach( \$plugin_installation as \$plugin_installation_id )
    {
        if(!in_array_recursive(\$plugin_installation_id,\$plugin_installed)){
            \$plugin = getArrayBySubArrayKey(\$plugin_packages,'id',\$plugin_installation_id);
            if(!\$plugin) continue;

            \$oActions->SetActionParams([
                'Id' => \$plugin['id'],
                'Type' => 'plugin',
                'File' => \$plugin['file']
            ],'AdminPackageInstall');
            echo \$oActions->DoAdminPackageInstall() ? "[OK] Rainloop - Plugin [{\$plugin['id']}] v{\$plugin['version']} installed" : "[ERROR] Cannot install [{\$plugin['id']}]";
            echo "\\n";
        }
        else {
            echo "[OK] Rainloop - Plugin [{\$plugin_installation_id}] enabled\\n";
        }
    }

    \$oConfig->set('plugins','enable',true);
    \$oConfig->set('plugins','enabled_list', implode(',',\$plugin_installation));
    \$oConfig->Save();

    function getArrayBySubArrayKey(\$array, \$subArrayKey, \$subArrayValue) {
        \$subArray = array_column(\$array, null, \$subArrayKey);
        if (isset(\$subArray[\$subArrayValue])) { return \$subArray[\$subArrayValue]; }
        return null;
    }

    function in_array_recursive(\$needle, \$haystack) {
        \$it = new RecursiveIteratorIterator(new RecursiveArrayIterator(\$haystack));
        foreach(\$it AS \$element) { if(\$element == \$needle) { return true; } } return false;
    }

    echo "\\n";
EOF
)"

echo "";
echo "[OK] Go to http://$(hostname)/rainloop/?admin to complete and configure installation!";
echo "  Default username/password for admin access:";
echo "  - admin";
echo "  - $RAINLOOP_ADMIN_PASSWORD";

if ! grep -qs "error_reporting" /var/www/html/rainloop/index.php; then
    echo_green "[OK] Rainloop - Disable php error_reporting()"
    sed -i "2 i error_reporting(0);" /var/www/html/rainloop/index.php
fi

echo "";
die "[OK] Rainloop installation completed!" 0;
