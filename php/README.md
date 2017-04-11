# Description

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
