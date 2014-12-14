;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;									;
;	Copyright 2012, 2014 Fidelity Information Services, Inc.    	;
;									;
;	This source code contains the intellectual property		;
;	of its copyright holder(s), and is made available		;
;	under a license.  If you do not know the terms of		;
;	the license, please stop and do not read further.		;
;									;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
posixtest	; test POSIX plugin
	; Initialization
        new ddzh,dh1,dh2,dir,file,errno,gid,hour,i,io,isdst,min,month,msg,os,oslist,out,result,retval,sec,stat,syslog1,syslog2,tmp,tv,tvsec,tvusec,uid,ver1,ver2,year
        set io=$io
        set os=$piece($zv," ",3)
        set setenvtst=1
        set arch=$piece($zv," ",4)
        if "HP-PA"=arch set setenvtst=0
	 if "Solaris"=os  do
        . open "unamer":(shell="/bin/sh":command="uname -r")::"pipe"
        . use "unamer" read opsver
        . close "unamer"
        . if "5.9"=opsver set setenvtst=0
        set syslog1=$ztrnlnm("syslog_warning")
        set:'$length(syslog1) syslog1=$select("AIX"=os!("Solaris"=os)!("OSF1"=os):"/usr/library/syslog/syslog","HP-UX"=os:"/var/adm/syslog/syslog.log","Linux"=os:"/var/log/messages",1:"")
        if '$length(syslog1) write "FAIL syslog1 is null string",! quit
        if '$length($zsearch(syslog1,154)) write "FAIL file syslog1=",syslog1," does not exist",! quit
        set syslog2=$ztrnlnm("syslog_info")
        set:'$length(syslog2) syslog2=$select("AIX"=os!("Solaris"=os)!("OSF1"=os):"/usr/library/syslog/syslog","HP-UX"=os:"/var/adm/syslog/syslog.log","Linux"=os:"/var/log/user.log",1:"")
        set tmp=$zsearch(syslog2,155) if '$length(tmp) write "tmp=",tmp,!,"FAIL file syslog2=",syslog2," does not exist",! quit

        ; Get version - check it later
        set ver1=$$version^%POSIX
        set ver2=$$VERSION^%POSIX

        ; Verify that command line invocation fails with error message
        open "POSIX":(shell="/bin/sh":command="$gtm_dist/mumps -run %POSIX":readonly:stderr="POSIXerr")::"pipe"
        use "POSIX" for i=1:1 read tmp quit:$zeof  set out1(i)=tmp
        use "POSIXerr" for i=1:1 read tmp quit:$zeof  set out2(i)=tmp
        use io close "POSIX"
        if "%POSIX-F-BADINVOCATION Must call an entryref in %POSIX"=$get(out1(1))&'$data(out2) write "PASS Invocation",!
        else  write "FAIL Invocation",! zwrite:$data(out1) out1  zwrite:$data(out2) out2

        ; Check $zhorolog/$ZHOROLOG
        ; retry until microsec returned by $zhorolog
        for  set dh1=$horolog,ddzh=$$zhorolog^%POSIX,dh2=$horolog quit:(dh1=dh2)&$piece(ddzh,".",2)
        if dh1'=$piece(ddzh,".",2) write "PASS $zhorolog",!
        else  write "FAIL $zhorolog $horolog=",dh1," $$zhorolog^%POSIX=",ddzh,!
        for  set dh1=$horolog,ddzh=$$ZHOROLOG^%POSIX,dh2=$horolog quit:(dh1=dh2)&$piece(ddzh,".",2)
        if dh1=$piece(ddzh,".",2) write "FAIL $ZHOROLOG $horolog=",dh1," $$ZHOROLOG^%POSIX=",ddzh,!
        else  write "PASS $ZHOROLOG",!

	; Check mktime()
	set tmp=$zdate(dh1,"YYYY:MM:DD:24:60:SS:DAY","","0,1,2,3,4,5,6"),isdst=-1
	set retval=$&gtmposix.mktime($piece(tmp,":",1)-1900,$piece(tmp,":",2)-1,+$piece(tmp,":",3),+$piece(tmp,":",4),+$piece(tmp,":",5),+$piece(tmp,":",6),.wday,.yday,.isdst,.tvsec,.errno)
	write "Daylight Savings Time is ",$select('isdst:"not ",1:""),"in effect",!
	set retval=$&gtmposix.localtime(tvsec,.sec,.min,.hour,.mday,.mon,.year,.wday,.yday,.isdst,.errno)
	set computeddh1=($$FUNC^%DATE(mon+1_"/"_mday_"/"_(1900+year))_","_($$FUNC^%TI($translate($justify(hour,2)_$justify(min,2)," ",0))+sec))
	if $piece(tmp,":",7)=wday&(dh1=computeddh1) write "PASS mktime()",!
	else  write "FAIL mktime() $horolog=",dh1," Computed=",computeddh1,!

        ; Check that we get at least fractional second times - this test has 1 in 10**12 chance of failing incorrectly
        set tmp="PASS Microsecond resolution"
        for i=0:1  set retval=$&gtmposix.gettimeofday(.tvsec,.tvusec,.errno) quit:tvusec  set:i $extract(tmp,1,4)="FAIL"
        write tmp,!
        set tv=tvusec/1E6+tvsec

        ; Check regular expression pattern matching
        set oslist="AIXHP-UXLinuxSolaris"
        if $$regmatch^%POSIX(oslist,"ux",,,.result,3)&("ux"=$extract(oslist,result(1,"start"),result(1,"end")-1)) write "PASS regmatch^%POSIX 1",!
        else  write "FAIL regmatch^%POSIX 1",!
        set tmp=$order(%POSIX("regmatch","ux","")) do regfree^%POSIX("%POSIX(""regmatch"",""ux"","_tmp_")")
        if $data(%POSIX("regmatch","ux",tmp))#10 write "FAIL regfree^%POSIX",!
        else  write "PASS regfree^%POSIX",!
        if $$REGMATCH^%POSIX(oslist,"ux",,,.result,3)&("ux"=$extract(oslist,result(1,"start"),result(1,"end")-1)) write "PASS REGMATCH^%POSIX 1",!
        else  write "FAIL REGMATCH^%POSIX 1",!
        set tmp=$order(%POSIX("regmatch","ux","")) do REGFREE^%POSIX("%POSIX(""regmatch"",""ux"","_tmp_")")
        if $data(%POSIX("regmatch","ux",tmp))#10 write "FAIL REGFREE^%POSIX",!
        else  write "PASS REGFREE^%POSIX",!
        if $$regmatch^%POSIX(oslist,"ux","REG_ICASE",,.result,3)&("UX"=$extract(oslist,result(1,"start"),result(1,"end")-1)) write "PASS regmatch^%POSIX 2",!
        else  write "FAIL regmatch^%POSIX 2",!
        do regfree^%POSIX("%POSIX(""regmatch"",""ux"","_$order(%POSIX("regmatch","ux",""))_")")
        if $$REGMATCH^%POSIX(oslist,"ux","REG_ICASE",,.result,3)&("UX"=$extract(oslist,result(1,"start"),result(1,"end")-1)) write "PASS REGMATCH^%POSIX 2",!
        else  write "FAIL REGMATCH^%POSIX 2",!
        do REGFREE^%POSIX("%POSIX(""regmatch"",""ux"","_$order(%POSIX("regmatch","ux",""))_")")
        if $$regmatch^%POSIX(oslist,"S$","REG_ICASE",,.result,3)&("s"=$extract(oslist,result(1,"start"),result(1,"end")-1)) write "PASS regmatch^%POSIX 3",!
        else  write "FAIL regmatch^%POSIX 3",!
        do regfree^%POSIX("%POSIX(""regmatch"",""S$"","_$order(%POSIX("regmatch","S$",""))_")")
        if $$REGMATCH^%POSIX(oslist,"S$","REG_ICASE",,.result,3)&("s"=$extract(oslist,result(1,"start"),result(1,"end")-1)) write "PASS REGMATCH^%POSIX 3",!
        else  write "FAIL REGMATCH^%POSIX 3",!
        do REGFREE^%POSIX("%POSIX(""regmatch"",""S$"","_$order(%POSIX("regmatch","S$",""))_")")
        if $$regmatch^%POSIX(oslist,"S$","REG_ICASE",,.result,3)&("s"=$extract(oslist,result(1,"start"),result(1,"end")-1)) write "PASS regmatch^%POSIX 3",!
        else  write "FAIL regmatch^%POSIX 3",!
        do regfree^%POSIX("%POSIX(""regmatch"",""S$"","_$order(%POSIX("regmatch","S$",""))_")")
        if $$REGMATCH^%POSIX(oslist,"S$","REG_ICASE",,.result,3)&("s"=$extract(oslist,result(1,"start"),result(1,"end")-1)) write "PASS REGMATCH^%POSIX 3",!
        else  write "FAIL REGMATCH^%POSIX 3",!
        do REGFREE^%POSIX("%POSIX(""regmatch"",""S$"","_$order(%POSIX("regmatch","S$",""))_")")
        if $$regmatch^%POSIX(oslist,"\([[:alnum:]]*\)-\([[:alnum:]]*\)",,,.result,5)&(oslist=$extract(oslist,result(1,"start"),result(1,"end")-1))&("AIXHP"=$extract(oslist,result(2,"start"),result(2,"end")-1))&("UXLinuxSolaris"=$extract(oslist,result(3,"start"),result(3,"end")-1))&(3=$order(result(""),-1)) write "PASS regmatch^%POSIX 4",!
        else  write "FAIL regmatch^%POSIX 4",!
        do regfree^%POSIX("%POSIX(""regmatch"",""\([[:alnum:]]*\)-\([[:alnum:]]*\)"","_$order(%POSIX("regmatch","\([[:alnum:]]*\)-\([[:alnum:]]*\)",""))_")")
        if $$REGMATCH^%POSIX(oslist,"\([[:alnum:]]*\)-\([[:alnum:]]*\)",,,.result,5)&(oslist=$extract(oslist,result(1,"start"),result(1,"end")-1))&("AIXHP"=$extract(oslist,result(2,"start"),result(2,"end")-1))&("UXLinuxSolaris"=$extract(oslist,result(3,"start"),result(3,"end")-1))&(3=$order(result(""),-1)) write "PASS REGMATCH^%POSIX 4",!
        else  write "FAIL REGMATCH^%POSIX 4",!
        do REGFREE^%POSIX("%POSIX(""regmatch"",""\([[:alnum:]]*\)-\([[:alnum:]]*\)"","_$order(%POSIX("regmatch","\([[:alnum:]]*\)-\([[:alnum:]]*\)",""))_")")
        if $$regmatch^%POSIX(oslist,"^AIX",,"REG_NOTBOL",.result,3) write "FAIL regmatch^%POSIX 5",!
        else  write "PASS regmatch^%POSIX 5",!
        do regfree^%POSIX("%POSIX(""regmatch"",""^AIX"","_$order(%POSIX("regmatch","^AIX",""))_")")
        if $$REGMATCH^%POSIX(oslist,"^AIX",,"REG_NOTBOL",.result,3) write "FAIL REGMATCH^%POSIX 5",!
        else  write "PASS REGMATCH^%POSIX 5",!
        do REGFREE^%POSIX("%POSIX(""regmatch"",""^AIX"","_$order(%POSIX("regmatch","^AIX",""))_")")

        ; Check statfile - indirectly tests mkdtemp also. Note that not all stat parameters can be reliably tested
        if ("OSF1"=os) set dir="posixtest"_$j_"_XXXXXX"
        else  set dir="/tmp/posixtest"_$j_"_XXXXXX"
        set retval=$$mktmpdir^%POSIX(.dir) write:'retval "FAIL mktmpdir retval=",retval,!
        set retval=$$statfile^%POSIX(.dir,.stat) write:'retval "FAIL statfile retval=",retval,!
        if stat("ino") write "PASS mktmpdir",!
        else  write "FAIL mktmpdir stat(ino)=",stat(ino),!
        ;Check that mtime atime and ctime atime are no more than 1 sec apart and tvsec is not greater that ctime
        set diffma=stat("mtime")-stat("atime")
        set:diffma<0 diffma=-diffma
        set diffca=stat("ctime")-stat("atime")
        set:diffca<0 diffca=-diffca
	; Normally tvsec is no greater than each of mtime, ctime and atime. However, we have seen one failure that made us change
	; tvsec<=stat("ctime") to tvsec-1<=stat("ctime") <time_shift_gtmposix>
        if ((diffma'>1)&(diffca'>1)&(tvsec-1'>stat("ctime"))) write "PASS statfile.times",!
        else  write "FAIL statfile.times dir=",dir," atime=",stat("atime")," ctime=",stat("ctime")," mtime=",stat("mtime")," tv_sec=",tvsec,!
        open "uid":(shell="/bin/sh":command="id -u":readonly)::"pipe"
        use "uid" read uid use io close "uid"
        open "gid":(shell="/bin/sh":command="id -g":readonly)::"pipe"
        use "gid" read gid use io close "gid"
        if stat("gid")=gid&(stat("uid")=uid) write "PASS statfile.ids",!
        else  write "FAIL statfile.ids gid=",gid," stat(""gid"")=",stat("gid")," uid=",uid," stat(""uid"")=",stat("uid"),!
	; Check that mode from stat has directory bit set, but not regular file bit
	set tmp=$$filemodeconst^%POSIX("S_IFREG"),tmp=$$filemodeconst^%POSIX("S_IFDIR")
	if stat("mode")\%POSIX("filemode","S_IFDIR")#2&'(stat("mode")\%POSIX("filemode","S_IFREG")#2) write "PASS filemodeconst^%POSIX",!
	else  write "FAIL filemodeconst^%POSIX mode=",stat("mode")," S_IFDIR=",%POSIX("filemode","S_IFDIR")," S_IFREG=",%POSIX("filemode","S_IFREG"),!

        ; Check signal & STATFILE
        set file="GTM_JOBEXAM.ZSHOW_DMP_"_$j_"_1"
        if $&gtmposix.signalval("SIGUSR1",.result)!$zsigproc($j,result) write "FAIL signal",!
        else  write "PASS signal",!
        set retval=$$STATFILE^%POSIX(.file,.stat) write:'retval "FAIL STATFILE",!
        if ((stat("mtime")-(stat("atime")+stat("ctime")/2)'>1)&(tvsec-1'>stat("ctime"))) write "PASS STATFILE.times",!
        else  write "FAIL STATFILE.times file=",file," atime=",stat("atime")," ctime=",stat("ctime")," mtime=",stat("mtime")," tv_sec=",tvsec,!
        open "uid":(shell="/bin/sh":command="id -u":readonly)::"pipe"
        use "uid" read uid use io close "uid"
        open "gid":(shell="/bin/sh":command="id -g":readonly)::"pipe"
        use "gid" read gid use io close "gid"
        if stat("gid")=gid&(stat("uid")=uid) write "PASS STATFILE.ids",!
        else  write "FAIL STATFILE.ids gid=",gid," stat(""gid"")=",stat("gid")," uid=",uid," stat(""uid"")=",stat("uid"),!
        zsystem "rm -f "_file

	; Execute the syslog test if in M mode
        ; Check syslog - caveat: test assumes call to syslog gets message there before process reads it
        ; Also,location of messages depends on syslog configuration
        if ("M"=$zchset) do
        . set msg="Warning from process "_$j_" at "_ddzh,out="FAIL syslog - msg """_msg_""" not found in "_syslog1
        . if $$syslog^%POSIX(msg,"LOG_USER","LOG_WARNING")
        . open syslog1:(readonly:exception="set tname=syslog1 g BADOPEN")
        . ; wait 1 sec before trying read.  If the read still fails you may have to increase the time.
        . hang 1
        . use syslog1 for  read tmp quit:$zeof  if $find(tmp,msg) set out="PASS syslog" quit
        . use io close syslog1
        . write out,!
        . if ("OSF1"=os) set logtype="LOG_USER"
        . else  set logtype="LOG_ERR"
        . set msg="Notice from process "_$j_" at "_ddzh,out="FAIL SYSLOG - msg """_msg_""" not found in "_syslog1
        . if $$SYSLOG^%POSIX(msg,logtype,"LOG_INFO")
        . open syslog2:(readonly:exception="s tname=syslog2 g BADOPEN")
        . ; wait 1 sec before trying read.  If the read still fails you may have to increase the time.
        . hang 1
        . use syslog2 for  read tmp quit:$zeof  if $find(tmp,msg) set out="PASS SYSLOG" quit
        . use io close syslog2
        . write out,!

        ; Check setenv and unsetenv
        if 1=setenvtst do
        . set retval=$&gtmposix.setenv("gtmposixtest",dir,0,.errno)
        . set tmp=$ztrnlnm("gtmposixtest") if tmp=dir write "PASS setenv",!
        . else  write "FAIL setenv $ztrnlnm(""gtmposixtest"")=",tmp," should be ",dir,!
        . set retval=$&gtmposix.unsetenv("gtmposixtest",.errno)
        . set tmp=$ztrnlnm("gtmposixtest") if '$length(tmp) write "PASS unsetenv",!
        . else  write "FAIL unsetenv $ztrnlnm(""gtmposixtest"")=",tmp," should be unset",!

        ; Check rmdir
        kill out1,out2
        set retval=$&gtmposix.rmdir(dir,.errno)
        open "statfile":(shell="/bin/sh":command="$gtm_dist/mumps -run %XCMD 'd statfile^%POSIX("""_dir_""",.stat)'":stderr="statfileerr":readonly)::"pipe"
        use "statfile" for i=1:1 read tmp quit:$zeof  set out1(i)=tmp
        use "statfileerr" for i=1:1 read tmp quit:$zeof  set out2(i)=tmp
        use io close "statfile"
	set errmsg="%GTM-E-ZCSTATUSRET, External call returned error status"
	set msg=""
	if ($data(out1)&'$data(out2)) set msg=$get(out1(1))
	else  if ($data(out2)&'$data(out1)) set msg=$get(out2(1))
        if errmsg=msg write "PASS rmdir",!
        else  write "FAIL rmdir",! zwrite:$data(out1) out1 zwrite:$data(out2) out2

        ; Check MKTMPDIR
        set dir="/tmp/posixtest"_$j_"_XXXXXX"
        set retval=$$MKTMPDIR^%POSIX(.dir) write:'retval "FAIL MKTMPDIR retval=",retval,!
        set retval=$$STATFILE^%POSIX(.dir,.stat) write:'retval "FAIL statfile retval=",retval,!
        if stat("ino") write "PASS MKTMPDIR",!
        else  write "FAIL MKTMPDIR stat(ino)=",stat(ino),!
        set retval=$&gtmposix.rmdir(dir,.errno)

        ; Check mkdir
        set dir="/tmp/posixtest"_$j_$$^%RANDSTR(6)
        set retval=$$mkdir^%POSIX(dir,"S_IRWXU") write:'retval "FAIL MKTMPDIR retval=",retval,!
        set retval=$$STATFILE^%POSIX(.dir,.stat) write:'retval "FAIL statfile retval=",retval,!
        if stat("ino") write "PASS mkdir",!
        else  write "FAIL mkdir stat(ino)=",stat(ino),!
        set retval=$&gtmposix.rmdir(dir,.errno)

        ; Check MKDIR
        set dir="/tmp/posixtest"_$j_$$^%RANDSTR(6)
        set retval=$$MKDIR^%POSIX(dir,"S_IRWXU") write:'retval "FAIL MKTMPDIR retval=",retval,!
        set retval=$$STATFILE^%POSIX(.dir,.stat) write:'retval "FAIL statfile retval=",retval,!
        if stat("ino") write "PASS MKDIR",!
        else  write "FAIL MKDIR stat(ino)=",stat(ino),!
        set retval=$&gtmposix.rmdir(dir,.errno)

        ; Check version - timestamp must be earlier than tv
        set tmp=86400*$piece(ddzh,",",1)+$piece(ddzh,",",2)
        if 86400*$piece(ver1,",",1)+$piece(ver1,",",2)<tmp write "PASS version",!
        else  write "FAIL version",!
        if 86400*$piece(ver2,",",1)+$piece(ver2,",",2)<tmp write "PASS VERSION",!
        else  write "FAIL VERSION",!

        ; All done with posix test
       quit
BADOPEN
       use $p
       write "Cannot open "_tname_" for reading.  Check permissions",!
       quit
