#!/usr/bin/perl

use CGI

$q = CGI->new;

print $q->header(-type=>'text/plain; charset=utf-8',
	'Access-Control-Allow-Origin' => '*',
	'Access-Control-Allow-Methods' => 'POST, GET',
	'Access-Control-Max-Age' => '604800'
	);
print "hello world!\n"
