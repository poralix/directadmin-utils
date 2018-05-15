#!/bin/bash
# =====================================================
# A script to run code with PHP versions
# installed by CustomBuild 2.x
# =====================================================
# Written by Alex Grebenschikov(support@poralix.com)
# =====================================================
# versions: 0.4-beta $ Tue May 15 16:47:43 +07 2018
#           0.3-beta $ Tue May 15 14:15:13 +07 2018
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
    build         - to re-install all installed versions (expert mode is used)
    update        - to update all installed versions (expert mode is used)
    --ini         - to show loaded ini files for PHP

Build all (beta):
    DO NOT use it for mod_php!!!
    you can specify: suphp, fastcgi, php-fpm to force the mode

Update all (beta):
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

# Do the version investigation and update if it's requested
do_versions()
{
    PHP_MODE="${1}";
    PHP_DIR=`dirname ${PHP}`;
    IVER=`${PHP} -v 2>&1 | grep ^PHP.*built | awk '{print $2}'`;
    IVER_xx=`echo ${IVER} | awk -F '.' '{print $1$2}'`;
    IVER_xdx=`echo ${IVER} | awk -F '.' '{print $1"."$2}'`;
    AVER=`grep ^php${IVER_xx}: /usr/local/directadmin/custombuild/versions.txt | cut -d\: -f2`;

    DETECTED=0; # 0 - none, 1 - custombuild, 2 - autodetected
    RELEASE_VERSION='';

    OPTIONS_CONF="/usr/local/directadmin/custombuild/options.conf";
    if [ -z "${PHP_MODE}" ]; then
        c=$(egrep -c -m1 "^php[1,2]_release=${IVER_xdx}" "${OPTIONS_CONF}");
        if [ "${c}" == "1" ]; then
            RELEASE_VERSION=$(egrep "^php[0-9]_release=${IVER_xdx}" "${OPTIONS_CONF}" | cut -d\_ -f1);
            PHP_MODE=$(grep "${RELEASE_VERSION}_mode" "${OPTIONS_CONF}" | cut -d\= -f2);
            DETECTED=1;
        fi;
    fi;

    if [ -z "${PHP_MODE}" ]; then
        PHP_MODE="mod_php";
        if [ -e "${PHP_DIR}/lsphp" ]; then
            PHP_MODE="lsphp";
            DETECTED=2;
        elif [ -e "/usr/local/php${IVER_xx}/etc/php-fpm.conf" ]; then
            PHP_MODE="php-fpm";
            DETECTED=2;
        elif [ -e "/usr/local/safe-bin/fcgid${IVER_xx}.sh" ]; then
            PHP_MODE="fastcgi";
            DETECTED=2;
        elif [ -e "/usr/local/suphp/sbin/suphp" ]; then
            PHP_MODE="suphp";
            DETECTED=2;
        fi;
    fi;

    UPDATE="";
    echo "";
    if [ -n "${AVER}" ]; then
        echo "Latest version of PHP ${IVER_xdx}: ${BN}${AVER}${BF}";
        if [ "${AVER}" != "${IVER}" ]; then
            UPDATE="${BN}Update is available${BF}";
            UPDATE="${UPDATE}\nTo update run: ${BN}cd /usr/local/directadmin/custombuild && ./build php_expert ${IVER_xdx} ${PHP_MODE}${BF}";
        else
            UPDATE="To re-install run: ${BN}cd /usr/local/directadmin/custombuild && ./build php_expert ${IVER_xdx} ${PHP_MODE}${BF}";
        fi;
    else
        echo "Latest version of PHP ${IVER_xdx}: N/A";
    fi;
    case ${DETECTED} in
        0)
            DETECTED_LANG="not found";
            ;;
        1)
            DETECTED_LANG="found in custombuild as ${RELEASE_VERSION}";
            ;;
        2)
            DETECTED_LANG="auto detection";
            ;;
    esac;
    echo "Installed version of PHP ${IVER_xdx}: ${BN}${IVER}${BF} as ${BN}${PHP_MODE}${BF} (${DETECTED_LANG})";
    echo "Installed into ${BN}${PHP}${BF}";
    [ -n "${UPDATE}" ] && echo -e "${UPDATE}";
}

# Call to PHP for version number
do_full_versions()
{
    ${PHP} -v 2>&1 | grep ^PHP;
}

# Call to custombuild
do_update()
{
    cd /usr/local/directadmin/custombuild && ./build php_expert ${IVER_xdx} ${PHP_MODE};
}

# Build all installed PHP versions
do_build_all()
{
    do_versions >/dev/null 2>&1;
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

        echo "Re-installing version of PHP ${IVER_xdx}: ${BN}${IVER}${BF} as ${BN}${PHP_MODE}${BF}";
        echo "Installed into ${BN}${PHP}${BF}";
        echo "Will run /usr/local/directadmin/custombuild && ./build php_expert ${IVER_xdx} ${PHP_MODE}";
        do_update ${PHP_MODE};
        echo "";
    else
        echo "DON'T USE THE SCRIPT FOR UPDATING PHP INSTALLED AS mod_PHP";
    fi;
}

# Update all installed PHP versions
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
            echo "Will run /usr/local/directadmin/custombuild && ./build php_expert ${IVER_xdx} ${PHP_MODE}";
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

if [ ! -x "/usr/local/directadmin/directadmin" ]; then
    echo "Directadmin not found! Terminating...";
    exit 1;
fi;

if [ -z "$1" ];
then
    do_usage;
    exit 2;
else
    CMD=$1;
fi;

for PHP in `ls -1 /usr/local/php*/bin/php | egrep "\/php[0-9]{2}\/bin" | sort -n`;
do
    PHPVER=`echo ${PHP} | cut -d\/ -f4`;

    case "${CMD}" in
        versions|version)
            do_versions;
            ;;
        full-versions|full-version)
            do_full_versions;
            ;;
        build)
            do_build_all $2;
            ;;
        update)
            do_update_all $2;
            ;;
        *)
            do_other $@;
            ;;
    esac;
done;

echo "";

exit 0;
