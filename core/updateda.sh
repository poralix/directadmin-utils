#!/usr/bin/env bash
#######################################################################################
#                                                                                     #
#       A script to update Directadmin from beta or stable channel                    #
#                                                                                     #
#######################################################################################
#                                                                                     #
#            Versions:                                                                #
#                      0.10-beta (Tue Feb 22 12:52:29 +07 2022)                       #
#                      0.9-beta (Thu Feb 17 13:05:52 +07 2022)                        #
#                      0.8-beta (Sat Feb 12 20:39:09 +07 2022)                        #
#                      0.7-beta (Fri Oct  1 10:23:57 +07 2021)                        #
#                      0.6-beta (Mon Sep 30 02:35:39 EDT 2019)                        #
#                      0.5-beta (Thu Jun 27 10:19:12 +07 2019)                        #
#                      0.4-beta (Tue May 22 12:53:02 +07 2018)                        #
#                      0.3      (Wed Mar 14 17:49:04 +07 2018)                        #
#            Written by: Alex Grebenschikov (zEitEr)                                  #
#            Site: www.poralix.com  E-mail: support@poralix.com                       #
#                                                                                     #
#######################################################################################
#######################################################################################
##                                                                                    #
##   MIT License                                                                      #
##                                                                                    #
##   Copyright (c) 2016-2021 Alex Grebenschikov, Poralix, www.poralix.com             #
##                                                                                    #
##   Permission is hereby granted, free of charge, to any person obtaining a copy     #
##   of this software and associated documentation files (the "Software"), to deal    #
##   in the Software without restriction, including without limitation the rights     #
##   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell        #
##   copies of the Software, and to permit persons to whom the Software is            #
##   furnished to do so, subject to the following conditions:                         #
##                                                                                    #
##   The above copyright notice and this permission notice shall be included in all   #
##   copies or substantial portions of the Software.                                  #
##                                                                                    #
##   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR       #
##   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,         #
##   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE      #
##   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER           #
##   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,    #
##   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE    #
##   SOFTWARE.                                                                        #
##                                                                                    #
#######################################################################################

BN="`tput -Txterm bold`";
BF="`tput -Txterm sgr0`";
DA_BIN="/usr/local/directadmin/directadmin";

usage()
{
    echo "
######################################################################################
#    A script to update Directadmin from beta or stable channel                      #
#    Written by: Alex Grebenschikov (zEitEr), Poralix, www.poralix.com               #
######################################################################################

    ${BN}Usage${BF} $0 <cmd> [<options>]

        ${BN}Commands${BF}:
            alpha   - Download and install Directadmin update from alpha channel
            beta    - Download and install Directadmin update from beta channel
            stable  - Download and install Directadmin update from stable channel
            version - Show installed version of Directadmin
            list_os - Show supported OS and their versions
            save_os - Save os_override option in directadmin.conf with value --os=
            license - Show License ID and User ID as how Directadmin sees it

        ${BN}Options${BF}:
            --lid=  - License ID (if omitted, we check if setup.txt)
            --uid=  - User ID (if omitted, we check if setup.txt)
            --ip=   - IP to be used for outgoing connection
            --os=   - Override OS selection (see list of OS for codes)

        ${BN}Possible OS${BF} (run the command to list supported OS with codes):

            $0 list_os

        ${BN}Example of usage${BF}:

            $0 alpha
            $0 beta
            $0 stable

        ${BN}or any combinations with${BF}:

            $0 beta --ip=1.2.3.4 --lid=12345 --uid=6789 --os=c9

        in the suggested example the script will try to download a directadmin
        binary compiled for ES_7.0_64 (CentOS 7 64 bit), connected from IP 1.2.3.4
        and using License ID 12345 owned by user with ID 6789.
";
}

die()
{
    echo "[ERROR] $1";
    exit_code="${2:-1}";
    exit "${exit_code}";
}

getLicenseDetails()
{
    TMPFILE=$(mktemp);
    SETUP_FILE="/usr/local/directadmin/scripts/setup.txt";
    if [ -f "${TMPFILE}" ]; then
        ${DA_BIN} l > ${TMPFILE};
        [ -z "${DA_UID}" ] && DA_UID=$(cat "${TMPFILE}" | grep ^uid= | cut -d\= -f2);
        [ -z "${DA_LID}" ] && DA_LID=$(cat "${TMPFILE}" | grep ^lid= | cut -d\= -f2);
        rm -f "${TMPFILE}";
    fi;
    if [ -f "${SETUP_FILE}" ]; then
        [ -z "${DA_UID}" ] && DA_UID=$(grep ^uid= "${SETUP_FILE}" | cut -d\= -f2);
        [ -z "${DA_LID}" ] && DA_LID=$(grep ^lid= "${SETUP_FILE}" | cut -d\= -f2);
    fi;
}

doLicenseDetails()
{
    DA_UID="";
    DA_LID="";
    getLicenseDetails;
    echo "UID=${DA_UID}";
    echo "LID=${DA_LID}";
}

doProcess()
{
    cd /usr/local/directadmin || die "Directadmin not installed!";

    if [ -z "${DA_UID}" ] || [ -z "${DA_LID}" ]; then
        getLicenseDetails;
    fi;

    [ -z "${DA_UID}" ] && die "Client ID is empty...";
    [ -z "${DA_LID}" ] && die "License ID is empty...";

    # IP
    [ -n "${DA_IP}" ] && DA_IP="--bind-address=${DA_IP}";

    # OS version override
    if [ -n "${OS_OVERRIDE}" ];
    then
        DA_OS="&os=${OS_OVERRIDE}";
    else
        if [ -n "${DA_OS}" ];
        then
            OS_choice=$(getOS "${DA_OS}");
            if [ -n "${OS_choice}" ]; then
                DA_OS="&os=${OS_choice}";
            else
                die "Could not find OS with the code ${DA_OS}. To list supported OS with codes run: $0 list_os" 2;
            fi;
        fi;
    fi;

    TMPFILE="new.tar.gz";
    [ -f "${TMPFILE}" ] && rm -f ${TMPFILE};

    wget ${DA_IP} --no-check-certificate -O ${TMPFILE} "https://www.directadmin.com/cgi-bin/daupdate?redirect=ok&uid=${DA_UID}&lid=${DA_LID}${CHANNEL}${DA_OS}";
    SIZE=$(ls -la ${TMPFILE} | awk '{print $5}');

    if [ -f "${TMPFILE}" ] && [ "${SIZE}" -gt "1000000" ];
    then
        tar -xzf "${TMPFILE}" >/dev/null 2>&1;
        if [ "$?" == "0" ];
        then
            ./directadmin p;
            scripts/update.sh;
            killall -9 directadmin;
            ./directadmin d;
        else
            die "Failed to unpack Directadmin update...";
        fi;
    else
        die "Failed to download Directadmin update...";
    fi;

    echo "[+] Directadmin ${RELEASE} version installed";
    doVersion;
}

doVersion()
{
    ${DA_BIN} v;
    ${DA_BIN} o;
}

doStableUpdate()
{
    CHANNEL="";
    RELEASE="stable";
    doProcess;
}

doAlphaUpdate()
{
    CHANNEL="&channel=alpha";
    RELEASE="alpha";
    doProcess;
}

doBetaUpdate()
{
    CHANNEL="&channel=beta";
    RELEASE="beta";
    doProcess;
}

getAllOS()
{
    a='RedHat';
    b='Fedora';
    c='CentOS';
    d='FreeBSD';
    e='Debian';

    RedHat[1]='RedHat 7.2';
    RedHat[2]='RedHat 7.3';
    RedHat[3]='RedHat 8.0';
    RedHat[4]='RedHat 9.0';

    Fedora[1]='Fedora 1.0';
    Fedora[2]='Fedora 3';
    Fedora[3]='Fedora 4';
    Fedora[4]='Fedora 5';
    Fedora[5]='Fedora 7';
    Fedora[6]='Fedora 9';

    CentOS[1]='ES 3.0';
    CentOS[2]='ES 4.0';
    CentOS[3]='ES 4.4';
    CentOS[4]='ES 4.1 64';
    CentOS[5]='ES 5.0';
    CentOS[6]='ES 5.0 64';
    CentOS[7]='ES 6.0';
    CentOS[8]='ES 6.0 64';
    CentOS[9]='ES 7.0 64';
    CentOS[10]='ES 8.0 64';

    FreeBSD[1]='FreeBSD 4.8';
    FreeBSD[2]='FreeBSD 5.1';
    FreeBSD[3]='FreeBSD 5.3';
    FreeBSD[4]='FreeBSD 6.0';
    FreeBSD[5]='FreeBSD 7.0';
    FreeBSD[6]='FreeBSD 7.1 64';
    FreeBSD[7]='FreeBSD 8.0 64';
    FreeBSD[8]='FreeBSD 9.1 32';
    FreeBSD[9]='FreeBSD 9.0 64';
    FreeBSD[10]='FreeBSD 11.0 64';
    FreeBSD[11]='FreeBSD 12.0 64';

    Debian[1]='Debian 3.1';
    Debian[2]='Debian 5';
    Debian[3]='Debian 5 64';
    Debian[4]='Debian 6';
    Debian[5]='Debian 6 64';
    Debian[6]='Debian 7';
    Debian[7]='Debian 7 64';
    Debian[8]='Debian 8 64';
    Debian[9]='Debian 9 64';
    Debian[10]='Debian 10 64';
    Debian[11]='Debian 11 64';
}

getOS()
{
    getAllOS;
    if [ -n "${1}" ]; then
        local letter="${DA_OS:0:1}";
        local index="${DA_OS:1}"
        local distr="${!letter}";
        local OSversion="${distr}[${index}]";
        local OS="${!OSversion}";
        echo "${OS}";
    fi;
}

doListOS()
{
    getAllOS;
    OUTPUT="";
    for letter in {a..z};
    do
        distr=${!letter};
        if [ -n "${distr}" ]; then
            OUTPUT="${OUTPUT}\n==================== ======";
            OUTPUT="${OUTPUT}\n${distr} Code\n==================== ======";
            OSversions=${distr}[@];
            index=0;
            for OSversion in "${!OSversions}";
            do
                let index=(index+1);
                if [ -n "${OS_OVERRIDE}" ]; then
                        if [ "${OS_OVERRIDE}" == "${OSversion}" ] ; then
                            OSversion="${BN}${OSversion}${BN}";
                        elif [ "${OS_OVERRIDE}" == "${OSversion//\ /%20}" ] ; then
                            OSversion="${BN}${OSversion}${BF}";
                        fi;
                fi;
                OUTPUT="${OUTPUT}\n${OSversion//\ /_} ${letter}${index}";
            done;
            OUTPUT="${OUTPUT}\n\n";
        fi;
    done;
    echo -ne "${OUTPUT}" 2>/dev/null | column -t 2>/dev/null;
}

doSaveOS()
{
    [ -z "${DA_OS}" ] && die "You should specify OS code in --os=, run $0 list_os too see possible variants";

    OS_choice=$(getOS "${DA_OS}");
    [ -z "${OS_choice}" ] && die "Could not find OS with the code ${DA_OS}. To list supported OS with codes run: $0 list_os" 2;

    ${DA_BIN} set os_override "${OS_choice//\ /%20}" restart;
}

os_override_warning()
{
    if [ -n "${OS_OVERRIDE}" ]; then
        echo "";
        echo "${BN}*** WARNING ***${BF} os_override detected in directadmin.conf with the value ${BN}${OS_OVERRIDE}${BF}.";
        echo "                A binary of Directadmin for ${BN}${OS_OVERRIDE//\%20/ }${BF} will be downloaded instead!";
        echo "                If it's not what you want you should change value in directadmin.conf";
        echo "";
    fi;
}

USER=$(whoami);

[ "root" == "${USER}" ] || die "Should be root to run this programm...";

[ -x "${DA_BIN}" ] || die "Could not find directadmin binary. Is DirectAdmin installed?";

OS_OVERRIDE=$(${DA_BIN} c | grep ^os_override= | cut -d= -f2);

for option in $@;
do
    case "${option}" in
        --lid=*|-lid=*|lid=*)
            DA_LID=$(echo ${option} | cut -d\= -f2);
        ;;
        --uid=*|-uid=*|uid=*)
            DA_UID=$(echo ${option} | cut -d\= -f2);
        ;;
        --os=*|-os=*|os=*)
            DA_OS=$(echo ${option} | cut -d\= -f2);
        ;;
        --ip=*|-ip=*|ip=*)
            DA_IP=$(echo ${option} | cut -d\= -f2);
        ;;
    esac;
done;

SHOW_OS_OVERRIDE_WARNING=0;

case "$1" in
    alpha)
        doAlphaUpdate;
        /usr/local/directadmin/directadmin set update_channel alpha restart;
        SHOW_OS_OVERRIDE_WARNING=1;
    ;;
    beta)
        doBetaUpdate;
        /usr/local/directadmin/directadmin set update_channel beta restart;
        SHOW_OS_OVERRIDE_WARNING=1;
    ;;
    stable)
        doStableUpdate;
        /usr/local/directadmin/directadmin set update_channel current restart;
        SHOW_OS_OVERRIDE_WARNING=1;
    ;;
    version)
        doVersion;
    ;;
    list_os)
        doListOS;
        SHOW_OS_OVERRIDE_WARNING=1;
    ;;
    save_os)
        doSaveOS;
    ;;
    license)
        doLicenseDetails;
    ;;
    *)
        usage;
        SHOW_OS_OVERRIDE_WARNING=1;
    ;;
esac;

[ "${SHOW_OS_OVERRIDE_WARNING}" == "1" ] && os_override_warning;

exit 0;
