#!/usr/bin/perl
#####################################
# URLgrep v0.1                      #
# by x0rz <hourto_c@epita.fr        #
#                                   #
# http://code.google.com/p/urlgrep/ #
#####################################
# Warning: this is a BETA VERSION -- use with caution!

use LWP::Simple qw($ua get);;
use HTML::LinkExtor;
use Data::Dumper;

$ua->timeout(5);
$ua->agent('Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; fr; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3');

my @crawled;
my @targets;

# Options
$host = "http://www.epita.fr/";
$depth = 1;
$regexp = /\?/;
$verbose = 0;

print ("# Running URLgrep on " . $host ."\n");
print ("# Started on ".gmtime()." \n");

parseURL($host, 0);

print ("\n");

print "[*] Crawl done - crawled ".scalar(@crawled)." URL(s).\n";

%seen = ();
foreach $item (@targets) {
    push(@targets_u, $item) unless $seen{$item}++;
}

if (scalar(@targets_u) == 0)
{
    print "[X] No target found.\n";
}
else
{
    print "[*] ".scalar(@targets_u)." target(s) found.\n";
    foreach $link (@targets_u)
    {
	print "- ".$link."\n";
    }
}

sub parseURL
{
    if ($verbose == 1)
    {
	print "[*] Trying (d:".$_[1].") " . $_[0] . "\n";
    }
    else
    {
	print ".";
	$|++;
    }

    push(@crawled, $_[0]);

    # Get the HTML page
    my $content = get($_[0]);
    print "[X] Get failed\n" if (!defined $content);

    # Extract links
    my $parser = HTML::LinkExtor->new();

    $parser->parse($content);
    my @parse = $parser->links;

    my @links;

    foreach $link (@parse)
    {
	push @links, constructURL($link->[2], $_[0]);
    }

    my @links = grep(!/.*\.(gif|jpe?g|png|css|js|ico|swf|axd|jsp|pdf)$/, @links);

    @targets = (@targets, grep($regexp, @links));

    if ($verbose == 1)
    {
	print "[*] " . scalar(@links) . " links found.\n";
    }

    # Testing current depth
    if ($_[1] < $depth)
    {
	# Grabbing all urls
	foreach $link (@links)
	{
	    my $visited = 0;

	    # Checking if already done
	    foreach $url_done (@crawled)
	    {
		if ($link eq $url_done)
		{
		    $visited = 1;
		}
	    }

	    # if not visited yet, parse it
	    if ($visited == 0)
	    {
		parseURL($link, $_[1] + 1);
	    }
	}
    }
}

sub constructURL
{
    my $newURL = $host;

    if ((index($_[0], "http://") == -1) && (index($_[0], "https://") == -1))
    {
	if (substr($newURL, -1, 1) eq "/")
	{
	    chop($newURL);
	}

	if ($_[0][0] eq '/')
	{
	    $newURL = $newURL . $_[0];
	}
	else
	{
	    $newURL = $newURL . '/' . $_[0];
	}
    }

    return ($newURL);
}
