# Content 

- clear_majordomo_digest.sh: A script for Majordomo Mailings Lists Digest and Archives clearing
- transip_mail_domains.sh: A auto-listing script adds domains for sending over TransIP Mail Service

# Script transip_mail_domains.sh:

For DirectAdmin servers which use TransIP Mail Service as a SMTP relay.
Exim should be configured to use TransIP Mail Service first.
The script DOES NOT change Exim's configuration. You should do it first.
The script DOES NOT change DNS records. You should do it first.

Installation:

```
cd /usr/local/directadmin/scripts/custom/
wget -O transip_mail_domains.sh https://raw.githubusercontent.com/poralix/directadmin-utils/master/email/transip_mail_domains.sh
chmod 750 ./transip_mail_domains.sh
```

Usage:

```
cd /usr/local/directadmin/scripts/custom/
./transip_mail_domains.sh --help

./transip_mail_domains.sh --run
```

# Author:

Alex Grebenschikov, www.poralix.com
