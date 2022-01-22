#!/bin/bash
#----------------------------------------------------------------------
# Description: A script for auto-listing domains for sending
#              over TransIP Mail Service
#  For DirectAdmin servers which use TransIP Mail Service
#  Exim should be configured to use TransIP Mail Service first!
#  The script DOES NOT change Exim's configuration. You should do it!
#  The script DOES NOT change DNS records. You should do it first
#  Contact Poralix if you want us to configure Exim for you.
#----------------------------------------------------------------------
# Author: Alex Grebenschikov, www.poralix.com
# Created at: Sat Jan 22 08:40:23 CET 2022
# Last modified: Sat Jan 22 13:08:47 CET 2022
# Version: 0.2 $ Sat Jan 22 13:08:47 CET 2022
#----------------------------------------------------------------------
# Copyright (c) 2022 Alex Grebenschikov, www.poralix.com
#----------------------------------------------------------------------

#######################################################################################
##                                                                                    #
##   MIT License                                                                      #
##                                                                                    #
##   Copyright (c) 2016 Alex Grebenschikov, Poralix, www.poralix.com                  #
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


# Configure section:
#----------------------------------------------------------------------
EXCLUDED_LIST="/etc/virtual/domains_relay_transip.excluded";
LIST_FILE="/etc/virtual/domains_relay_transip";
DOMAINS_FILE="/etc/virtual/domains";
DNS_RESOLVER="1.1.1.1";
SEARCH_RECORD="x-transip-mail-auth";
DEBUG=0;
VERBOSE=0;
DRY_RUN=0;
AUTH_KEY="";

TEST_AUTH=1;
TEST_SPF=0;
TEST_DKIM=0;

RUN=0;
#----------------------------------------------------------------------

do_usage()
{
    echo "
# =========================================================================== #
# The auto-listing script adds domains for sending over TransIP Mail Service  #
#  For DirectAdmin servers which use TransIP Mail Service as a SMTP relay     #
#  Exim should be configured to use TransIP Mail Service first                #
#  The script DOES NOT change Exim's configuration. You should do it first    #
#  The script DOES NOT change DNS records. You should do it first             #
# Author: Alex Grebenschikov, www.poralix.com                                 #
# =========================================================================== #

Usage:

    ${0} <options>

Options:

    --run            - Run the tests

    --test-spf       - Enable SPF test
    --test-dkim      - Enable DKIM test
    --test-all       - Enable SPF/DKIM tests

    --key=<KEY>      - If specified should contain a value for x-transip-mail-auth.
                       This is the value which can be found in TransIP dashboard.
                       TransIP requires this to be added for every domain.

                       If omitted the script won't verify the value of the record
                       in DNS. Any value will give a positive result.

    --debug          - Print DEBUG output
    --verbose        - Do a verbose output

    --dry-run        - Do selected tests without writing changes to a file

Important:

    You can add excluded domains in the file ${EXCLUDED_LIST}
    Verified domains will be added in the file ${LIST_FILE}
    Nothing else gets changed by the script.


    The script uses remote DNS resolver ${DNS_RESOLVER}.
    Make sure the server's firewall does not block connections to it.

Copyright:

    (c) 2022 Alex Grebenschikov, www.poralix.com

License:

    MIT License
";
    exit 0;
}

c_echo()
{
    [ "${VERBOSE}" == "1" ] && echo "${1}";
}

do_add_domain()
{
    if [ "${DRY_RUN}" == "1" ]; then
        DRY_RUN_DOMAINS="${1}\n${DRY_RUN_DOMAINS}";
    else
        echo "${1}" >> "${LIST_FILE}.new";
    fi;
}

for ARG in $@;
do
    case "${ARG}" in
        --debug)
            DEBUG=1;
        ;;
        --key=*)
            AUTH_KEY=$(echo ${ARG} | cut -d= -f2);
        ;;
        --verbose)
            VERBOSE=1;
        ;;
        --dry-run)
            DRY_RUN=1;
        ;;
        --test-spf)
            TEST_SPF=1;
        ;;
        --test-dkim)
            TEST_DKIM=1;
        ;;
        --test-all)
            TEST_AUTH=1;
            TEST_SPF=1;
            TEST_DKIM=1;
        ;;
        --run)
            RUN=1;
        ;;
        --help|--usage|*)
            do_usage;
        ;;
    esac;
done;

[ -z "$1" ] && do_usage;

DOMAINS="";

[ -h "${LIST_FILE}" ] && echo "[ERROR] The ${LIST_FILE} is a symbolic link. Terminating..." && exit 1;
[ ! -s "${DOMAINS_FILE}" ] && echo "[ERROR] Could not find a list of domains. Terminating..." && exit 2;

[ -s "${LIST_FILE}" ] && cp -p "${LIST_FILE}" "${LIST_FILE}.old";
[ -f "${LIST_FILE}.new" ] && rm -f "${LIST_FILE}.new";

touch "${LIST_FILE}.new";
chmod 600 "${LIST_FILE}.new";

AUTH_OK_DOMAINS="";
SPF_OK_DOMAINS="";
DKIM_OK_DOMAINS="";
FOUND_OK_DOMAINS="";
DRY_RUN_DOMAINS="";

c_echo "STEP 1: Testing ${SEARCH_RECORD} record";
    c_echo "====================================================================";

for DOMAIN in $(cat "${DOMAINS_FILE}" | sort | uniq);
do
    c_echo "[OK] Processing ${DOMAIN}";

    [ "${DEBUG}" == "1" ] && set -x;

    if [ -z "${AUTH_KEY}" ]; then
        CHECK_AUTH_RECORD=$(dig +short TXT "${SEARCH_RECORD}.${DOMAIN}" @${DNS_RESOLVER} | xargs);
    else
        CHECK_AUTH_RECORD=$(dig +short TXT "${SEARCH_RECORD}.${DOMAIN}" @${DNS_RESOLVER} | grep "${AUTH_KEY}");
    fi;

    if [ -z "${CHECK_AUTH_RECORD}" ]; then
        c_echo "[WARNING] Domain ${DOMAIN} is not configured to use TransIP mail service. AUTH record is missing.";
    else
        c_echo "[INFO][${DOMAIN}] Found a value ${CHECK_AUTH_RECORD} for ${SEARCH_RECORD}.${DOMAIN} in DNS.";
        AUTH_OK_DOMAINS="${AUTH_OK_DOMAINS} ${DOMAIN}";
    fi;

    [ "${DEBUG}" == "1" ] && set +x;
    c_echo "--------------------------------------------------------------------";
done;

# SHOULD WE TEST SPF?
if [ "${TEST_SPF}" == "1" ]; then
    c_echo "";
    c_echo "STEP 2: Testing SPF record";
    c_echo "====================================================================";

    if [ -n "${AUTH_OK_DOMAINS}" ]; then
        TEST_DOMAINS="${AUTH_OK_DOMAINS}";
    else
        TEST_DOMAINS=$(cat "${DOMAINS_FILE}" | sort | uniq);
    fi;

    for DOMAIN in ${TEST_DOMAINS};
    do
        CHECK_SPF_RECORD=$(dig +short TXT "${DOMAIN}" @${DNS_RESOLVER} | grep -o " include:_spf.transip.email ");

        if [ -z "${CHECK_SPF_RECORD}" ]; then
            c_echo "[WARNING] Domain ${DOMAIN} is not configured to use TransIP mail service. SPF record is bad.";
        else
            c_echo "[INFO][${DOMAIN}] Found a string ${CHECK_SPF_RECORD// /} in SPF record for ${DOMAIN} in DNS.";
            SPF_OK_DOMAINS="${SPF_OK_DOMAINS} ${DOMAIN}";
        fi;
        c_echo "--------------------------------------------------------------------";
    done;
fi;

# SHOULD WE TEST DKIM?
if [ "${TEST_DKIM}" == "1" ]; then
    c_echo "";
    c_echo "STEP 3: Testing DKIM record";
    c_echo "====================================================================";

    if [ -n "${SPF_OK_DOMAINS}" ]; then
        TEST_DOMAINS="${SPF_OK_DOMAINS}";
    elif [ -n "${AUTH_OK_DOMAINS}" ]; then
        TEST_DOMAINS="${AUTH_OK_DOMAINS}";
    else
        TEST_DOMAINS=$(cat "${DOMAINS_FILE}" | sort | uniq);
    fi;

    for DOMAIN in ${TEST_DOMAINS};
    do
        CHECK_DKIM_A_RECORD=$(dig +short CNAME "transip-A._domainkey.${DOMAIN}" @${DNS_RESOLVER} | grep "_dkim-A.transip.email");
        CHECK_DKIM_B_RECORD=$(dig +short CNAME "transip-B._domainkey.${DOMAIN}" @${DNS_RESOLVER} | grep "_dkim-B.transip.email");
        CHECK_DKIM_C_RECORD=$(dig +short CNAME "transip-C._domainkey.${DOMAIN}" @${DNS_RESOLVER} | grep "_dkim-C.transip.email");

        if [ -z "${CHECK_DKIM_A_RECORD}" ] || [ -z "${CHECK_DKIM_B_RECORD}" ] || [ -z "${CHECK_DKIM_C_RECORD}" ]; then
            c_echo "[WARNING] Domain ${DOMAIN} is not configured to use TransIP mail service. DKIM record is bad.";
        else
            c_echo "[INFO][${DOMAIN}] Found DKIM record ${CHECK_DKIM_A_RECORD} for ${DOMAIN} in DNS.";
            c_echo "[INFO][${DOMAIN}] Found DKIM record ${CHECK_DKIM_B_RECORD} for ${DOMAIN} in DNS.";
            c_echo "[INFO][${DOMAIN}] Found DKIM record ${CHECK_DKIM_C_RECORD} for ${DOMAIN} in DNS.";
            DKIM_OK_DOMAINS="${DKIM_OK_DOMAINS} ${DOMAIN}";
        fi;
        c_echo "--------------------------------------------------------------------";
    done;
fi;

if [ "${TEST_DKIM}" == "1" ]; then
    FOUND_OK_DOMAINS="${DKIM_OK_DOMAINS}";
elif [ "${TEST_DKIM}" == "0" ] && [ "${TEST_SPF}" == "1" ]; then
    FOUND_OK_DOMAINS="${SPF_OK_DOMAINS}";
elif [ "${TEST_DKIM}" == "0" ] && [ "${TEST_SPF}" == "0" ]; then
    FOUND_OK_DOMAINS="${AUTH_OK_DOMAINS}";
fi;

if [ -n "${FOUND_OK_DOMAINS}" ]; then

    c_echo "";
    c_echo "STEP 4: Completing the list of domains";
    c_echo "====================================================================";

    for DOMAIN in ${FOUND_OK_DOMAINS};
    do
        if [ -s "${EXCLUDED_LIST}" ]; then
            c_echo "[INFO] Found ${EXCLUDED_LIST}";
            CHECK_EXCLUDED=$(grep "^${DOMAIN}$" "${EXCLUDED_LIST}");
            if [ -z "${CHECK_EXCLUDED}" ]; then
                do_add_domain "${DOMAIN}";
            else
                c_echo "[WARNING] Skipping domain ${DOMAIN}, as it is listed in ${EXCLUDED_LIST}"
            fi;
        else
            do_add_domain "${DOMAIN}";
        fi;
        c_echo "--------------------------------------------------------------------";
    done;
else
    echo "[WARNING] None of the hosted domains is configured for sending over TransIP";
fi;

if [ "${DRY_RUN}" == "0" ]; then

    if [ -f "${LIST_FILE}.new" ]; then
        cat "${LIST_FILE}.new" > "${LIST_FILE}";
        rm -f "${LIST_FILE}.new";
    fi;

    chown root:mail "${LIST_FILE}";
    chmod 640 "${LIST_FILE}";

    echo -e "\n\n====================================================================";
    echo " Listed the following domains in ${LIST_FILE}";
    echo "====================================================================";
    cat "${LIST_FILE}"
    echo -e "====================================================================";
    wc -l "${LIST_FILE}";
    echo -e "\n";
else
    echo -e "\n\n================================================================================";
    echo " Found the following domains to be listed in ${LIST_FILE}";
    echo "================================================================================";
    echo -n -e "${DRY_RUN_DOMAINS}" | sort | grep -v "$^";
    echo -e "================================================================================";
    echo -n -e "${DRY_RUN_DOMAINS}" | grep -v "$^" | wc -l;
    echo -e "\n";
fi;

exit 0;
