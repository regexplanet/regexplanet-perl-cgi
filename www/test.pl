#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use HTML::Entities;
use JSON;


# Version 2013-08-11
#
# Handles display of whitespace (including newlines) within patterns and data, by
# using <code> tags and using &nbsp; and <br>.
#
# Global flag (/g) is honored. 
#     $var = $input =~ /$regex/g 
#        This is executed, but only once. Realistically, if the global flag is
#        being used the match would be done repeatedly in a loop
#     @var = $input =~ /$regex/g 
#        The /g flag makes this 'pluck all matches'
#     $input =~ s/$regex/$replace/g
#        The /g flag makes this do global replacement
#
# Named capture results are extracted from results and displayed
#
# Capture values can be used in substitution text.
#  The recommended syntax is $1 for the first capture group
#  or $+{name} for a named capture group
#
# Embedded code is disallowed
#
# Error text for invalid regexes is displayed
#
# Perl version is checked, /adlu flags only allowed if supported (5.14+)
#
# Unescaped forward slashes get escaped, so that they won't prematurely
# terminate a qr/regex/


# main-line
    my $q = CGI->new;
    
    print $q->header(-type=>'text/plain; charset=utf-8',
    'Access-Control-Allow-Origin' => '*',
    'Access-Control-Allow-Methods' => 'POST, GET',
    'Access-Control-Max-Age' => '604800'
    );
    
    my $regex_str = $q->param('regex');
    my $replacement = $q->param('replacement');
    my $data;
    my $this_perl_version = $];
    
    my $msg = 'Perl support is a work in progress<br>';
    
    if (!$regex_str) {
        $data = { "success" => $JSON::false, "message" => "No regex to test" };
    } elsif ( has_embedded_code($regex_str) ) {
        $data = { "success" => $JSON::false, "message" => "Embedded code is not supported" };
    } else {
        my %opt_trans = # Options whose initial letter is not the flag
                        (dotall  => 's',
                         comment => 'x',
                        );
        my %opt_ver = (a       => 5.014000,
                       d       => 5.014000,
                       l       => 5.014000,
                       u       => 5.014000,
                      );
        my %run_time =   (g   => 1,
                          c   => 1);
        my $regex_options = '';
        my $exec_options  = '';
        for my $o (@{$q->{param}{option}}) {
            my $required_perl_version = $opt_ver{$o} || 0;
            if ($required_perl_version > $this_perl_version) {
                my $required = format_version($required_perl_version);
                my $running  = format_version($this_perl_version);
                $msg .= "Option $o needs Perl version $required. We are running version $running<br>";
            } else {
                my $opt_letter = $opt_trans{$o} || substr($o, 0, 1);
                if ($run_time{$opt_letter}) {
                    $exec_options  .= $opt_letter;
                } else {
                    $regex_options .= $opt_letter;
                }
            }
        }
        
        $regex_options = join('', sort( split(  //, $regex_options)));
        my $regex = '';
        eval {
            $regex = $regex_options ? qr/(?$regex_options)$regex_str/
                                    : qr/$regex_str/;
        };
        if ($@) {
            # Invalid regex or regex flags
            my $msg_prefix = $@;
            $msg_prefix =~ s/ [ ] at [ ] .*//x;
            $msg .= 'Perl reported error:<br>' . as_code($msg_prefix) . '<br>';
            $regex = '';
        }
        my $regex_option_p = $regex_options =~ /p/;
        my $exec_option_g = $exec_options =~ /g/ ? 'g' : '';
        
        if ($exec_options =~ /c/) {
            $msg .= "Option c is only relevant when using the same subject<br>"
                  . "string with different regexes. This test harness only <br>"
                  . "handles one regex at a time<br>";
            if (! $exec_option_g) {
                $msg .= "Option c is only relevant when option g is also selected<br>";
            }
        }
        if ($exec_option_g) {
            $msg .= "You have selected option g, so 'global' actions tested<br>";
        }
        
        
        
        my $html = "<table class=\"table table-bordered table-striped\" style=\"width:auto;\">\n"
        
        . "\t<tr>\n"
        . "\t\t<td>"
        . "Regular expression"
        . "</td>\n"
        . "\t\t<td>"
        . as_code($regex_str)
        . "</td>\n"
        . "\t</tr>\n"
        ;

        
        $html .= "\t<tr>\n"
        . "\t\t<td>"
        . "Options"
        . "</td>\n"
        . "\t\t<td>"
        . as_code($regex_options . $exec_options)
        . "</td>\n"
        . "\t</tr>\n"
        
        . "\t<tr>\n"
        . "\t\t<td>"
        . "Perl regex object"
        . "</td>\n"
        . "\t\t<td>"
        . as_code('qr/' . escape_slashes($regex_str) . '/' . $regex_options)
        . "</td>\n"
        . "\t</tr>\n";
        
        if (length($regex_options) > 0)
        {
        $html .= "\t<tr>\n"
        . "\t\t<td>"
        . "Perl code (embedded options)"
        . "</td>\n"
        . "\t\t<td>"
        . as_code('/(?' . $regex_options . ')' . escape_slashes($regex_str) . '/' )
        . "</td>\n"
        . "\t</tr>\n";
        }
        
        $html .= "\t<tr>\n"
        . "\t\t<td>"
        . "Perl variable"
        . "</td>\n"
        . "\t\t<td>"
        . as_code($regex_str)
        . "</td>\n"
        . "\t</tr>\n";
        
        $html .= "</table>";
        
        $html .= '<table class="table table-bordered table-striped">'
        . '<thead>'
        . '<th style="text-align:center;">Test</th>'
        . '<th>Input</th>'
        . '<th style="text-align:center;">$var = $input =~ '
        . ($exec_option_g ? '/$regex/g' : '$regex')
        . '</th>'
        . '<th style="text-align:center;">@array = $input =~ '
        . ($exec_option_g ? '/$regex/g' : '$regex')
        . '</th>'
        . '<th>split($regex, $input)</th>'
        . '<th>$input =~ s/$regex/$replace/'
        . ($exec_option_g ? 'g' : '')
        . '</th>'
        . '</tr>'
        . '</thead>'
        . '<tbody>';
        
        my @inputs = $q->param('input');
        my $count = 0;
        
        INPUT:
        for (my $loop = 0; $loop < scalar(@inputs); $loop++) {
            my $input = $inputs[$loop];
            
            next INPUT unless length($input);
            
            $html .= "\t\t<tr>"
            . "\t\t\t<td style=\"text-align:center;\">"
            . ($loop + 1)
            . "</td>"
            . "\t\t\t<td>"
            . as_code($input)
            . "</td>";
            
            $html .= "\t\t\t<td>";
            my $var;
            $var = $input =~  $regex   unless $exec_option_g;
            $var = $input =~ /$regex/g if     $exec_option_g;
            my ($before, $during, $after) = ( $`, $&, $');
            my $named = '';
            for my $bufname (sort keys %-) {
                my $a_ref = $-{$bufname};
                my $a_size = scalar @{$a_ref};
                if ($a_size == 1) {
                    $named .= "\$+{$bufname}";
                    $named .= fmt_var('', $a_ref->[0]);
                    $named .= '<br/>';
                } else {
                    for my $idx (0 .. $a_size - 1) {
                        $named .= "\$-{$bufname}[$idx]";
                        $named .= fmt_var('', $a_ref->[$idx]);
                        $named .= '<br/>';
                    }
                }
            }
            $html .= fmt_var('$var', $var);

            $html .= "<br/>";
            if ($var) {
                if ($regex_option_p) {
                    # User specified /p, so presumably is intending to use
                    # ${^PREMATCH} , ${^MATCH} and ${^POSTMATCH} 
                    $html .= fmt_var( '${^PREMATCH}=',  $before) . "<br/>";
                    $html .= fmt_var( '${^MATCH}='   ,  $during) . "<br/>";
                    $html .= fmt_var( '${^POSTMATCH}=', $after)  . "<br/>";  
                } else {
                    #$html .= "\$`="      . as_code($before) . "<br/>";
                    #$html .= "\$&amp;="  . as_code($during) . "<br/>";
                    #$html .= "\$&#x27;=" . as_code($after)  . "<br/>";
                    $html .= fmt_var( '$`'  , $before) . "<br/>";
                    $html .= fmt_var( '$&'  , $during) . "<br/>";
                    $html .= fmt_var( "\$'" , $after)  . "<br/>";
                }
            }
            $html .= $named;
            $html .= "</td>";
            
            $html .= "\t\t\t<td>";
            my @results;
            pos($input) = 0;    # Start at the beginning
            @results = $input =~  $regex   unless $exec_option_g;
            @results = $input =~ /$regex/g if     $exec_option_g;
            for (my $resultLoop = 0; $resultLoop < scalar(@results); $resultLoop++) { 
                $html .= fmt_var( "\$array[$resultLoop]", $results[$resultLoop]) . '<br/>'
            }
            $html .= "</td>";
            
            $html .= "\t\t\t<td>";
            my @words = split $regex, $input;
            for (my $wordLoop = 0; $wordLoop < scalar(@words); $wordLoop++) {
                $html .= fmt_var( "[$wordLoop]", $words[$wordLoop]) . "<br/>"
            }
            $html .= "</td>";
            
            $html .= "\t\t\t<td>";
            my $replaced = $input;
            #$replaced =~ s/$regex/$replacement/  unless $exec_option_g;
            #$replaced =~ s/$regex/$replacement/g if     $exec_option_g;
            eval '$replaced =~ s/$regex/' . escape_slashes($replacement) . '/' . $exec_option_g;
            $html .= as_code($replaced);
            $html .= "</td>";
            $html .= "\t\t</tr>";
            $count++;
        }
        if ($count == 0) {
            $html .= "\t\t<tr>"
                   . "\t\t\t<td colspan=\"5\"><i>"
                   . "(no inputs to test)"
                   . "</i></td>"
                   . "\t\t</tr>";
        }
        $html .= "\t</tbody>\n"
               . "</table>\n";
        $data = { "success" => JSON::true, "html" => '<div class="alert alert-warning">' . $msg . '</div>' . $html};
    }
        
    my $body = to_json($data, {'utf8' => 1, 'pretty' => 1});
    my $callback = $q->param('callback');
    if ($callback && length($callback)) {
        $body = $callback . "(" . $body . ")";
    }
    print $body;

#  End of main-line
#########################
sub as_code {
    my ($txt) = @_;
    $txt = $txt || '';
    my $encoded = "<code>" . HTML::Entities::encode($txt) . "</code>";
    $encoded =~ s/ [ ] /&nbsp;/gx;
    $encoded =~ s/ \n  /<br>/gx;
    return $encoded;
}

sub fmt_var {
    my ($var_name, $var_value) = @_;
    my $result = HTML::Entities::encode($var_name);
    if (! defined $var_value) {
        $result .= ' is undef';
    } elsif (length $var_value == 0) {
        $result .= ' is a null string';
    } else{
        $result .= '=' . as_code($var_value);
    }
    
}
sub format_version {
    my ($ver) = @_;
    # Assumes version is in format v.sssnnn or v.sss
    # Returns string formatted as v.s.n
    my ($v, $s, $n) = "${ver}000" =~ / (\d+) [.] (\d{3}) (\d{3}) /x;
    return $v . '.' . ($s + 0) . '.' . ($n + 0);
}

sub has_embedded_code {
    my ($user_supplied_regex) = @_;
    if ($user_supplied_regex =~
          /
            \( 
                \s* (?: \# [^\n]* \n \s* )* \s* \?
                \s* (?: \# [^\n]* \n \s* )* \s* [?p]?
                \s* (?: \# [^\n]* \n \s* )* \s*
            \{
          /x ) {
        return 'Regex contains embedded code';
    } else {
        return '';
    }
}

sub escape_slashes {
    my ($txt) = @_;
    $txt =~ s{(?x) (?<!\\)    # not preceding \
             (                # capture 
             (?: \\\\         #     zero or more '\\'
            )*\/              #     /
            )
             }{\\$1}gx;
    return $txt;
}
