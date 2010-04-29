#!/usr/bin/perl
#####################################
# URLgrep v0.5                      #
# by x0rz <hourto_c@epita.fr>       #
#                                   #
# http://code.google.com/p/urlgrep/ #
#####################################
# Warning: this is a BETA VERSION -- use with caution!

use LWP::Simple qw($ua get);;
use HTML::LinkExtor;
use Term::ANSIColor;
use Getopt::Long;

# Catching Ctrl-C
$SIG{INT} = \&tsktsk;

sub tsktsk {
    print ("\n");
    print_comm ("Catching Ctrl-C!\n");
    finishing();
    exit 0;
}


my @crawled;		# list of crawled urls
my @targets;		# list of urls that matches the regexp
my @targets_misc;	# list of misc links that matches the regexp


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
my $cookie_file = "";

GetOptions ('verbose' => \$verbose,
	    'depth=i' => \$depth,
	    'url=s' => \$entry_url,
	    'regexp=s' => \$regexp,
	    'insensitive' => \$casei,
	    'output=s' => \$output,
	    'help' => \$help,
	    'all' => \$all,
	    'timeout=i' => \$timeout,
	    'cookie=s' => \$cookie_file);


$ua->env_proxy(); # load env proxy (*_proxy)
$ua->timeout($timeout);
$ua->agent('Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; fr; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3');

# cookie
if ($cookie_file ne "")
{
    $ua->cookie_jar({ file => $cookie_file });
}


if ($help != 0)
{
    print_comm ("URLgrep v0.5\n");
    print_comm ("by x0rz <hourto_c\@epita.fr>\n");
    print_comm ("http://code.google.com/p/urlgrep/\n");
    print_comm ("\n");
    print_comm ("usage: ./urlgrep.pl -u URL [-r -i -d -a -o -t -c -v -h]\n");
    exit 0;
}

if ($entry_url eq "")
{
    print_comm ("usage: ./urlgrep.pl -u URL [-r -i -d -a -o -t -c -v -h]\n");
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
    
    # removing duplicates
    %seen = ();
    foreach $item (@targets) {
	push(@targets_u, $item) unless $seen{$item}++;
    }

    # searching in misc links
    my $grep;
    if ($casei)
    {
        @grep = grep(/$regexp/i, @targets_misc);
    }
    else
    {
        @grep = grep(/$regexp/, @targets_misc);
    }
    # removing duplicates for misc links
    %seen = ();
    foreach $item (@targets_misc) {
        push(@targets_misc_u, $item) unless $seen{$item}++;
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

    if (scalar(@targets_misc_u) != 0)
    {
	print_comm ("We also found some other links that may interest you:\n");
    }

    foreach $link (@targets_misc_u)
    {
	print_info();
	print $link."\n";
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
	print "Couldn't reach the page.\n";
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

    # Adding the results to the targets list
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
	    if ($visited == 0 &&
		($link =~ !m/.*\.(gif|jpe?g|png|css|js|ico|swf|axd|jsp|pdf)$/i))
	    {
		parseURL($link, $_[1] + 1);
	    }
	}
    }
}

sub constructURL
{
    # 0 = link
    # 1 = page

    my $newURL = "";
    my $protocol = "";

    # check if it's a good http link
    if ($_[0] =~ m!^(ftp:|mailto:|javascript:|#).*!i)
    {
	# we keep it in our misc list
	push (@targets_misc, $_[0]);
	return  "";
    }

    if ($_[1] =~ m!^https://!i)
    {
	$protocol = "https://";
    }
    else
    {
	$protocol = "http://";
    }

    # in case the given page does not finish with a '/'
    if (index($_[1], "/", 7) == -1)
    {
	$_[1] .= "/";
    }

    # Testing if link is absolute
    if ($_[0] =~ m!^https?://!i)
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
    else  # link is relative
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
	    $newURL = $protocol.find_wwwhost($_[1]);
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
                $newURL = $protocol . substr($_[0], 2, length($_[0] - 2));
            }
            else
            {
                $newURL = $protocol . find_wwwhost($_[1]) . '/' . substr($_[0],1);
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
