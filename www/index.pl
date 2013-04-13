#!/usr/bin/perl

use CGI

$q = CGI->new;

print $q->redirect('http://www.regexplanet.com/advanced/perl/index.html');
