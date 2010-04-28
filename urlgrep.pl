#!/usr/bin/perl
#####################################
# URLgrep v0.2                      #
# by x0rz <hourto_c@epita.fr        #
#                                   #
# http://code.google.com/p/urlgrep/ #
#####################################
# Warning: this is a BETA VERSION -- use with caution!

use LWP::Simple qw($ua get);;
use HTML::LinkExtor;
use Term::ANSIColor;
use Getopt::Long;

use Data::Dumper;

$ua->timeout(5);
$ua->agent('Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; fr; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3');

# Catching Ctrl-C
$SIG{INT} = \&tsktsk;

sub tsktsk {
    print ("\n");
    print_comm ("Catching Ctrl-C!\n");
    finishing();
    exit 0;
}


my @crawled;
my @targets;

my $total_links = 0;

#
# 1. Options
#
my $host = "http://localhost/";
my $depth = 1;
my $regexp = "";
my $verbose = 0;
my $help = 0;

GetOptions ('verbose' => \$verbose,
	    'depth=i' => \$depth,
	    'url=s' => \$host,
	    'regexp=s' => \$regexp,
	    'help' => \$help);

if ($help != 0)
{
    print_comm ("URLgrep v0.2\n");
    print_comm ("by x0rz <hourto_c@epita.fr\n");
    print_comm ("http://code.google.com/p/urlgrep/\n");
    print_comm ("\n");
    print_comm ("usage: ./urlgrep.pl --url=URL [--depth=D --verbose --regexp=REG]\n");
    exit 0;
}

if ($host eq "")
{
    print_comm ("usage: ./urlgrep.pl --url=URL [--depth=D --verbose --regexp=REG]\n");
    exit 1;
}

print_comm ("Running URLgrep on " . $host ."\n");
print_comm ("Started on ".gmtime()." \n");

#
# 2. Call first root URL
#
parseURL($host, 0);

if ($verbose == 0)
{
    print ("\n");
}

finishing();


sub finishing
{
    print_comm ("Finished on ".gmtime()." \n");
    
    print_ok();
    print "Crawl done - crawled ".scalar(@crawled)." URL(s).\n";
    
    %seen = ();
    foreach $item (@targets) {
	push(@targets_u, $item) unless $seen{$item}++;
    }
    
    if (scalar(@targets_u) == 0)
    {
	print_ko();
	print color 'red';
	print "No target found.\n";
    }
    else
    {
	print_ok();

	print color 'red';
	print scalar(@targets_u)." URL(s) found matching /".$regexp."/.\n";
	foreach $link (@targets_u)
	{
	    print_info();
	    print $link."\n";
	}
    }
}

sub parseURL
{
    if ($verbose == 1)
    {
	print_ok();
	print "Trying (d:".$_[1].") " . $_[0] . "\n";
    }
    else
    {
	print ".";
	$|++;
    }

    push(@crawled, $_[0]);

    # Get the HTML page
    my $content = get($_[0]);
    if (!defined $content)
    {
	print_ko();
	print "Could't reach the page.\n";
    }

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

    my @grep = grep(/$regexp/, @links);
    @targets = (@targets, @grep);

    if ($verbose == 1)
    {
	print_ok();
	print  scalar(@links) . " link(s) found.\n";
	if (scalar(@grep) != 0) {
	    print "     > " . scalar(@grep)." matched!\n";
	}
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

	if (substr($_[0], 1, 2) eq "./")
	{
	    
	}
    }

    return ($newURL);
}

# Misc
sub print_ok {
    print color 'bold white';
    print "[";
    print color 'green';
    print "OK";
    print color 'white';
    print "] ";
    print color 'reset';
}

sub print_ko {
    print color 'bold white';
    print "[";
    print color 'red';
    print "KO";
    print color 'white';
    print "] ";
    print color 'reset';
}

sub print_info {
    print color 'bold white';
    print "[";
    print color 'blue';
    print ">>";
    print color 'white';
    print "] ";
    print color 'reset';
}

sub print_comm {
    print color 'bold red';
    print "# ";
    print color 'reset';
    print color 'yellow';
    print $_[0];
    print color 'reset';
}
