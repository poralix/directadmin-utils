#!/usr/bin/env bash
#######################################################################################
#                                                                                     #
#       A script to update Directadmin from beta or stable channel                    #
#                                                                                     #
#######################################################################################
#                                                                                     #
#            Version: 0.1 (Thu Aug 31 18:12:01 +07 2017)                              #
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

function usage()
{
    echo "
######################################################################################
#    A script to update Directadmin from beta or stable channel                      #
#    Written by: Alex S Grebenschikov (zEitEr)                                       #
######################################################################################

    Usage $0 <cmd> [<options>]

        Commands:
            stable - Download and install Directadmin update from stable channel
            beta   - Download and install Directadmin update from beta channel

        Options:
            --lid  - License ID (if omitted, we check if setup.txt)
            --uid  - User ID (if omitted, we check if setup.txt)
";
}

function die()
{
    echo "[ERROR] $1";
    exit 1;
}

function doProcess()
{
#set -x
    cd /usr/local/directadmin || die "Directadmin not installed!";
    SETUP_FILE="/usr/local/directadmin/scripts/setup.txt";
    if [ -f "${SETUP_FILE}" ]; then
        [ -z "${DA_UID}" ] && DA_UID=$(grep ^uid= "${SETUP_FILE}" | cut -d\= -f2);
        [ -z "${DA_LID}" ] && DA_LID=$(grep ^lid= "${SETUP_FILE}" | cut -d\= -f2);
    fi;
    [ -z "${DA_UID}" ] && die "Client ID is empty...";
    [ -z "${DA_LID}" ] && die "License ID is empty...";

    TMPFILE="new.tar.gz";
    [ -f "${TMPFILE}" ] && rm -f ${TMPFILE};

    wget --no-check-certificate -O ${TMPFILE} "https://www.directadmin.com/cgi-bin/daupdate?redirect=ok&uid=${DA_UID}&lid=${DA_LID}${CHANNEL}"
    SIZE=$(ls -la ${TMPFILE} | awk '{print $5}');

    if [ -f "${TMPFILE}" ] && [ "${SIZE}" -gt "1000000" ];
    then
        tar -xzf new.tar.gz >/dev/null 2>&1;
        if [ "$?" == "0" ];
        then
            ./directadmin p
            scripts/update.sh
            killall -9 directadmin
            ./directadmin d
        else
            die "Failed to unpack Directadmin update...";
        fi;
    else
        die "Failed to download Directadmin update...";
    fi;

    echo "[+] Directadmin ${RELEASE} version installed";
    /usr/local/directadmin/directadmin v;
    /usr/local/directadmin/directadmin o;
}

function doStableUpdate()
{
    CHANNEL="";
    RELEASE="stable";
    doProcess;
}

function doBetaUpdate()
{
    CHANNEL="&channel=beta";
    RELEASE="beta";
    doProcess;
}

for option in $@;
do
    case "${option}" in
        --lid=*|-lid=*|lid=*)
            DA_LID=$(echo ${option} | cut -d\= -f2);
        ;;
        --uid=*|-uid=*|uid=*)
            DA_UID=$(echo ${option} | cut -d\= -f2);
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
    *)
        usage;
    ;;
esac;

exit 0;
