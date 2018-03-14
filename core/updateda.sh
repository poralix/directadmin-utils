#!/usr/bin/env bash
#######################################################################################
#                                                                                     #
#       A script to update Directadmin from beta or stable channel                    #
#                                                                                     #
#######################################################################################
#                                                                                     #
#            Version: 0.3 (Wed Mar 14 17:49:04 +07 2018)                              #
#            Written by: Alex S Grebenschikov (zEitEr)                                #
#            Site: www.poralix.com  E-mail: support@poralix.com                       #
#                                                                                     #
#######################################################################################
#######################################################################################
##                                                                                    #
##   MIT License                                                                      #
##                                                                                    #
##   Copyright (c) 2016 Alex S Grebenschikov (www.poralix.com)                        #
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

usage()
{
    echo "
######################################################################################
#    A script to update Directadmin from beta or stable channel                      #
#    Written by: Alex S Grebenschikov (zEitEr)                                       #
######################################################################################

    Usage $0 <cmd> [<options>]

        Commands:
            stable  - Download and install Directadmin update from stable channel
            beta    - Download and install Directadmin update from beta channel
            version - Show installed version of Directadmin
            list_os - Show supported OS and their versions

        Options:
            --lid=  - License ID (if omitted, we check if setup.txt)
            --uid=  - User ID (if omitted, we check if setup.txt)
            --ip=   - IP to be used for outgoing connection
            --os=   - Override OS selection (see list of OS for codes)

        Possible OS (run the command to list supported OS with codes):

            $0 list_os

        Example of usage:

            $0 beta
            $0 stable

        or any combinations with:

            $0 beta --ip=1.2.3.4 --lid=12345 --uid=6789 --os=c9
";
}

die()
{
    echo "[ERROR] $1";
    exit 1;
}

doProcess()
{
    cd /usr/local/directadmin || die "Directadmin not installed!";
    SETUP_FILE="/usr/local/directadmin/scripts/setup.txt";
    if [ -f "${SETUP_FILE}" ]; then
        [ -z "${DA_UID}" ] && DA_UID=$(grep ^uid= "${SETUP_FILE}" | cut -d\= -f2);
        [ -z "${DA_LID}" ] && DA_LID=$(grep ^lid= "${SETUP_FILE}" | cut -d\= -f2);
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
            OS_choice=`getOS "${DA_OS}"`;
            if [ -n "${OS_choice}" ]; then
                DA_OS="&os=${OS_choice}";
            else
                echo "[ERROR] Could not find OS with the code ${DA_OS}. To list support OS with codes run: $0 list_os";
                exit 2;
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
    /usr/local/directadmin/directadmin v;
    /usr/local/directadmin/directadmin o;
}

doStableUpdate()
{
    CHANNEL="";
    RELEASE="stable";
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

    Debian[1]='Debian 3.1';
    Debian[2]='Debian 5';
    Debian[3]='Debian 5 64';
    Debian[4]='Debian 6';
    Debian[5]='Debian 6 64';
    Debian[6]='Debian 7';
    Debian[7]='Debian 7 64';
    Debian[8]='Debian 8 64';
    Debian[9]='Debian 9 64';
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
            for OSversion in "${!OSversions}"
            do
                let index=(index+1);
                if [ -n "${OS_OVERRIDE}" ] && [ "${OS_OVERRIDE}" == "${OSversion}" ] ; then
                    OSversion="**${OSversion}**"
                fi;
                OUTPUT="${OUTPUT}\n${OSversion//\ /_} ${letter}${index}";
            done;
            OUTPUT="${OUTPUT}\n";
        fi;
    done;
    echo -ne "${OUTPUT}" 2>/dev/null | column -t 2>/dev/null;
}

os_override_warning()
{
    if [ -n "${OS_OVERRIDE}" ]; then
        echo "";
        echo "*** WARNING *** os_override detected in directadmin.conf with the value ${OS_OVERRIDE}.";
        echo "                A binary of Directadmin for ${OS_OVERRIDE} will be downloaded instead!";
        echo "                If it's not what you want you should change value in directadmin.conf";
        echo "";
    fi;
}

OS_OVERRIDE=$(/usr/local/directadmin/directadmin c | grep ^os_override= | cut -d= -f2);
os_override_warning;


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

case "$1" in
    stable)
        doStableUpdate;
    ;;
    beta)
        doBetaUpdate;
    ;;
    version)
        doVersion;
    ;;
    list_os)
        doListOS;
    ;;
    *)
        usage;
    ;;
esac;

os_override_warning;

exit 0;
