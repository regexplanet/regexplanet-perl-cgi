#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use DateTime;
use JSON;
# not available by default, how do I install it?
#use Perl::Version;

my $q = CGI->new;

print $q->header(-type=>'text/plain; charset=utf-8',
	'Access-Control-Allow-Origin' => '*',
	'Access-Control-Allow-Methods' => 'POST, GET',
	'Access-Control-Max-Age' => '604800'
	);

my $data;

$data = {
	'$^O' => "$^O",
	'$^V' => "$^V",
	'$]' => "$]",
	'commit' => $ENV{'COMMIT'},
	'lastmod' => $ENV{'LASTMOD'},
	'path_translated()' => $q->path_translated(),
	'remote_addr()' => $q->remote_addr(),
	'script_name()' => $q->script_name(),
	'server_name()' => $q->server_name(),
	'server_software()' => $q->server_software(),
	'server_port ()' => $q->server_port(),
	"success" => JSON::true,
#LATER:	'version' => Perl::Version->new($^V)->stringify,
	'tech' => "Perl $^V",
	'timestamp' => DateTime->now()->iso8601().'Z',
	'version' => "$^V",
	};

my $body = to_json($data, {'utf8' => 1, 'pretty'=> 0});
my $callback = $q->param('callback');
if ($callback && length($callback))
{
	$body = $callback . "(" . $body . ")"
}

print $body
