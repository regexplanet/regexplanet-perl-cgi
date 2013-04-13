#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use JSON;
use Perl::Version;

my $q = CGI->new;

print $q->header(-type=>'text/plain; charset=utf-8',
	'Access-Control-Allow-Origin' => '*',
	'Access-Control-Allow-Methods' => 'POST, GET',
	'Access-Control-Max-Age' => '604800'
	);

my $data;

$data = {
	'$^O' => $^O,
	'$^V' => Perl::Version->new($^V)->stringify,
	'$]' => $],
	'path_translated()' => $q->path_translated(),
	'remote_addr()' => $q->remote_addr(),
	'script_name()' => $q->script_name(),
	'server_name()' => $q->server_name(),
	'server_software()' => $q->server_software(),
	'server_port ()' => $q->server_port(),
	"success" => JSON::true,
	'version' => Perl::Version->new($^V)->stringify,
	};

my $body = to_json($data, {'utf8' => 1, 'pretty'=> 0});
my $callback = $q->param('callback');
if (length($callback))
{
	$body = $callback . "(" . $body . ")"
}

print $body
