#!/bin/bash
# =====================================================
# A script to run code with PHP versions
# installed by CustomBuild 2.x
# =====================================================
# Written by Alex Grebenschikov(support@poralix.com)
# =====================================================
# versions: 0.3-beta $ Tue May 15 14:15:13 +07 2018
#           0.2-beta $ Mon Dec 26 14:32:03 +07 2016
#           0.1-beta $ Tue Mar 17 12:40:51 NOVT 2015
# =====================================================
#set -x

LANG=C;
CMD="";
PHPVER="";
BN="`tput -Txterm bold`"
BF="`tput -Txterm sgr0`"

do_usage()
{
    echo "
# =====================================================
# A script to run code with PHP versions
# installed by CustomBuild 2.x
# =====================================================
# Written by Alex Grebenschikov(support@poralix.com)
# =====================================================

Usage:
    $0 <command-for-php>

Built-in commands:
    versions      - to list installed PHP versions
    full-versions - to show installed PHP versions
    update-all    - to update all installed versions (expert mode is used)
    --ini         - to show loaded ini files for PHP

Update-all (beta):
    DO NOT use it for mod_php!!!
    you can specify: suphp, fastcgi, php-fpm to force the mode

Other commands:
    You can run any other command supported by PHP,
    run 
        php --help 
    or 
        $0 --help
    to see a list of the options.
";
}

do_versions()
{
    PHP_DIR=`dirname ${PHP}`;
    IVER=`${PHP} -v 2>&1 | grep ^PHP.*built | awk '{print $2}'`;
    IVER_xx=`echo ${IVER} | awk -F '.' '{print $1$2}'`;
    IVER_xdx=`echo ${IVER} | awk -F '.' '{print $1"."$2}'`;
    AVER=`grep ^php${IVER_xx}: /usr/local/directadmin/custombuild/versions.txt | cut -d\: -f2`;

    if [ -z "${PHP_MODE}" ]; then
        PHP_MODE="mod_php";
        if [ -e "${PHP_DIR}/lsphp" ]; then
            PHP_MODE="lsphp";
        elif [ -e "/usr/local/php${IVER_xx}/etc/php-fpm.conf" ]; then
            PHP_MODE="php-fpm";
        elif [ -e "/usr/local/safe-bin/fcgid${IVER_xx}.sh" ]; then
            PHP_MODE="fastcgi";
        elif [ -e "/usr/local/suphp/sbin/suphp" ]; then
            PHP_MODE="suphp";
        fi;
    fi;

    UPDATE="";
    echo "";
    if [ -n "${AVER}" ]; then
        echo "Latest version of PHP ${IVER_xdx}: ${BN}${AVER}${BF}";
        if [ "${AVER}" != "${IVER}" ]; then
            UPDATE="${BN}Update is available${BF}";
            UPDATE="${UPDATE}\nTo update run: ${BN}cd /usr/local/directadmin/custombuild && ./build php_expert ${IVER_xx} ${PHP_MODE}${BF}";
        else
            UPDATE="To re-install run: ${BN}cd /usr/local/directadmin/custombuild && ./build php_expert ${IVER_xx} ${PHP_MODE}${BF}";
        fi;
    else
        echo "Latest version of PHP ${IVER_xdx}: N/A";
    fi;
    echo "Installed version of PHP ${IVER_xdx}: ${BN}${IVER}${BF} as ${BN}${PHP_MODE}${BF}";
    echo "Installed into ${BN}${PHP}${BF}";
    [ -n "${UPDATE}" ] && echo -e "${UPDATE}";
}

do_full_versions()
{
    ${PHP} -v 2>&1 | grep ^PHP;
}

do_update()
{
    cd /usr/local/directadmin/custombuild && ./build php_expert ${IVER_xx} ${PHP_MODE};
}

do_update_all()
{
    do_versions >/dev/null 2>&1;
    if [ "${AVER}" != "${IVER}" ]; then
        if [ "${PHP_MODE}" != "mod_php" ]; then

            if [ -n "${1}" ]; then
                case "${1}" in
                    suphp|fastcgi|php-fpm)
                        PHP_MODE="${1}";
                        ;;
                    *)
                        ;;
                esac;
            fi;

            echo "Updating version of PHP ${IVER_xdx}: ${BN}${IVER}${BF} as ${BN}${PHP_MODE}${BF}";
            echo "Installed into ${BN}${PHP}${BF}";
            echo "Will run /usr/local/directadmin/custombuild && ./build php_expert ${IVER_xx} ${PHP_MODE}";
            do_update ${PHP_MODE};
            echo "";
        else
            echo "DON'T USE THE SCRIPT FOR UPDATING PHP INSTALLED AS mod_PHP";
        fi;
    fi;
}

do_other()
{
    echo "${BN}Running for ${PHPVER}${BF}";
    ${PHP} $@;
    echo "";
}

if [ -z "$1" ];
then
    do_usage;
    exit 1;
else
    CMD=$1;
fi;

for PHP in `ls -1 /usr/local/php*/bin/php | sort -n`;
do
    PHPVER=`echo ${PHP} | cut -d\/ -f4`;

    case "${CMD}" in
        versions|version)
            do_versions;
            ;;
        full-versions|full-version)
            do_full_versions;
            ;;
        update-all)
            do_update_all $2;
            ;;
        *)
            do_other $@;
            ;;
    esac;
done;

echo "";

exit 0;
