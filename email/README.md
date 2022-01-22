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
```

Options:

```
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
```

# Author:

Alex Grebenschikov, www.poralix.com
