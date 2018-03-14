# Scripts for operations with PHP

- change_domain_phpver.sh
- test_sockets_ssl.php

# Description of change_domain_phpver.sh

The script can be used to show which PHP version is set for a domain in Directadmin.

You can use the script to change PHP version for a domain from pre-installed with Custombuild 2.0.

Example of usage:

```
# ./change_domain_phpver.sh domain.com
Domain domain.com found and is owned by the user userbob
Currently used: (no values mean defaults)
    php1_select: 5.3 as suphp (2)
    php2_select: 5.6 as suphp (1)
PHP Versions:
    1 stands for PHP (default): 5.6 as suphp
    2 stands for PHP (additional): 5.3 as suphp
You did not specified new version, terminating here...
```

Run

```
./change_domain_phpver.sh domain.com 2
```

to set the second PHP version as a default for the domain.com (in our case it's PHP 5.3).

Run

```
./change_domain_phpver.sh domain.com 1
```

to set the primary PHP version as a default for the domain.com (in our case it's PHP 5.6).

# Description of test_sockets_ssl.php

A simple PHP-script to test connections to a remote host with and/or without TLS/SSL.

Run under Document Root via HTTP/HTTPS or in a console:

```
# php test_sockets_ssl.php
<pre>
Connection to imap.gmail.com:993 without SSL  FAILED
Connection to imap.gmail.com:993 with SSL  FAILED
Connection to smtp.gmail.com:25 without SSL  FAILED
Connection to smtp.gmail.com:25 with SSL  OK
Connection to smtp.gmail.com:465 without SSL  FAILED
Connection to smtp.gmail.com:465 with SSL  FAILED
Connection to smtp.gmail.com:587 without SSL  FAILED
Connection to smtp.gmail.com:587 with SSL  OK
</pre>
```
