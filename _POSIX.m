;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;									;
;	Copyright 2012, 2014 Fidelity Information Services, Inc.	;
;									;
;	This source code contains the intellectual property		;
;	of its copyright holder(s), and is made available		;
;	under a license.  If you do not know the terms of		;
;	the license, please stop and do not read further.		;
;									;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%POSIX	; High level wrappers to low level POSIX functions
	set:'$length($etrap)&(("B"=$ztrap)!'$length($ztrap)) $etrap="set $etrap=""use $principal write $zstatus,! zhalt 1"" set tmp1=$piece($ecode,"","",2),tmp2=$text(@tmp1) if $length(tmp2) write $text(+0),@$piece(tmp2,"";"",2),! zhalt +$extract(tmp1,2,$length(tmp1))"
	set $ecode=",U255,"	      ; must call an entryref
	quit

; Get value for symbolic file modes - only lower case because this is an internal utility routine
filemodeconst(sym)	; get numeric value for file mode symbolic constant
	quit:$data(%POSIX("filemode",sym)) %POSIX("filemode",sym)
	new retval,symval
	set retval=$&gtmposix.filemodeconst(sym,.symval),%POSIX("filemode",sym)=symval
	quit symval

; Create a directory
MKDIR(dirname,mode)
	new retval
	set retval=$$mkdir(dirname,mode)
	quit:$quit retval quit
mkdir(dirname,mode)
	new errno,retval
	set retval=$&gtmposix.mkdir(dirname,$select(mode'=+mode:$$filemodeconst(mode),1:mode),.errno)
	quit:$quit 'retval quit

; Create a temporary directory
MKTMPDIR(template)
	new retval
	set retval=$$mktmpdir(.template)
	quit:$quit retval quit
mktmpdir(template)
	new errno,mode,retval,savetemplate
	set:"XXXXXX"'=$extract(template,$length(template)-5,$length(template)) $ecode=",U254,"
	set savetemplate=template,retval=$&gtmposix.mkdtemp(.template,.errno)
	if savetemplate=template do
	. set $extract(template,$length(template)-5,$length(template))=$$^%RANDSTR(6)
	. set retval='$$mkdir(template,"S_IRWXU")
	quit:$quit 'retval quit

; Discard a previously compiled regular expression - *must* be passed by variable name
REGFREE(pregstr)
	new retval
	set retval=$$regfree(pregstr)
	quit:$quit retval quit
regfree(pregstr)
	if $&gtmposix.regfree(@pregstr)
	zkill @pregstr
	quit:$quit 1 quit

; Match a regular expression
REGMATCH(str,patt,pattflags,matchflags,matchresults,maxresults)
	new retval
	set retval=$$regmatch($get(str),$get(patt),$get(pattflags),$get(matchflags),.matchresults,$get(maxresults))
	quit:$quit retval quit
regmatch(str,patt,pattflags,matchflags,matchresults,maxresults)
	new errno,i,j,mfval,matchsuccess,nextmf,nextpf,nextrmeo,nextrmso,pfval,pregstr,regmatchtsize,regofftsize,resultbuf
	if $length($get(pattflags)) for i=1:1:$length(pattflags,"+") do
	. set nextpf=$piece(pattflags,"+",i)
	. if $increment(pfval,$select(nextpf'=+nextpf:$$regsymval(nextpf),1:nextpf))
	else  set pfval=0
	do:'$data(%POSIX("regmatch",patt,pfval))
	. if $&gtmposix.regcomp(.pregstr,patt,pfval,.errno)
	. zkill %POSIX("regcomp","errno")
	. set %POSIX("regmatch",patt,pfval)=pregstr
	set:'$data(maxresults) maxresults=1
	set $zpiece(resultbuf,$zchar(0),maxresults*$$regsymval("sizeof(regmatch_t)")+1)=""
	if $length($get(matchflags)) for i=1:1:$length(matchflags,"+") do
	. set nextmf=$piece(matchflags,"+",i)
	. if $increment(mfval,$select(nextmf'=+nextmf:$$regsymval(nextmf),1:nextmf))
	else  set mfval=0
	if $&gtmposix.regexec(%POSIX("regmatch",patt,pfval),str,maxresults,.resultbuf,mfval,.matchsuccess)
	zkill %POSIX("regexec","errno")
	do:matchsuccess
	. kill matchresults
	. set regmatchtsize=$$regsymval("sizeof(regmatch_t)"),j=1 for i=1:1:maxresults do  if 'matchresults(i,"start") kill matchresults(i) quit
	. . if $&gtmposix.regofft2offsets($zextract(resultbuf,j,$increment(j,regmatchtsize)-1),.nextrmso,.nextrmeo)
	. . set matchresults(i,"start")=1+nextrmso
	. . set matchresults(i,"end")=1+nextrmeo
	quit:$quit matchsuccess quit

; Get numeric value for regular expression symbolic constant - only lower case because this is an internal utility routine
regsymval(sym)
	quit:$data(%POSIX("regmatch",sym)) %POSIX("regmatch",sym)
	new retval,symval
	set retval=$&gtmposix.regconst(sym,.symval),%POSIX("regmatch",sym)=symval
	quit symval

; Return attributes for a file in a local variable passed in by reference
STATFILE(f,s)
	new retval
	set retval=$$statfile(f,.s)
	quit:$quit retval quit
statfile(f,s)
	new atime,blksize,blocks,ctime,dev,errno,gid,ino,mode,mtime,nlink,rdev,retval,size,uid
	set retval=$&gtmposix.stat(f,.dev,.ino,.mode,.nlink,.uid,.gid,.rdev,.size,.blksize,.blocks,.atime,.mtime,.ctime,.errno)
	if retval set %POSIX("stat","errno")=errno
	else  zkill %POSIX("stat","errno")
	kill s
	set s("atime")=atime
	set s("blksize")=blksize
	set s("blocks")=blocks
	set s("ctime")=ctime
	set s("dev")=dev
	set s("gid")=gid
	set s("ino")=ino
	set s("mode")=mode
	set s("mtime")=mtime
	set s("nlink")=nlink
	set s("rdev")=rdev
	set s("size")=size
	set s("uid")=uid
	quit:$quit 'retval quit

; Log a message to the system log
SYSLOG(message,facility,level)
	new retval
	set retval=$$syslog($get(message),$get(facility),$get(level))
	quit:$quit retval quit
syslog(message,facility,level)
	if $data(facility)#10 set:facility'=+facility facility=$$syslogval(facility)
	else  set facility=$$syslogval("LOG_USER")
	if $data(level)#10 set:level'=+level level=$$syslogval(level)
	else  set level=$$syslogval("LOG_INFO")
	if $&gtmposix.syslog(+facility+level,message)
	quit:$quit 1 quit
syslogval(msg)	; get numeric value for syslog symbolic constant
	quit:$data(%POSIX("syslog",msg))#10 %POSIX("syslog",msg)
	new retval,msgval
	set retval=$&gtmposix.syslogconst(msg,.msgval),%POSIX("syslog",msg)=msgval
	quit msgval

; Provide a version number for this wrapper based on the CVS check in timestamp
VERSION() quit $$version
version()
	new tmp,tmp1,tmp2,tmp3
	set tmp="$Date: 2014/03/04 10:30:00 $" set:8=$length(tmp) tmp="$Date: "_$zdate($horolog,"YYYY/MM/DD 24:60:SS")_" $"
	set tmp1=$piece(tmp," ",2),tmp1=$piece(tmp1,"/",2,3)_"/"_$piece(tmp1,"/",1)
	set tmp2=$piece(tmp," ",3),tmp3=$piece(tmp2,":",3),tmp2=$piece(tmp2,":",1)#13_":"_$piece(tmp2,":",2)_$select(tmp2\13:"PM",1:"AM")
	quit $$FUNC^%DATE(tmp1)_","_(tmp3+$$FUNC^%TI(tmp2))


; Extrinsic special variable that extends $HOROLOG and reports in microseconds
ZHOROLOG()   quit $$zhorolog()
zhorolog()
	new day,errno,hour,isdst,mday,min,mon,retval,sec,tvsec,tvusec,wday,yday,year
	if $&gtmposix.gettimeofday(.tvsec,.tvusec,.errno)
	zkill %POSIX("gettimeofday","errno")
	set retval=$&gtmposix.localtime(tvsec,.sec,.min,.hour,.mday,.mon,.year,.wday,.yday,.isdst,.errno)
	if retval set %POSIX("localtime","errno")=errno
	else  zkill %POSIX("localtime","errno")
	quit $$FUNC^%DATE(mon+1_"/"_mday_"/"_(1900+year))_","_(hour*60+min*60+sec)_$select(tvusec:tvusec*1E-6,1:"")

;	Error message texts
U254	;"-F-BADTEMPLATE Template "_template_" does not end in ""XXXXXX"""
U255	;"-F-BADINVOCATION Must call an entryref in "_$text(+0)
