#!/usr/bin/perl
#####################################
# URLgrep v0.41                     #
# by x0rz <hourto_c@epita.fr>       #
#                                   #
# http://code.google.com/p/urlgrep/ #
#####################################
# Warning: this is a BETA VERSION -- use with caution!

use LWP::Simple qw($ua get);;
use HTML::LinkExtor;
use Term::ANSIColor;
use Getopt::Long;

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
my $entry_url = "";
my $depth = 1;
my $regexp = "^.*\$";
my $verbose = 0;
my $help = 0;
my $output = "";
my $casei = 0;
my $all = 0;
my $timeout = 5;


GetOptions ('verbose' => \$verbose,
	    'depth=i' => \$depth,
	    'url=s' => \$entry_url,
	    'regexp=s' => \$regexp,
	    'insensitive' => \$casei,
	    'output=s' => \$output,
	    'help' => \$help,
	    'all' => \$all,
	    'timeout=i' => \$timeout);

$ua->timeout($timeout);
$ua->agent('Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; fr; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3');

if ($help != 0)
{
    print_comm ("URLgrep v0.41\n");
    print_comm ("by x0rz <hourto_c@epita.fr>\n");
    print_comm ("http://code.google.com/p/urlgrep/\n");
    print_comm ("\n");
    print_comm ("usage: ./urlgrep.pl -u URL [-r -i -d -a -o -t -v -h]\n");
    exit 0;
}

if ($entry_url eq "")
{
    print_comm ("usage: ./urlgrep.pl -u URL [-r -i -d -a -o -t -v -h]\n");
    exit 1;
}


# Calculating host
my $host = find_hostname($entry_url);

print_comm ("Running URLgrep on " . $entry_url ."\n");
print_comm ("Regexp: /".$regexp."/".($casei? "i" : "")."\n");
print_comm ("Started on ".gmtime()." \n");

#
# 2. Call first root URL
#
parseURL($entry_url, 0);

if ($verbose == 0)
{
    print ("\n");
}

finishing();

# return domain
sub find_hostname
{
    my $url = $_[0];
    $url =~ s!^https?://(?:www\.)?!!i;
    $url =~ s!/.*!!;
    $url =~ s/[\?\#\:].*//;
    
    return $url;
}

# return domain and sub-domains
sub find_wwwhost
{
    return (URI->new($_[0])->host);
}

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
	print scalar(@targets_u)." URL(s) found matching /".$regexp."/".($casei? "i" : "")."\n";
	foreach $link (@targets_u)
	{
	    print_info();
	    print $link."\n";
	}

	if ($output ne "")
	{
	    print_comm ("Generating output...\n");
	    if (!open FILE, ">", $output)
	    {
		print_ko();
		print "Couldn't create file.\n";
	    }
	    else
	    {
		foreach $link (@targets_u)
		{
		    print FILE $link."\n";
		}
		print_ok();
		print "URLs correctly written in " .$output. "\n";
	    }

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
	print("\n");
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

    # removing images and other special files
    @links = grep(!/.*\.(gif|jpe?g|png|css|js|ico|swf|axd|jsp|pdf)$/, @links);

    # removing javascript, mailto, FTP links and anchors links
    @links = grep(!/^(#|ftp:|mailto:|javascript:).*/, @links);

    # remving empty links
    @links = grep(!/^\ *$/, @links);

    # Targets matching the given regexp
    my @grep;
    if ($casei)
    {
	@grep = grep(/$regexp/i, @links);
    }
    else
    {
	@grep = grep(/$regexp/, @links);
    }
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
    my $newURL;

    # 0 = link
    # 1 = page

    # in case the given page does not finish with a '/'
    if (index($_[1], "/", 7) == -1)
    {
	$_[1] .= "/";
    }

    # Testing if link is absolute
    if ((index($_[0], "http://") != -1) || (index($_[0], "https://") != -1))
    {
	# if we want to go through all the links (not only local to the website)
	if ($all)
	{
	    $newURL = $_[0];
	}
	else
	{
	    # Calculating host of the link
	    my $link_host = find_hostname($_[0]);

	    if ($link_host eq $host)
	    {
		$newURL = $_[0];
	    }
	    else
	    {
		# return empty string
		$newURL = "";
	    }
	}
    }
    else
    {
	# Construct directory URL
	if (substr($_[1], 0, 1) ne "/")
	{
	    # Relative URL
	    $newURL = substr($_[1], 0, rindex($_[1], "/"));
	}
	else
	{
	    # Need the root URL
	    $newURL = "http://".find_wwwhost($_[1]);
	}

	# We need to remove the last '/' of the host
        if (substr($newURL, -1, 1) eq "/")
        {
            chop($newURL);
        }

        # href link begins with '/'
        if (substr($_[0], 0, 1) eq "/")
        {
            # href link begins with "//"
            if (substr($_[0], 0, 2) eq "//")
            {
                $newURL = "http://" . substr($_[0], 2, length($_[0] - 2));
            }
            else
            {
                $newURL = "http://" . find_wwwhost($_[1]) . '/' . substr($_[0],1);
            }
        }
        else
        {
            # href link begins with "./"
            if (substr($_[0], 0, 2) eq "./")
            {
                $newURL = $newURL . '/' . substr($_[0], 2, length($_[0] - 2));
            }
            else
            {
                $newURL = $newURL . '/' . $_[0];
            }
        }
    }
    
    #print ("0  " . $_[0]."\n");
    #print ("1  " .$_[1]."\n");
    #print("==> " . $newURL."\n");

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
