#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use HTML::Entities;
use JSON;

my $q = CGI->new;

print $q->header(-type=>'text/plain; charset=utf-8',
	'Access-Control-Allow-Origin' => '*',
	'Access-Control-Allow-Methods' => 'POST, GET',
	'Access-Control-Max-Age' => '604800'
	);

my $regex_str = $q->param('regex');
my $replacement = $q->param('replacement');
my $data;

if (!$regex_str)
{
	$data = { "success" => JSON::false, "message" => "No regex to test" };
}
else
{
	my %options = map { $_ => 1 } $q->param('option');
	my $perl_options = '';
	if ($options{'a'}) { $perl_options .= 'a'; }
	if ($options{'c'}) { $perl_options .= 'c'; }
	if ($options{'d'}) { $perl_options .= 'd'; }
	if ($options{'g'}) { $perl_options .= 'g'; }
	if ($options{'ignorecase'}) { $perl_options .= 'i'; }
	if ($options{'l'}) { $perl_options .= 'l'; }
	if ($options{'multiline'}) { $perl_options .= 'm'; }
	if ($options{'p'}) { $perl_options .= 'p'; }
	if ($options{'dotall'}) { $perl_options .= 's'; }
	if ($options{'unicode'}) { $perl_options .= 'u'; }
	if ($options{'comment'}) { $perl_options .= 'x'; }

	my $regex;
	if (length($perl_options) == 0)
	{
		$regex = qr/$regex_str/;
	}
	else
	{
		$regex = qr/(?$perl_options)$regex_str/;
	}

	my $html = "<table class=\"table table-bordered table-striped\" style=\"width:auto;\">\n"

		. "\t<tr>\n"
		. "\t\t<td>"
		. "Regular expression"
		. "</td>\n"
		. "\t\t<td>"
		. HTML::Entities::encode($regex_str)
		. "</td>\n"
		. "\t</tr>\n"

		. "\t<tr>\n"
		. "\t\t<td>"
		. "Options"
		. "</td>\n"
		. "\t\t<td>"
		. HTML::Entities::encode($perl_options)
		. "</td>\n"
		. "\t</tr>\n"

		. "\t<tr>\n"
		. "\t\t<td>"
		. "Perl code"
		. "</td>\n"
		. "\t\t<td>"
		. 'qr/' . HTML::Entities::encode($regex_str) . '/' . HTML::Entities::encode($perl_options)
		. "</td>\n"
		. "\t</tr>\n";

		if (length($perl_options) > 0)
		{
			$html .= "\t<tr>\n"
			. "\t\t<td>"
			. "Perl code (embedded options)"
			. "</td>\n"
			. "\t\t<td>"
			. 'qr/(?' . HTML::Entities::encode($perl_options) . ')' . HTML::Entities::encode($regex_str) . '/'
			. "</td>\n"
			. "\t</tr>\n";
		}

		$html .= "\t<tr>\n"
		. "\t\t<td>"
		. "Perl variable"
		. "</td>\n"
		. "\t\t<td>"
		. HTML::Entities::encode($regex)
		. "</td>\n"
		. "\t</tr>\n";

		$html .= "</table>";

	$html .= "<table class=\"table table-bordered table-striped\">\n"
		. "\t<thead>"
		. "\t\t<tr>\n"
		. "\t\t\t<th style=\"text-align:center;\">Test</th>\n"
		. "\t\t\t<th>Input</th>\n"
		. "\t\t\t<th style=\"text-align:center;\">=~</th>\n"
		. "\t\t\t<th>split</th>\n"
		. "\t\t\t<th>=~ s/\$regex/\$input/r</th>\n"
		. "\t\t</tr>\n"
		. "\t</thead>\n"
		. "\t<tbody>\n";

	my @inputs = $q->param('input');
	my $count = 0;

	for (my $loop = 0; $loop < scalar(@inputs); $loop++)
	{
		my $input = $inputs[$loop];
		if (length($input) == 0)
		{
			next;
		}
		$html .= "\t\t<tr>"
			. "\t\t\t<td style=\"text-align:center;\">"
			. ($loop + 1)
			. "</td>"
			. "\t\t\t<td>"
			. HTML::Entities::encode($input)
			. "</td>";

		$html .= "\t\t\t<td>";
		$html .= ($input =~ $regex) ? "true" : "false";
		$html .= "<br/>";
		$html .= "\$`=<code>" . HTML::Entities::encode($`) . "</code><br/>";
		$html .= "\$&amp;=<code>" . HTML::Entities::encode($&) . "</code><br/>";
		$html .= "\$&#x27;=<code>" . HTML::Entities::encode($') . "</code><br/>";
		$html .= "</td>";

		$html .= "\t\t\t<td>";
		my @words = split $regex, $input;
		for (my $wordLoop = 0; $wordLoop < scalar(@words); $wordLoop++)
		{
			$html .= "[$wordLoop]:&nbsp;" . HTML::Entities::encode($words[$wordLoop]) . "<br/>"
		}
		$html .= "</td>";

		$html .= "\t\t\t<td>";
		my $replaced = $input;
		$replaced =~ s/$regex/$replacement/;
		$html .= HTML::Entities::encode($replaced);
		$html .= "</td>";

		$html .= "\t\t</tr>";
		$count += 1;
	}

	if ($count == 0)
	{
		$html .= "\t\t<tr>"
			. "\t\t\t<td colspan=\"5\"><i>"
			. "(no inputs to test)"
			. "</i></td>"
			. "\t\t</tr>";
	}

	$html .= "\t</tbody>\n"
		. "</table>\n";


	$data = { "success" => JSON::true, "html" => '<div class="alert alert-warning">Perl support is pretty raw.  If you are a Perl hacker, I could really use some help!  (<a href="http://www.regexplanet.com/support/api.html">instructions</a>, <a href="https://github.com/fileformat/regexplanet-perl-cgi">code on GitHub</a>)</div>' . $html};
}

my $body = to_json($data, {'utf8' => 1, 'pretty'=> 1});
my $callback = $q->param('callback');
if ($callback && length($callback))
{
	$body = $callback . "(" . $body . ")"
}

print $body
