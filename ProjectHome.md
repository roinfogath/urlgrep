# What is URLgrep? #

_URLgrep_ is a simple perl web crawler that gives you the ability to perform a grep search on all links of any webpage using regular expressions.

## Common usage ##

This tool can be useful in pen-testing to find dangerous pattern in URLs.
For example you can use it as a generic vulnerability scanner using regular expressions! How awesome is that? ;-)

## Current features ##
  * **Fast** and easy to use
  * Support grep regexp syntax
  * Stop automatically when all pages have been visited
    * you can set your own search depth
  * Works with cookies
    * you just have specify the cookie file
  * Also check for some other types of links (mailto, javascript, etc.)
  * Proxy support
    * through the _$http\_proxy_ environment variable

### Note ###

**This script is NOT currently under development!**
Please keep in mind this tool have been made to fulfill my own needs.

Tested and working on Unix-like systems (_Linux_, _BSD_ and _Mac OS X_).

## Examples ##

```
./urlgrep.pl -u "http://www.epita.fr" -r "\.php$" -d 1
```


Output will be:
```
# Running URLgrep on http://www.epita.fr
# Regexp: /\.php$/
# Started on Wed Apr 28 18:06:58 2010
.....................
# Finished on Wed Apr 28 18:07:01 2010
[OK] Crawl done - crawled 21 URL(s).
[OK] 4 URL(s) found matching /\.php$/
[>>] http://www.epita.fr/recherche.php
[>>] http://www.epita.fr/index.php
[>>] http://www.epita.fr/telechargements.php
[>>] http://www.epita.fr/etudes-programmes.php
```
