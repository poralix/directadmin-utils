#!/bin/bash
#
# A script to change domain's PHP version in console
# ======================================================
# Written by Alex s Grebenschikov (support@poralix.com)
# Version: 0.1-beta $ Mon Dec 14 00:50:41 NOVT 2015
# ======================================================

BN="`tput -Txterm bold`"
BF="`tput -Txterm sgr0`"

do_show_phpver()
{
    if [ "$1" == "1" ];
    then
        echo "${BN}${php_release[1]}${BF} as ${BN}${php_mode[1]}${BF}";
    elif [ "$1" == "2" ];
    then
        echo "${BN}${php_release[2]}${BF} as ${BN}${php_mode[2]}${BF}";
    else
        echo "<empty>";
    fi;
}

do_versions()
{
    echo -e "\t${BN}1${BF} stands for PHP (default): `do_show_phpver 1`";
    echo -e "\t${BN}2${BF} stands for PHP (additional): `do_show_phpver 2`";
}

do_usage()
{
    echo "#######################################################";
    echo "#          Written by Alex S Grebenschikov            #";
    echo "#######################################################";
    echo "Usage ${BN}$0 <domain> [<1|2>]${BF}";
    echo "PHP Versions (if omitted will show current settings): ";
    do_versions;
    exit 0;
}

data=`grep "^php[1,2]_" /usr/local/directadmin/custombuild/options.conf`;
php_release[1]=`echo $data | grep -o php1_release=[^\ ]* | cut -d\= -f2`
php_mode[1]=`echo $data | grep -o php1_mode=[^\ ]* | cut -d\= -f2`
php_release[2]=`echo $data | grep -o php2_release=[^\ ]* | cut -d\= -f2`
php_mode[2]=`echo $data | grep -o php2_mode=[^\ ]* | cut -d\= -f2`

if [ -z "$1" ];
then
    do_usage;
else
    DOMAIN=$1;
fi;

DO_NOT_CHANGE=0;

if [ -n "$2" ];
then
    if [ "$2" == "1" ];
    then
        PHP1_VER=$2;
        PHP2_VER=2;
    elif [ "$2" == "2" ];
    then
        PHP1_VER=$2;
        PHP2_VER=1;
    else
        do_usage;
    fi;
else
    DO_NOT_CHANGE=1
fi;

DCF=`ls -1 /usr/local/directadmin/data/users/*/domains/${DOMAIN}.conf 2>&1 | head -1`;

if [ ! -f "${DCF}" ];
then
    echo "[ERROR] Domain ${BN}${DOMAIN}${BF} does not seem to exist on the server!";
    exit 1;
fi;

owner=`echo ${DCF} | cut -d\/ -f7`

echo "Domain ${BN}${DOMAIN}${BF} found and is owned by the user ${BN}${owner}${BF}";

data=`grep "^php[1,2]_select=" ${DCF}`;
php1_select=`echo $data | grep -o php1_select=[^\ ]* | cut -d\= -f2`
php2_select=`echo $data | grep -o php2_select=[^\ ]* | cut -d\= -f2`

echo "Currently used: (no values mean defaults)";
echo -e "\tphp1_select: `do_show_phpver ${php1_select}` (${php1_select})";
echo -e "\tphp2_select: `do_show_phpver ${php2_select}` (${php2_select})";
echo "PHP Versions: ";
do_versions;

if [ "${DO_NOT_CHANGE}" == "1" ];
then
    echo "You did not specified new version, terminating here...";
    exit 0;
fi;

if [ -z ${php1_select} ] && [ -z ${php2_select} ];
then
    echo "php1_select=${PHP1_VER}" >> ${DCF};
    echo "php2_select=${PHP2_VER}" >> ${DCF};
else
    TF=`mktemp`;
    cat ${DCF}| grep -v "^php[1,2]_select=" > ${TF};
    cat ${TF} > ${DCF};
    echo "php1_select=${PHP1_VER}" >> ${DCF};
    echo "php2_select=${PHP2_VER}" >> ${DCF};
    rm -f ${TF};
fi;

echo "Rewriting virtual host....";
echo "action=rewrite&value=httpd&user=${owner}" >> /usr/local/directadmin/data/task.queue
/usr/local/directadmin/dataskq
/usr/local/directadmin/dataskq
echo "Finished...";

exit 0;
