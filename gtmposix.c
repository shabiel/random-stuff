/************************************************************************/
/*									*/
/*	Copyright 2012, 2014 Fidelity Information Services, Inc.	*/
/*									*/
/*	This source code contains the intellectual property		*/
/*	of its copyright holder(s), and is made available		*/
/*	under a license.  If you do not know the terms of		*/
/*	the license, please stop and do not read further.		*/
/*									*/
/************************************************************************/

/* Caution - these functions are not thread-safe */

#include <errno.h>
#include <regex.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <syslog.h>
#include <time.h>
#include <unistd.h>
#include "gtmxc_types.h"

#define MAXREGEXMEM 65536	/* Maximum memory to allocate for a compiled regular expression */
#define MINMALLOC   64		/* Minimum space to request from gtm_malloc - MAXREGEXMEM/MINMALLOC should be a power of 4 */

/* Translation tables for various include file #define names to the platform values for those names */
/* Names *must* be in alphabetic order of strings; otherwise search will return incorrect results */

static const char *fmodes[] =
{
	"S_IFBLK",  "S_IFCHR", "S_IFDIR", "S_IFIFO", "S_IFLNK", "S_IFMT",  "S_IFREG",
	"S_IFSOCK", "S_IRGRP", "S_IROTH", "S_IRUSR", "S_IRWXG", "S_IRWXO", "S_IRWXU",
	"S_ISGID",  "S_ISUID", "S_ISVTX", "S_IWGRP", "S_IWOTH", "S_IWUSR", "S_IXGRP",
	"S_IXOTH",  "S_IXUSR"
};
static const gtm_int_t fmode_values[] =
{
	S_IFBLK,  S_IFCHR, S_IFDIR, S_IFIFO, S_IFLNK, S_IFMT,  S_IFREG,
	S_IFSOCK, S_IRGRP, S_IROTH, S_IRUSR, S_IRWXG, S_IRWXO, S_IRWXU,
	S_ISGID,  S_ISUID, S_ISVTX, S_IWGRP, S_IWOTH, S_IWUSR, S_IXGRP,
	S_IXOTH,  S_IXUSR
};

static const char *priority[] =
{
	"LOG_ALERT", "LOG_CRIT", "LOG_DEBUG", "LOG_EMERG", "LOG_ERR",
	"LOG_INFO", "LOG_LOCAL0", "LOG_LOCAL1", "LOG_LOCAL2",
	"LOG_LOCAL3", "LOG_LOCAL4", "LOG_LOCAL5", "LOG_LOCAL6",
	"LOG_LOCAL7", "LOG_NOTICE", "LOG_USER", "LOG_WARNING"
};
static const gtm_int_t priority_values[] =
{
	LOG_ALERT, LOG_CRIT, LOG_DEBUG, LOG_EMERG, LOG_ERR,
	LOG_INFO,  LOG_LOCAL0, LOG_LOCAL1, LOG_LOCAL2,
	LOG_LOCAL3, LOG_LOCAL4, LOG_LOCAL5, LOG_LOCAL6,
	LOG_LOCAL7, LOG_NOTICE, LOG_USER, LOG_WARNING
};

static const char *regxflags[] =
{
	"REG_BADBR", "REG_BADPAT", "REG_BADRPT", "REG_EBRACE", "REG_EBRACK", "REG_ECOLLATE",
	"REG_ECTYPE", "REG_EESCAPE", "REG_EPAREN", "REG_ERANGE", "REG_ESPACE", "REG_ESUBREG",
	"REG_EXTENDED", "REG_ICASE", "REG_NEWLINE", "REG_NOMATCH", "REG_NOSUB",
	"REG_NOTBOL", "REG_NOTEOL",
	"sizeof(regex_t)", "sizeof(regmatch_t)", "sizeof(regoff_t)"
};
static const gtm_int_t regxflag_values[] =
{
	REG_BADBR, REG_BADPAT, REG_BADRPT, REG_EBRACE, REG_EBRACK, REG_ECOLLATE,
	REG_ECTYPE, REG_EESCAPE, REG_EPAREN, REG_ERANGE, REG_ESPACE, REG_ESUBREG,
	REG_EXTENDED, REG_ICASE, REG_NEWLINE, REG_NOMATCH, REG_NOSUB,
	REG_NOTBOL, REG_NOTEOL,
	sizeof(regex_t), sizeof(regmatch_t), sizeof(regoff_t)
};

static const char *signals[] =
{
	"SIGABRT", "SIGALRM", "SIGBUS", "SIGCHLD", "SIGCONT", "SIGFPE", "SIGHUP", "SIGILL",
	"SIGINT", "SIGKILL", "SIGPIPE", "SIGQUIT", "SIGSEGV", "SIGSTOP", "SIGTERM",
	"SIGTRAP", "SIGTSTP", "SIGTTIN", "SIGTTOU", "SIGURG", "SIGUSR1", "SIGUSR2",
	"SIGXCPU", "SIGXFSZ"
};
static const gtm_int_t signal_values[] =
{
	SIGABRT, SIGALRM, SIGBUS, SIGCHLD, SIGCONT, SIGFPE, SIGHUP, SIGILL,
	SIGINT, SIGKILL, SIGPIPE, SIGQUIT, SIGSEGV, SIGSTOP, SIGTERM,
	SIGTRAP, SIGTSTP, SIGTTIN, SIGTTOU, SIGURG, SIGUSR1, SIGUSR2,
	SIGXCPU, SIGXFSZ
};

/* POSIX routines */

gtm_status_t posix_gettimeofday(int argc, gtm_long_t *tv_sec, gtm_long_t *tv_usec, gtm_int_t *err_num)
{
	struct timeval	currtimeval;

	*err_num = 0;
	if (3 != argc)
		return (gtm_status_t)(*err_num = -argc); /* Warning - assignment */
	if (-1 == gettimeofday(&currtimeval, NULL)) {
		*err_num = errno;
	} else {
		*tv_sec = (gtm_long_t)currtimeval.tv_sec;
		*tv_usec = (gtm_long_t)currtimeval.tv_usec;
	}
	return (gtm_status_t)*err_num;
}

gtm_status_t posix_localtime(int argc, gtm_long_t timep, gtm_int_t *sec, gtm_int_t *min, gtm_int_t *hour,
			     gtm_int_t *mday, gtm_int_t *mon, gtm_int_t *year, gtm_int_t *wday,
			     gtm_int_t *yday, gtm_int_t *isdst, gtm_int_t *err_num)
{
	struct tm	*currtimetm;

	*err_num = 0;
	if (11 != argc)
		return (gtm_status_t)(*err_num = -argc); /* Warning - assignment */
	if (currtimetm = localtime((time_t *)&timep))  /* Warning - assignment */
	{
		*sec	= (gtm_int_t)currtimetm->tm_sec;
		*min	= (gtm_int_t)currtimetm->tm_min;
		*hour	= (gtm_int_t)currtimetm->tm_hour;
		*mday	= (gtm_int_t)currtimetm->tm_mday;
		*mon	= (gtm_int_t)currtimetm->tm_mon;
		*year	= (gtm_int_t)currtimetm->tm_year;
		*wday	= (gtm_int_t)currtimetm->tm_wday;
		*yday	= (gtm_int_t)currtimetm->tm_yday;
		*isdst	= (gtm_int_t)currtimetm->tm_isdst;
	} else {
#		if defined __SunOS || defined __linux__
		/* Linux & Solaris do not set errno as required by POSIX std as of "IEEE Std 1003.1-2001" */
		*err_num = (gtm_int_t)-1;
#		else
		*err_num = (gtm_int_t)errno;
#		endif
	}
	return (gtm_status_t)*err_num;
}

gtm_status_t posix_mkdir(int argc, gtm_char_t *dirname, gtm_int_t mode, gtm_int_t *err_num)
{
	int	retval;

	if (3 != argc)
		return (gtm_status_t)(*err_num = -argc); /* Warning - assignment */
	/* Possible return codes on error EACCESS, EDQUOT, EEXIST, EFAULT, ELOOP, EMLINK, ENAMETOOLONG, ENOENT, ENOMEM, ENOSPC, ENOTDIR, EPERM, EROFS */
	retval = mkdir((char *)dirname, (mode_t)mode);
	*err_num = (0 == retval) ? 0 : (gtm_int_t)errno; /* if not zero return errno */
	return (gtm_status_t)retval;
}

gtm_status_t posix_mkdtemp(int argc, gtm_char_t *template, gtm_int_t *err_num)
{
	char	*retval;

	if (2 != argc)
		return (gtm_status_t)(*err_num = -argc); /* Warning - assignment */
#	if defined __SunOS || defined __hpux || defined _AIX
	/* Return 0 with template unchanged since neither HP-UX nor Solaris support mkdtemp()
	 * and AIX only supports it effective version 7.x.
	 */
	*err_num = 0;
#	else
	/* Possible return codes on error EACCESS, EDQUOT, EEXIST, EFAULT, ELOOP, EMLINK, ENAMETOOLONG, ENOENT, ENOMEM, ENOSPC, ENOTDIR, EPERM, EROFS */
	retval = mkdtemp((char *)template);
	*err_num = (NULL != retval) ? 0 : (gtm_int_t)errno;
#	endif
	return (gtm_status_t)*err_num;
}

gtm_status_t posix_mktime(int argc, gtm_int_t year, gtm_int_t mon, gtm_int_t mday, gtm_int_t hour,
			  gtm_int_t min, gtm_int_t sec, gtm_int_t *wday, gtm_int_t *yday, gtm_int_t *isdst,
			  gtm_long_t *unixtime, gtm_int_t *err_num)
{
	struct tm	time_str;

	*err_num = 0;
	if (11 != argc)
		return (gtm_status_t)(*err_num = -argc); /* Warning - assignment */
	time_str.tm_year	= (int)year;
	time_str.tm_mon		= (int)mon;
	time_str.tm_mday	= (int)mday;
	time_str.tm_hour	= (int)hour;
	time_str.tm_min		= (int)min;
	time_str.tm_sec		= (int)sec;
	time_str.tm_isdst	= (int)(*isdst);
	*unixtime = (gtm_long_t)mktime(&time_str);
	if (-1 == *unixtime)
	{
#	if defined __SunOS || defined __hpux
		/* Solaris and HPUX set errno for mktime */
		*err_num = (gtm_int_t)errno;
#	else
		*err_num = (gtm_int_t)-1;
#	endif
	} else
	{
		*wday		= (gtm_int_t)time_str.tm_wday;
		*yday		= (gtm_int_t)time_str.tm_yday;
		/* Only set DST if passed -1 */
		if (-1 == *isdst)
		{
			*isdst	= (gtm_int_t)time_str.tm_isdst;
		}
	}
	return (gtm_status_t)*err_num;
}

gtm_status_t posix_regcomp(int argc, gtm_string_t *pregstr, gtm_char_t *regex, gtm_int_t cflags, gtm_int_t *err_num)
{
	int	retval;
	regex_t *preg;

	*err_num = 0;
	if (4 != argc)
		return (gtm_status_t)(*err_num = -argc); /* Warning - assignment */
	preg = (regex_t *)gtm_malloc(sizeof(regex_t));
	retval = regcomp(preg, regex, (int)cflags);
	if (retval)
	{	/* While AIX _may_ set errno, the open group specifically calls this function out as NOT setting errno. Each
		 * platform uses a set of return codes which are all defined in /usr/include/regex.h. All but Solaris list these
		 * error codes in the man page */
		*err_num = (gtm_int_t)retval;
		return (gtm_status_t)*err_num;
	}
	(pregstr->length) = sizeof(gtm_char_t *);
	memcpy(pregstr->address, &preg, pregstr->length);
	return (gtm_status_t)*err_num;
}

/* posix_regexec() does not entirely follow the implementation of the POSIX regexec(). The latter returns 0 for a
 * successful match, REG_NOMATCH otherwise. But returning non-zero to GT.M from a C function will invoke the GT.M
 * error trap, which is not desirable for the non-match of a pattern.  Therefore, posix_regexec() always returns
 * zero and the result of the match is in the parameter *matchsuccess with 1 meaning a successful match and 0
 * otherwise.
 */
gtm_status_t posix_regexec(int argc, gtm_string_t *pregstr, gtm_char_t *string, gtm_int_t nmatch, gtm_string_t *pmatch,
			   gtm_int_t eflags, gtm_int_t *matchsuccess)
{
	int		retval;
        regex_t         *preg;
	regmatch_t	*result;
	size_t		resultsize;

	*matchsuccess = 0;
	if (6 != argc)
		return (gtm_status_t)-argc;
	memcpy(&preg, pregstr->address, pregstr->length);
	resultsize = nmatch * sizeof(regmatch_t);
	result = (regmatch_t *)gtm_malloc(resultsize);
	retval = regexec(preg, (char *)string, (size_t)nmatch, result, (int)eflags);
	*matchsuccess = (0 == retval);
	if (*matchsuccess)
		memcpy(pmatch->address, result, resultsize);
	gtm_free((void*)result);
	return (gtm_status_t)0;
}

gtm_status_t posix_regfree(int argc, gtm_string_t *pregstr)
{
	regex_t	*preg;

	if (1 != argc)
		return (gtm_status_t)-argc;
	memcpy(&preg, pregstr->address, pregstr->length);
	/* regfree is a void function */
	regfree(preg);
	gtm_free((void *)preg);
	return (gtm_status_t)0;
}

gtm_status_t posix_rmdir(int argc, gtm_char_t *pathname, gtm_int_t *err_num)
{
	gtm_status_t	retval;

	if (2 != argc)
		return (gtm_status_t)(*err_num = -argc); /* Warning - assignment */
	retval = (gtm_status_t)rmdir((const char *)pathname);
	*err_num = (retval) ? (gtm_int_t)errno : 0;
	return retval;
}

gtm_status_t posix_setenv(int argc, gtm_char_t *name, gtm_char_t *value, gtm_int_t overwrite, gtm_int_t *err_num)
{
	gtm_status_t	retval;

	if (4 != argc)
		return (gtm_status_t)(*err_num = -argc); /* Warning - assignment */
	retval = (gtm_status_t)setenv((char *)name, (char *)value, (int)overwrite);
	*err_num = (retval) ? (gtm_int_t)errno : 0;
	return retval;
}

gtm_status_t posix_stat(int argc, gtm_char_t *fname, gtm_ulong_t *dev, gtm_ulong_t *ino, gtm_ulong_t *mode,
			gtm_ulong_t *nlink, gtm_ulong_t *uid, gtm_ulong_t *gid, gtm_ulong_t *rdev, gtm_long_t *size,
			gtm_long_t *blksize, gtm_long_t *blocks, gtm_long_t *atime, gtm_long_t *mtime,
			gtm_long_t *ctime, gtm_int_t *err_num)
{
	struct stat	thisfile;
	gtm_status_t	retval;

	*err_num = 0;
	if (15 != argc)
		return (gtm_status_t)(*err_num = -argc); /* Warning - assignment */
	retval = (gtm_status_t)stat((char *)fname, &thisfile);
	if (retval)
	{
		*err_num = (gtm_int_t)errno;
		return retval;
	}
	*dev     = (gtm_ulong_t)thisfile.st_dev;	/* ID of device containing file */
	*ino     = (gtm_ulong_t)thisfile.st_ino;	/* inode number */
	*mode    = (gtm_ulong_t)thisfile.st_mode;	/* protection */
	*nlink   = (gtm_ulong_t)thisfile.st_nlink;	/* number of hard links */
	*uid     = (gtm_ulong_t)thisfile.st_uid;	/* user ID of owner */
	*gid     = (gtm_ulong_t)thisfile.st_gid;	/* group ID of owner */
	*rdev    = (gtm_ulong_t)thisfile.st_rdev;	/* device ID (if special file) */
	*size    = (gtm_long_t)thisfile.st_size;	/* total size, in bytes */
	*blksize = (gtm_long_t)thisfile.st_blksize;	/* blocksize for file system I/O */
	*blocks  = (gtm_long_t)thisfile.st_blocks;	/* number of 512B blocks allocated */
	*atime   = (gtm_long_t)thisfile.st_atime;	/* time of last access */
	*mtime   = (gtm_long_t)thisfile.st_mtime;	/* time of last modification */
	*ctime   = (gtm_long_t)thisfile.st_ctime;	/* time of last status change */
	return retval;
}

/* posix_syslog() does not entirely follow the format of POSIX syslog().  For one thing, syslog() provides for a
 * variable number of arguments, whereas posix_syslog() can only provide a fixed number.  For another, per
 * http://lab.gsi.dit.upm.es/semanticwiki/index.php/Category:String_Format_Overflow_in_syslog()
 * the safe way to use syslog() is to force the format to "%s".
 * Note that while POSIX syslog() returns no value, posix_syslog() returns 0; otherwise, GT.M will raise a
 * runtime error.
 */
gtm_status_t posix_syslog(int argc, gtm_int_t priority, gtm_char_t *message)
{
	if (2 != argc)
		return (gtm_status_t)-argc;
	/* syslog() is a void function */
	syslog((int)priority, "%s", (char *)message);
	return (gtm_status_t)0;
}

gtm_status_t posix_unsetenv(int argc, gtm_char_t *name, gtm_int_t *err_num)
{
	gtm_status_t retval;

	if (2 != argc)
		return (gtm_status_t)(*err_num = -argc); /* Warning - assignment */
	retval = (gtm_status_t)unsetenv(name);
	*err_num = (retval) ? (gtm_int_t)errno : 0;
	return retval;
}

/* Helper routines */

/* Given a symbolic constant for regex facility or level, provide the numeric value */
gtm_status_t posixhelper_regconst(int argc, gtm_char_t *symconst, gtm_int_t *symval)
{
	if (2 != argc)
		return (gtm_status_t)-argc;
	return posixutil_searchstrtab(regxflags, regxflag_values, sizeof(regxflags) / sizeof(regxflags[0]), symconst, symval);
}


/* Given a symbolic constant for file mode, provide the numeric value */
gtm_status_t posixhelper_filemodeconst(int argc, gtm_char_t *symconst, gtm_int_t *symval)
{
	if (2 != argc)
		return (gtm_status_t)-argc;
	return posixutil_searchstrtab(fmodes, fmode_values, sizeof(fmodes) / sizeof(fmodes[0]), symconst, symval);
}

/* Endian independent conversion from regmatch_t bytestring to offsets */
gtm_status_t posixhelper_regofft2offsets(int argc, gtm_string_t *regofftbytes, gtm_int_t *rmso, gtm_int_t *rmeo)
{
	regmatch_t	buf;

	if (3 != argc)
		return (gtm_status_t)-argc;
	memcpy(&buf, regofftbytes->address, sizeof(regmatch_t));
	*rmso = (gtm_int_t)((regoff_t)(buf.rm_so));
	*rmeo = (gtm_int_t)((regoff_t)(buf.rm_eo));
	return 0;
}

/* Given a signal name, provide the numeric value */
gtm_status_t posixhelper_signalval(int argc, gtm_char_t *symconst, gtm_int_t *symval)
{
	if (2 != argc)
		return (gtm_status_t)-argc;
	return posixutil_searchstrtab(signals, signal_values, sizeof(signals) / sizeof(signals[0]), symconst, symval);
}

/* Given a symbolic constant for syslog facility or level, provide the numeric value */
gtm_status_t posixhelper_syslogconst(int argc, gtm_char_t *symconst, gtm_int_t *symval)
{
	if (2 != argc)
		return (gtm_status_t)-argc;
	return posixutil_searchstrtab(priority, priority_values, sizeof(priority) / sizeof(priority[0]), symconst, symval);
}

/* Utility routines used by other functions above */

gtm_status_t posixutil_searchstrtab(char *tblstr[], gtm_int_t tblval[], gtm_int_t tblsize, char *str, gtm_int_t *strval)
{
	gtm_int_t	compflag, current, first, last;

	first = 0;
	last = tblsize - 1;
	for (; ;)
	{
		current = (first + last) / 2;
		compflag = strcmp(tblstr[current], str);
		if (0 == compflag)
		{
			*strval = tblval[current];
			return (gtm_status_t)0;
		}
		if (first == last)
			return (gtm_status_t)1;
		if (0 > compflag)
			first = (first == current) ? (current + 1) : current;
		else
			last = current;
	}
}
