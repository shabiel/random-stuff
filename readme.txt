This is the readme.txt file for the gtmposix plugin.


OVERVIEW

gtmposix is a simple plugin to allow FIS GT.M (http://fis-gtm.com)
application code to use selected POSIX functions on POSIX (UNIX/Linux)
editions of GT.M.  gtmposix provides a set of low-level calls wrapping
and closely matching their corresponding POSIX functions, and a set of
high-level entryrefs that provide a further layer of wrapping to make
the functionality available in a form more familiar to M programmers.

gtmposix is just a wrapper for POSIX functions; it does not actually
provide the underlying functionality.

gtmposix consists of the following files:

  - COPYING - the free / open source software (FOSS) license under
    which gtmposix is provided to you.  See section LICENSE, below for
    more information, especially if COPYING is missing when you
    receive gtmposix.

  - gtmposix.c - C code that wraps POSIX functions for use by GT.M

  - gtmposix.xc_proto - a prototype to generate the call-out table
    used by GT.M to map M entryrefs to C entry points, as described in
    the Programmers Guide, UNIX edition.

  - Makefile - for use by GNU make to build, test, install and
    uninstall the package.

  - _POSIX.m - wraps the C code with M-like functionality to provide
    ^%POSIX entryrefs

  - posixtest.m - a simple test to check for correct operation of
    gtmposix

  - readme.txt - this file

References to the Programmers Guide are to the UNIX edition.


LICENSE

If you receive this plugin integrated with a GT.M distribution, the
license for your GT.M distribution is also your license for this
plugin.

In the event the package contains a COPYING file, that is your license
for this plugin. Except as noted here, you must retain that file and
include it if you redistribute the package or a derivative work
thereof.

If you have a signed agreement providing you with GT.M under a
different license from that in the COPYING file, you may, at your
option, delete the COPYING file and use gtmposix as an integral part
of GT.M under the same terms as that of the GT.M license. If your GT.M
license permits redistribution, you may redistribute gtmposix
integrated with GT.M under the terms of that license.

Simple aggregation or bundling of this package with another for
distribution does not create a derivative work. To make clear the
distinction between this package and another with which it is
aggregated or bundled, it suffices to place the package in a separate
directory or folder when distributing the aggregate or bundle.

Should you receive this package not integrated with a GT.M
distribution, and missing a COPYING file, you may create a file called
COPYING from the GNU Affero General Public License Version 3 or later
(https://www.gnu.org/licenses/agpl.txt) and use this package under the
terms of that license.


INSTALLATION

gtmposix comes with a Makefile that you can use with GNU make to build,
test, install and uninstall the package.  Depending on the platform,
GNU make may be available via "gmake" or "make" command. Building and
testing gtmposix does not normally require root access, while installing
it as a GT.M plug-in does. The targets in the Makefile designated for
external use are:

  - all: creates libgtmposix.so (the shared library of C code that
    wraps POSIX functions) and gtmposix.xc (although this is a text
    file, the first line points to libgtmposix.so and gtmposix.xc must
    therefore be created by the Makefile

  - clean: delete object files and gtmposix.xc

  - install: executed as root to install gtmposix as a plugin under a
    GT.M installation directory

  - test: after building gtmposix and before installation, a quick
    test for correct operation of the plugin

  - uninstall: executed as root to remove an installed plugin from
    under a GT.M installation

The following targets also exist, but are intended for use within the
Makefile rather than for external invocation: gtmposix.o, gtmposix.xc,
and libgtmposix.so.

Make always needs the following environment variable to be set:
gtm_dist, the directory where GT.M is installed.  If you plan to
install the plugin for multiple GT.M versions, please clean the build
each time, since the file gtmxc_types.h is included from $gtm_dist to
build the shared library.

Depending on your GT.M installation, some make targets may need
additional environment variables to be set:

  - make test sends a LOG_WARNING severity message and a LOG_INFO
    severity message and reads the syslog file for each to verify the
    messages.  Although posixtest.m tries to make reasonable guesses
    about the location of the files on your system, it has no way to know
    how you have syslog configured.  If you see a "FAIL syslog ..."
    output message repeat the test with the environment variable
    syslog_warning set to the location of the syslog file for
    LOG_WARNING messages.  If you see a "FAIL SYSLOG ..." output
    message, repeat the test with the environment variable syslog_info
    set to the location of the syslog file for LOG_INFO messages.  In
    particular, a test on Red Hat Enterprise Linux may require
    $syslog_info to be "/var/log/messages".

  - if your GT.M installation includes UTF-8 support (i.e., if it has
    a utf8 sub-directory), make install will require the environment
    variable LC_CTYPE to specify a valid UTF-8 locale, and depending
    on how libicu is built on your system, may require the
    gtm_icu_version to have the ICU version number.  Refer to
    sub-section on ICU of Chapter 2, GT.M Language Extensions, for
    more information about gtm_icu_version and LC_CTYPE.


TESTING

The expected output of make test is as below; manually verify whether
the statement about Daylight Savings Time is correct.

    PASS Invocation
    PASS $zhorolog
    PASS $ZHOROLOG
    Daylight Savings Time is not in effect
    PASS mktime()
    PASS Microsecond resolution
    PASS regmatch^%POSIX 1
    PASS regfree^%POSIX
    PASS REGMATCH^%POSIX 1
    PASS REGFREE^%POSIX
    PASS regmatch^%POSIX 2
    PASS REGMATCH^%POSIX 2
    PASS regmatch^%POSIX 3
    PASS REGMATCH^%POSIX 3
    PASS regmatch^%POSIX 3
    PASS REGMATCH^%POSIX 3
    PASS regmatch^%POSIX 4
    PASS REGMATCH^%POSIX 4
    PASS regmatch^%POSIX 5
    PASS REGMATCH^%POSIX 5
    PASS mktmpdir
    PASS statfile.times
    PASS statfile.ids
    PASS filemodeconst^%POSIX
    PASS signal
    PASS STATFILE.times
    PASS STATFILE.ids
    PASS syslog
    PASS SYSLOG
    PASS setenv
    PASS unsetenv
    PASS rmdir
    PASS MKTMPDIR
    PASS mkdir
    PASS MKDIR
    PASS version
    PASS VERSION


USE

For use by GT.M, the environment variable GTMXC_gtmposix must point to
gtmposix.xc ($gtm_dist/plugin/gtmposix.xc after make install), the
location of the gtmposix.xc file; and the environment variable
gtmroutines must allow GT.M processes to find the %POSIX entryrefs.
Depending on your platform, this will include a $gtmroutines term of
the form $gtm_dist/plugin/o/_POSIX.so or
$gtm_dist/plugin/o($gtm_dist/plugin/r) for M mode processes and
$gtm_dist/plugin/o/utf8/_POSIX.so or
$gtm_dist/plugin/o/utf8($gtm_dist/plugin/r) for UTF-8 mode processes.

For GT.M versions V5.5-000 and newer, the $gtm_dist/gtmprofile file that you can
source to set environment variables and the $gtm_dist/gtm script to
run GT.M automatically define appropriate values for $GTMXC_gtmposix
and $gtmroutines to allow processes to execute gtmposix.

Note you may need additional environment variables to install and use
gtmposix, for example to preload the correct libraries if they are not
automatically loaded.  Contact your GT.M support channel for
assistance with these environment variables.


(High level) ^%POSIX entryrefs

Except for any entryrefs starting with $$, which must be called as
functions, ^%POSIX entryrefs as described below can be called either
as functions or with a DO.  Except where noted, each entry ref can be
invoked in either all upper-case or all lower-case, but not with mixed
case.  These entryrefs have no abbreviations.

    $$filemodeconst^%POSIX(sym)
    Given a symbolic file mode as a string,, e.g., "S_IRWXU" returns
    the numeric value of that mode.  See also the description of
    $&gtmposix.filemodeconst().

    mkdir^%POSIX(dirname,mode)
    Given a directory name as a string, and a mode, as either a
    symbolic or numeric value, creates the directory.

    mktmpdir^%POSIX(.template)
    With a directory name template ending in "XXXXXX" creates a
    directory with a unique name, replacing the "XXXXXX" to return the
    name of the directory created in template.  On platforms where
    mkdtemp() is not available (AIX, HP-UX, and Solaris), GT.M uses
    mkdir to create a temporary directory with a random name created
    by GT.M.

    regfree^%POSIX(pregstrname)
    Given the *name* of a variable with a compiled regular expression
    as a string, frees the memory and ZKILLs the variable.  Note that
    regfree() requires a *variable name* to be passed in as a string.
    For example, after
    regmatch^%POSIX("AIXHP-UXLinuxSolaris","ux","REG_ICASE",,.matches,1),
    the call to regfree to release the memory would be
    regfree^%POSIX("%POSIX(""regmatch"",""ux"",%POSIX(""regmatch"",""REG_ICASE""))")

    regmatch^%POSIX(str,patt,pattflags,matchflags,.matchresults,maxresults)
    regular expression matching in string str for pattern patt that
    compiles the pattern if needed using regcomp() and then matches
    using regmatch().  pattflags are flags used when compiling the
    pattern with regcomp() and matchflags are flags controlling the
    matching provided to regexec().  maxresults is the maximum number
    of matches to be provided.  matchresults is returned as an array,
    where matchresults(n,"start") provides the starting character
    position for the nth match and matchresults(n,"end") is the
    character position in the string for the first character after a
    match, e.g.
    $extract(str,matchresults(2,"start"),matchresults(2,"end")-1)
    provides the second matching substring.  When called as a
    function, the return value is 1 on successful match and 0 if there
    was no match.  On a successful match, prior data in matchresults
    is deleted; otherwise it is left unchanged.  On failing
    compilation, %POSIX("regcomp","errno") contains the error code
    from errlog() and when the match encounters an error (as opposed
    to a failure to match), %POSIX("regexec","errno") contains the
    value of errno.  Local variable nodes
    %POSIX("regmatch",patt,pattflags) contain descriptors of compiled
    patterns and *must* *not* *be* *modified* *by* *your*
    *application* *code*.  To pass multiple flags, simply add the
    numeric values of the individual flags as provided by
    $$regsymval^%POSIX().  Be sure to read Memory Usage
    Considerations, below.  Refer to man regex for more information
    about regular expressions and pattern matching.

    $$regsymval^%POSIX(sym)
    returns the numeric value of a symbolic constant used in regular
    expression pattern matching, such as "REG_ICASE".  Also, it
    provides the sizes of certain structures that M code needs to have
    access to, when provided as strings, such as
    "sizeof(regex_t)", "sizeof(regmatch_t)", and "sizeof(regoff_t)".

    statfile^%POSIX(f,.s)
    provides information about file f in nodes of local variable s.
    All prior nodes of s are deleted.  When called as a function,
    statfile returns 1 unless the underlying call to stat() failed, in
    which case %POSIX("stat","errno") contains errno from the call to
    stat().  Refer to man 2 stat for more information.

    syslog^%POSIX(message,format,facility,level)
    provides a mechanism to log messages to the system log.  format
    defaults to "%s", facility to "LOG_USER" and level to "LOG_INFO".
    When called as a function, syslog returns 1.  Refer to man syslog
    for more information,

    $$version^%POSIX
    returns a version for the gtmposix wrapper in the form of a
    $horolog timestamp.

    $$zhorolog^%POSIX
    provides the time in $horolog format, but with microsecond
    resolution of the number of seconds since midnight.  Note that
    microsecond resolution does not mean microsecond accuracy.


Examples of ^%POSIX usage

Below are examples of usage of high level entryrefs in ^%POSIX.  The
file posixtest.m contains examples of use of the functions in
gtmposix.

    GTM>set str="THE QUICK BROWN FOX JUMPS OVER the lazy dog" 

    GTM>write:$$regmatch^%POSIX(str,"the",,,.result) $extract(str,result(1,"start"),result(1,"end")-1)
    the
    GTM>write:$$regmatch^%POSIX(str,"the","REG_ICASE",,.result) $extract(str,result(1,"start"),result(1,"end")-1)
    THE
    GTM>

    GTM>set retval=$$statfile^%POSIX($ztrnlnm("gtm_dist")_"/mumps",.stat) zwrite stat
    stat("atime")=1332555721
    stat("blksize")=4096
    stat("blocks")=24
    stat("ctime")=1326986163
    stat("dev")=2052
    stat("gid")=0
    stat("ino")=6567598
    stat("mode")=33133
    stat("mtime")=1326986160
    stat("nlink")=1
    stat("rdev")=0
    stat("size")=8700
    stat("uid")=0

    GTM>write stat("mode")\$$filemodeconst^%POSIX("S_IFREG")#2 ; It is a regular file
    1
    GTM>

    GTM>do syslog^%POSIX(str) zsystem "tail -1 /var/log/messages" 
    Mar 24 19:23:12 bhaskark mumps: THE QUICK BROWN FOX JUMPS OVER the lazy dog

    GTM>

    GTM>write $$version^%POSIX," ",$zdate($$version^%POSIX)
    62626,48013 06/18/12
    GTM>

    GTM>write $horolog," : ",$$zhorolog^%POSIX
    62626,60532 : 62626,60532.466276
    GTM>


(Low Level) gtmposix calls

The high level entryrefs in ^%POSIX access low level functions in
gtmposix.c that directly wrap POSIX functions.  Unless otherwise
noted, functions return 0 for a successful completion, and non-zero
otherwise.  Note that some POSIX functions only return success, and
also that a non-zero return value will trigger a "%GTM-E-ZCSTATUSRET,
External call returned error status" GT.M runtime error for your
$ZTRAP or $ETRAP error handler.  The value of errno is returned to M
application code and can be queried for the underlying error.

Note: The gtmposix GT.M interface to call out to POSIX functions is a
low-level interface designed for use by programmers rather than
end-users.  Misuse, abuse and bugs can result in programs that are
fragile, hard to troubleshoot and potentially with security
vulnerabilities.

    $&gtmposix.filemodeconst(fmsymconst,.symval)
    Takes a symbolic regular file mode constant in fmsymconst and
    returns the numeric value in symval.  If no such constant exists,
    the return value is non-zero. Currently supported fmsymconst
    constants are the following. Please see stat() function man page
    for their meaning.

	"S_IFBLK",  "S_IFCHR", "S_IFDIR", "S_IFIFO", "S_IFLNK", "S_IFMT",  "S_IFREG",
	"S_IFSOCK", "S_IRGRP", "S_IROTH", "S_IRUSR", "S_IRWXG", "S_IRWXO", "S_IRWXU",
	"S_ISGID",  "S_ISUID", "S_ISVTX", "S_IWGRP", "S_IWOTH", "S_IWUSR", "S_IXGRP",
	"S_IXOTH",  "S_IXUSR"

    $&gtmposix.gettimeofday(.tvsec,.tvusec,.errno)
    Returns the current time as the number of seconds since the UNIX
    epoch (00:00:00 UTC on 1 January 1970) and the number of
    microseconds within the current second.  See man gettimeofday on
    your POSIX system for more information.

    $&gtmposix.localtime(tvsec,.sec,.min,.hour,.mday,.mon,.year,.wday,.yday,.isdst,.errno)
    Takes a time value in tvsec represented as a number of seconds
    from the epoch - for example as returned by gettimeofday() - and
    returns a number of usable fields for that time value.  See man
    localtime for more information.

    $&gtmposix.mkdtemp(template,.errno)
    With a template for a temporary directory name - the last six
    characters must be "XXXXXX" - creates a unique temporary directory
    and updates template with the name.  See man mkdtemp for more
    information.

    $&gtmposix.mktime(year,month,mday,hour,min,sec,.wday,.yday,.isdst,.unixtime,.errno)
    Takes elements of POSIX broken-down time and returns time since
    the UNIX epoch in seconds in unixtime.  Note that year is the
    offset from 1900 (i.e, 2014 is 114) and month is the offset from
    January (i.e., December is 11).  wday is the day of the week
    offset from Sunday and yday is the day of the year offset from
    January 1 (note that the offsets of dates after March 31 vary
    between leap years and non-leap years).  isdst should be
    initialized to one of 0, 1, or -1 as required by the POSIX
    mktime() function.  If a $horolog value is the source of
    broken-down time, isdst should be -1 since GT.M $horolog reflects
    the state of Daylight Savings time in the timezone of the process,
    but the M application code does not know whether or not Daylight
    Savings Time is in effect; on return from the call, it is 0 if
    Daylight Savings Time is in effect and 1 if it is not.

    $&gtmposix.regcomp(.pregstr,regex,cflags,.errno)
    Takes a regular expression regex, compiles it and returns a
    pointer to a descriptor of the compiled regular expression in
    pregstr.  Application code *must* *not* modify the value of
    pregstr.  cflags specifies the type of regular expression
    compilation.  See man regex for more information.

    $&gtmposix.regconst(regsymconst,.symval)
    Takes a symbolic regular expression constant in regsymconst and
    returns the numeric value in symval.  If no such constant exists,
    the return value is non-zero.  The $$regsymval^%POSIX() function
    uses $&gtmposix.regconst().  Currently supported values of
    regsymconst are:

	"REG_BADBR", "REG_BADPAT", "REG_BADRPT", "REG_EBRACE", "REG_EBRACK", "REG_ECOLLATE",
	"REG_ECTYPE", "REG_EESCAPE", "REG_EPAREN", "REG_ERANGE", "REG_ESPACE", "REG_ESUBREG",
	"REG_EXTENDED", "REG_ICASE", "REG_NEWLINE", "REG_NOMATCH", "REG_NOSUB",
	"REG_NOTBOL", "REG_NOTEOL",
	"sizeof(regex_t)", "sizeof(regmatch_t)", "sizeof(regoff_t)"

    $&gtmposix.regexec(pregstr,string,nmatch,.pmatch,eflags,.matchsuccess)
    Takes a string in string and matches it against a previously
    compiled regular expression whose descriptor is in pregstr with
    matching flags in eflags, for which numeric values can be obtained
    from symbolic values with $$regconst^%POSIX().  nmatch is the
    maximum number of matches to be returned and pmatch is a
    predefined string in which the function returns information about
    substrings matched.  pmatch must be initialized to at least nmatch
    times the size of each match result which you can effect with:
    set $zpiece(pmatch,$zchar(0),nmatch*$$regsymval("sizeof(regmatch_t)")+1)=""
    matchsuccess is 1 if the match was successful, 0 if not.  The
    return value is 0 for both successful and failing matches; a
    non-zero value indicates an error.  See man regex for more
    information.

    $&gtmposix.regfree(pregstr)
    Takes a descriptor for a compiled regular expression, as provided
    by $&gtmposix.regcomp() and frees the memory associated with the
    compiled regular expression.  After executing
    $&gtmposix.regfree(), the descriptor can be safely deleted;
    deleting a descriptor prior to calling this function will result
    in a memory leak because deleting the descriptor makes the memory
    used for the compiled expression unrecoverable.

    $&gtmposix.regofft2int(regofftbytes,.regofftint)
    On both little- and big-endian platforms, takes a sequence of
    bytes of size sizeof(regoff_t) and returns it as an integer.
    $$regsconst^%POSIX("sizeof(regoff_t)") provides the size of
    regoff_t.  Always returns 0

    $&gtmposix.rmdir(pathname,.errno)
    Removes a directory, which must be empty.  See man 2 rmdir for
    more information.

    $&gtmposix.setenv(name,value,overwrite,.errno)
    Sets the value of an environment variable.  name is the name of an
    environment variable (i.e., without a leading "$") and value is the
    value it is to have ($char(0) cannot be part of the value).  If
    the name already has a value, then overwrite must be non-zero in
    order to replace the existing value.  See man setenv for more
    information.

    $&gtmposix.signalval(signame,.sigval)
    Takes a signal name (such as "SIGUSR1") and provides its value in
    sigval.  A non-zero return value means that no value was found for
    the name.  Currently supported signames are:

	"SIGABRT", "SIGALRM", "SIGBUS", "SIGCHLD", "SIGCONT", "SIGFPE", "SIGHUP", "SIGILL",
	"SIGINT", "SIGKILL", "SIGPIPE", "SIGQUIT", "SIGSEGV", "SIGSTOP", "SIGTERM",
	"SIGTRAP", "SIGTSTP", "SIGTTIN", "SIGTTOU", "SIGURG", "SIGUSR1", "SIGUSR2",
	"SIGXCPU", "SIGXFSZ"

    $&gtmposix.stat(fname,.dev,.ino,.mode,.nlink,.uid,.gid,.rdev,.size,.blksize,.blocks,.atime,.mtime,.ctime,.errno)
    Takes the name of a file in fname, and provides information about
    it.  See man 2 stat for more information.

    $&gtmposix.syslog(priority,message,.errno)
    Takes a priority, format and message to log on the system log.
    Priority is itself an OR of a facility and a level.  See man
    syslog for more information.

    $&gtmposix.syslogconst(syslogsymconst,.syslogsymval)
    Takes a symbolic syslog facility or level name (e.g., "LOG_USER")
    in syslogsymconst and returns its value in syslogsymval.  A
    non-zero return value means that a value was not found.  Currently
    supported values of syslogsymconst are.

	"LOG_ALERT", "LOG_CRIT", "LOG_DEBUG", "LOG_EMERG", "LOG_ERR",
	"LOG_INFO", "LOG_LOCAL0", "LOG_LOCAL1", "LOG_LOCAL2",
	"LOG_LOCAL3", "LOG_LOCAL4", "LOG_LOCAL5", "LOG_LOCAL6",
	"LOG_LOCAL7", "LOG_NOTICE", "LOG_USER", "LOG_WARNING"

    $&gtmposix.unsetenv(name,.errno)
    Unsets the value of an environment variable.

posixtest.m contains examples of use of the low level gtmposix
interfaces.


The %POSIX local variable

The gtmposix plugin uses the %POSIX local variable to store
information pertaining to POSIX external calls.  For example, a call
to $&regsymval^%POSIX("REG_NOTBOL") that returns a numeric value also
sets the node %POSIX("regmatch","REG_NOTBOL") to that value.
Subsequent calls to $$regsymval^%POSIX("REG_NOTBOL") return the stored
value rather than calling out the low level function.  This means that
an explicit NEW of %POSIX, an unconditional NEW or an exclusive NEW in
the call stack will result in the stored value being discarded.

If your application already uses %POSIX for another purpose, you can
edit _POSIX.m and replace all occurrences of %POSIX with another
available local variable name.


Memory Usage Considerations

When $&gtmposix.regcomp() is called to compile a regular expression,
it allocates needed memory, and returns a descriptor to the compiled
code.  Until a subsequent call to $&gtmposix.regfree() with that
descriptor, the memory is not freed.  The high level regmatch^%POSIX()
entryref stores descriptors in %POSIX("regmatch",...) nodes.  If these
nodes are deleted without calls to $&gtmposix.regfree() to release
compiled regular expressions, a memory leak is created.  If your
application has explicit, unconditional or exclusive NEWs in the call
stack, you will need to modify it to ensure that memory used to
compile regular expressions does not leak.  Another approach is to
modify _POSIX.m to free the cached compiled reguler expression after
the call to $&gtmposix.regexec()


Error Handling

Entryrefs within ^%POSIX except the top one (calling which is not
meaningful), raise errors but do not set their own error handlers with
$ZTRAP or $ETRAP.  Application code error handlers should deal with
these errors.  In particular, note that non-zero function return
values from $&gtmposix functions will result in ZCSTATUSRET errors.

Look at the end of _POSIX.m for errors raised by entryrefs in %POSIX.

Updates

2014/03/10 10:30:00
-------------------

  Added binding for POSIX function mktime(). Please see above for more details.

  Improve error checking for all implemented functions as follows:
  - posix_gettimeofday returns errno as appropriate. Previously, it returned
    success (0) or failure (-1), but no detailed failure information.

  - posix_localtime returns errno as appropriate for those platforms that
    support it (currently AIX and HP-UX). Previously, it returned success (0) or
    failure (-1), as it still does for Linux and Solaris, but no detailed
    failure information.

  - In case of an argument mismatch, posix_mkdir, posix_mkdtemp, posix_regcomp,
    and posix_stat each set errno as the negative of the input argument count.

  - posix_regcomp and posix_regexec each set errno to the return code from the
    POSIX function regcomp() and regex(). Previously these functions returned
    errno even though these functions do not set it.

  - posix_regexec
    The above plugin function leaves the matched result data buffer unmodified.
    Previously it copied data from an uninitialized pointer.
  
  All functions now enforce variable type conversions. [Unix] (GTM-7969)


2013/01/02 15:00:00
-------------------

* "make test" does not issue DLLNOOPEN error due to unknown directory of the ICU library. Previously, "make test" was halting with
  DLLNOOPEN under UTF-8 mode. (GTM-7875)

* $$filemodeconst^%POSIX() can also report the values for S_IFMT, S_IFSOCK, S_IFLNK, S_IFREG, S_IFBLK, S_IFDIR, S_IFCHR, and
  S_IFIFO. (GTM-7930)
