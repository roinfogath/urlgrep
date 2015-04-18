# Options #

Below are the currently supported options:
  * _-u link, --url link_
    * target webpage's url

  * _-d n, --depth n_
    * set the depth of the crawler (default=1)

  * _-a, --all_
    * specify this option if you want to search in pages that link outside

  * _-r exp, --regexp exp_
    * the regular expression you want to apply (see example below)

  * _-i, --ignore-case_
    * case insensitive search

  * _-m, --invert-match_
    * invert the sense of matching

  * _-o file, --output file_
    * will dump all matching URLs into the specified _file_

  * _-t n, --timeout n_
    * set the timeout when requesting a page (default=5 seconds)

  * _-c file, --cookie file_
    * specify your cookie file

  * _-v ,--verbose_
    * verbose mode

  * _-h, --help_
    * show the help and usage


# Examples #

```
./urlgrep.pl --url="http://www.epita.fr/" --regexp="\?" -d 1 -v
```
This will search for any URL in the website www.epita.fr containing a '?'.


```
./urlgrep.pl -u "http://www.epita.fr" -r "\.php" -d 2
```
Using short options, this will search PHP pages in the website www.epita.fr.

```
./urlgrep.pl -u "http://www.epita.fr" -d 1 -r "pHp" -i -v -o test.log
```
Will dump the results in _test.log_.