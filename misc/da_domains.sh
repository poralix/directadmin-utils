#!/bin/bash
#----------------------------------------------------------------------
# Description: A script for listing all domains from DirectAdmin
#----------------------------------------------------------------------
# Author: Alex Grebenschikov, www.poralix.com
# Created at: Mon Oct 31 13:21:06 +07 2022
# Last modified: Mon Nov 21 11:44:46 +07 2022
# Version: 0.2 $ Mon Nov 21 11:44:46 +07 2022
#----------------------------------------------------------------------
# Copyright (c) 2022 Alex Grebenschikov, www.poralix.com
#----------------------------------------------------------------------

DNS_RESOLVER="1.1.1.1";

die()
{
    echo $1;
    exit $2;
}

usage()
{
    echo "#----------------------------------------------------------------------
# Copyright (c) 2022 Alex Grebenschikov, www.poralix.com
#----------------------------------------------------------------------

Description:
    This is a script to list directadmin domains with a requested from 
    DNS additional information.

Usage:
    $0 <options>

Options:
    --domains  - just list domains without DNS queries
    --ns       - list domains with their nameservers
    --mx       - list domains with their MX records
    --ipv4     - list domains with their IPv4
    --ipv6     - list domains with their IPv6
";
    exit 0;
}

domains()
{
    for DOM in $(awk -F: {'print $1'} /etc/virtual/domainowners | sort | uniq); do echo - $DOM; done
}

nameservers()
{
    for DOM in $(awk -F: {'print $1'} /etc/virtual/domainowners | sort | uniq); do echo - $DOM: $(dig +short NS "@${DNS_RESOLVER}" "${DOM}" | sort | xargs); done
}

ip4()
{
    for DOM in $(awk -F: {'print $1'} /etc/virtual/domainowners | sort | uniq); do echo - $DOM: $(dig +short A "@${DNS_RESOLVER}" "${DOM}" | sort | xargs); done
}

ip6()
{
    for DOM in $(awk -F: {'print $1'} /etc/virtual/domainowners | sort | uniq); do echo - $DOM: $(dig +short AAAA "@${DNS_RESOLVER}" "${DOM}" | sort | xargs); done
}

mx()
{
    for DOM in $(awk -F: {'print $1'} /etc/virtual/domainowners | sort | uniq); do echo - $DOM: $(dig +short MX "@${DNS_RESOLVER}" "${DOM}" | sort | xargs); done
}

run_cmd()
{
    case $1 in
        domains)
            domains;
        ;;
        nameservers)
            nameservers;
        ;;
        ip4)
            ip4;
        ;;
        ip6)
            ip6;
        ;;
        mx)
            mx;
        ;;
        usage|*)
            usage;
        ;;
    esac;
}

test -e "/etc/virtual/domainowners" || die "Error: Not a directadmin server?" 1;

RUN="";

for CMD in $@
do
    case $CMD in
        --only-domains|--domains)
            RUN="domains";
        ;;
        --ns)
            RUN="nameservers";
        ;;
        --ip4)
            RUN="ip4";
        ;;
        --ip6)
            RUN="ip6";
        ;;
        --mx)
            RUN="mx";
        ;;
        --help)
            RUN="usage";
        ;;
    esac;
done;

run_cmd "${RUN}";

exit 0;
