#!/usr/bin/env bash
#######################################################################################
#                                                                                     #
#       A script to manage private_html directories on Directadmin servers            #
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
#    A script to manage private_html directories on Directadmin servers              #
#    Written by: Alex S Grebenschikov (zEitEr)                                       #
######################################################################################

    Usage $0
        --list        - list private_html status for all domains
        --list-dirs   - list only domains with static folder for private_html
        --list-links  - list only domains with symlink for private_html
        --list-no     - list only domains without private_html at all

        --create-symlink=dirs  - Replace directory private_html with a symlink
        --create-symlink=no    - Create symlink private_html where it does not exist
    ";
}

function doList()
{
    for DH in `ls -d1 /home/*/domains/*/ | egrep -v "/shared/|/suspended/|/default/" | sort`;
    do
        DOMAIN=$(echo ${DH} | cut -d\/ -f5);
        if [ -L "${DH}/private_html" ]; then
            [ "${1}" == "links" ] && echo "[S] Domain ${DOMAIN} has private_html symlink in ${DH}";
        elif [ -d "${DH}/private_html" ]; then
            [ "${1}" == "dirs" ] && echo "[D] Domain ${DOMAIN} has private_html folder in ${DH}";
        else
            [ "${1}" == "no" ] && echo "[-] Domain ${DOMAIN} has no private_html folder in ${DH}";
        fi;
    done;
}

function doCreateSymlink()
{
    for DH in `ls -d1 /home/*/domains/*/ | egrep -v "/shared/|/suspended/|/default/" | sort`;
    do
        USER=$(echo ${DH} | cut -d\/ -f3);
        DOMAIN=$(echo ${DH} | cut -d\/ -f5);

        if [ -L "${DH}/private_html" ]; then
        {
            [ "${1}" == "links" ] && echo "[-] Skipping domain ${DOMAIN}";
        }
        elif [ -d "${DH}/private_html" ]; then
        {
            if [ "${1}" == "dirs" ]; then
            {
                echo "[+] Moving existing private_html to private_html.old for domain ${DOMAIN}";
                mv "${DH}/private_html" "${DH}/private_html.old";
                echo "[+] Create symlink to public_html for domain ${DOMAIN} under ${DH}";
                ln -s public_html ${DH}/private_html;
                chown -h ${USER}:${USER} ${DH}/private_html;
            }
            fi;
        }
        else
        {
            if [ "${1}" == "no" ]; then
            {
                echo "[+] Create symlink to public_html for domain ${DOMAIN} under ${DH}";
                ln -s public_html ${DH}/private_html;
                chown -h ${USER}:${USER} ${DH}/private_html;
            }
            fi;
        }
        fi;
    done;
}

case "${1}" in
    --list=all|--list)
        doList dirs;
        doList links;
        doList no;
    ;;
    --list=dirs|--list-dirs)
        doList dirs;
    ;;
    --list=links|--list-links)
        doList links;
    ;;
    --list=no|--list-no)
        doList no;
    ;;
    --create-symlink=dirs)
        doCreateSymlink dirs;
    ;;
    --create-symlink=no)
        doCreateSymlink no;
    ;;
    *)
        usage;
    ;;
esac;

exit 0;
