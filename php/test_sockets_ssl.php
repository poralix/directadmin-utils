<?php
// =============================
// Poralix Testing Script
// www.poralix.com
// =============================
$debug=false;
$test_ssl=true;
$test_nonssl=true;

$hosts=[
    "imap.gmail.com" => [993],
    "smtp.gmail.com" => [25, 465, 587],
    ];

if ($debug) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
} else {
    error_reporting(0);
    ini_set('display_errors', 0);
}

print "<pre>\n";
foreach ($hosts as $host => $ports)
{
    foreach ($ports as $port)
    {
        if ($test_nonssl)
        {
            print "Connection to $host:$port without SSL  ";
            if (!($fp = fsockopen($host, $port, $errno, $errstr, 30))) 
            {
                fclose($fp);
                print "OK";
            }
            else
            {
                print "FAILED";
            }
            print "\n";
        }
        if ($test_ssl)
        {
            print "Connection to $host:$port with SSL  ";
            if (!($fp = fsockopen("ssl://".$host, $port, $errno, $errstr, 30)))
            {
                fclose($fp);
                print "OK";
            }
            else
            {
                print "FAILED";
            }
            print "\n";
        }
    }
}
print "</pre>\n";

exit(0);

