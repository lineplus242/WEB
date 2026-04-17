#!/bin/sh
#################################################################################
#
#   Program Name : Security Check for Unix	
#   Description : 이 프로그램은 Unix 시스템 통합 진단 프로그램입니다
#   Author : (주)시큐어원
#-------------------------------------------------------------------------------#
#
# - U_15 파일 및 디렉터리 소유자 설정 (Nouser, Nogroup 파일 존재 유무)
# - U_25 world writable 파일 점검
# - U_33 숨겨진 파일 및 디렉토리 검색 및 제거
#
# - 위 항목의 경우 "find /" 명령이 있으므로 시스템 부하가 예상됨
# - 2017.1.31 위 항목에 대해 필터링을 수행하여 저장하므로 양호함
#################################################################################
LANG=C
export LANG
alias ls=ls

#================================================================================
# 변수 설정 & OS 체크
#================================================================================
OS_STR=`uname -s`
OS_VER=`uname -r`

# 실행 시 조건 확인. 확인 없이 진행하려면 false로 설정
START_CHECK="true"

# OS별 설정 - 차후 반영
case $OS_STR in
	Linux)
		;;
	AIX)
		;;
	HP-UX)
		;;
	SunOS)
		;;
esac

HOST_NAME=`hostname`
DATE_STR=`date +%Y%m%d`

RESULT_FILE=$HOST_NAME".xml"
RESULT_TXT=$HOST_NAME".txt"
REF_FILE=$HOST_NAME"_"$OS_STR"_"$DATE_STR"_REF.txt"
TAR_FILE=$HOST_NAME"_"$OS_STR"_"$DATE_STR".tar"

SOL_VERSION=""
SOL_VER_PART=""
SOL_VER_NOICE=""
R_SVR="true"
NFS_SVR="false"
SMTP_SVR="false"
SNMP_SVR="false"
FTP_SVR="false"
TELNET_SVR="false"
TMP_MSG=""
TMP_RESULT=""
FIND_RUN="true"
Exp=""
Evi=""

#================================================================================
# 환경 설정 파일
#================================================================================
PW_FILE="/etc/passwd"

#AIX
PW_SET_FILE_AIX="/etc/security/user"
SECURE_FILE_AIX=$PW_SET_FILE_AIX

#HP-UX
PW_SET_FILE_HP="/tcb/files/auth/system/default"
SECURE_FILE_HP="/etc/securetty"
PROFILE_FILE="/etc/profile"
TMOUT_FILE=$PROFILE_FILE
SMTP_CF_FILE="/etc/mail/sendmail.cf"
KERNEL_FILE="/etc/init.d/inetinit"
D_KERNEL_FILE="/etc/default/inetinit"
ISSUE_FILE="/etc/issue"
INETD_CONF="/etc/inetd.conf"

#================================================================================
# Notice
#================================================================================
show_notice() {
	echo ""
	echo "#######################################################################"
	echo "#"
	echo "#  Vulnerability analysis for $OS_STR"
	echo "#  Version : 2026"
	echo "#  Copyright @ secureone Co., LTD"
	echo "#"
	echo "#----------------------------------------------------------------------"
	echo "#"
	echo "#  - Host : $HOST_NAME"
	echo "#  - OS : $OS_STR($OS_VER)"
	echo "#  - Date : "`date +%Y-%m-%d-%H:%M:%S`
	echo "#"
	echo "#######################################################################"
    echo ""
	
	if [ $START_CHECK = "true" ]
		then
			echo "Begin to analysis[y/n] : [ENTER = y]"
			read ANSWER
			
			if [ "$ANSWER" = "y" -o "$ANSWER" = "Y" -o "$ANSWER" = "" ]
				then
					echo " "
				else
					echo "*** Terminated by user ***"
					exit 0
			fi
			
			echo "전체 경로 find하는 체크 항목 실행 여부[y/n] : [ENTER = y]"
			echo "   - U_15 파일 및 디렉터리 소유자 설정 (Nouser, Nogroup 파일 존재 유무)"
			echo "   - U_25 world writable 파일 점검"
			echo "   - U_33 숨겨진 파일 및 디렉토리 검색 및 제거"
			
			read ANSWER_FIND
			
			if [ "$ANSWER_FIND" = "y" -o "$ANSWER_FIND" = "Y" -o "$ANSWER_FIND" = "" ]
				then
					FIND_RUN="true"
				else
					FIND_RUN="false"
			fi
			
			unset ANSWER
			unset ANSWER_FIND
	  else
		FIND_RUN="true"
	fi
}

#================================================================================
# File permission check
#================================================================================
perm_num()
{
	unset Pr
	unset Pw
	unset Px
	unset nPr
	unset nPw
	unset nPx
	
	#Pr=${1:0:1}
	#Pw=${1:1:1}
	#Px=${1:2:1}
	Pr=`echo $1 | cut -c1-1`
	Pw=`echo $1 | cut -c2-2`
	Px=`echo $1 | cut -c3-3`
	
	if [ "$Pr" = "r" ]
		then
			nPr=4
		else
			nPr=0
	fi
	
	if [ "$Pw" = "w" ]
		then
			nPw=2
		else
			nPw=0
	fi

	if [ "$Px" = "x" -o "$Px" = "s" -o "$Px" = "t" ]
		then
			nPx=1
		else
			nPx=0
	fi
	
	echo "$nPr+$nPw+$nPx" | bc
}

perm_check() {
	###################################################################
	# oTYPE
	# - : plain file. 일반 파일. 실행 파일도 포함한다.
	# d : directory. 디렉토리 형식.
	# l : link. 다른 파일을 가리키는 링크 파일.
	# p : pipe. 두 개의 프로그램을 연결하는 파이프 파일. 
	# b : block device. 블럭 단위로 하드웨어와 반응하는 파일.
	# c : character device. 스트림 단위로 하드웨어와 반응하는 파일.
	#
	#Permission
	# r = 4
	# w = 2
	# x = 1
	# - = 0
	#
	# SetUID, SetGID, Stikybit설정
	# 기존에 설정하는 퍼미션앞에 숫자를 하나 더 붙여주면 된다.
	# 1 = stikybit
	# 2 = SetGID
	# 4 = SetUID
	#
	# 사용법
	# perm_check [FILE_NAME]
	#
	# 결과값
	# TYPE : $oTYPE
	# SetUID, SetGID, Stikybit : $sPn
	# Owner Permission : $uPn
	# Group Permission : $gPn
	# Other Permission : $oPn
	# Owner Name : $OWNER
	# Group Name : $GROUP
	###################################################################

	unset TARGET
	
	unset TARGET_PROP
	unset PERM
	unset type
	unset sUID
	unset sGID
	unset stBIT
	
	unset oTYPE
	unset uPerm
	unset gPerm
	unset oPerm
	unset sPn
	unset uPn
	unset gPn
	unset oPn
	unset OWNER
	unset GROUP
	
	TARGET="$1"
	
	if [ -f $TARGET ]
		then
			TARGET_PROP=`ls -alL $1`
	elif [ -d $TARGET ]
		then
			TARGET_PROP=`ls -alLd $1`
	fi
	
	PERM=`echo $TARGET_PROP | awk '{print $1}'`

	#type=${PERM:0:1}
	type=`echo $PERM | cut -c1-1`
		
	#uPerm=${PERM:1:3}
	#gPerm=${PERM:4:3}
	#oPerm=${PERM:7:3}
	uPerm=`echo $PERM | cut -c2-4`
	gPerm=`echo $PERM | cut -c5-7`
	oPerm=`echo $PERM | cut -c8-10`

	#sUID=${uPerm:2:1}
	#sGID=${gPerm:2:1}
	#stBIT=${oPerm:2:1}
	sUID=`echo $uPerm | cut -c3-3`
	sGID=`echo $gPerm | cut -c3-3`
	stBIT=`echo $oPerm | cut -c3-3`

	if [ "$sUID" = "s" -o "$sUID" = "S" ]
		then
			sPn="4"
	fi
	if [ "$sGID" = "s" -o "$sGID" = "S" ]
		then
			sPn="2"
	fi
	if [ "$stBIT" = "t" -o "$stBIT" = "T" ]
		then
			sPn="1"
	fi

	case $type in
		-)
			oTYPE="plain file"
		;;
		d)
			oTYPE="directory"
		;;
		l)
			oTYPE="link"
		;;
		p)
			oTYPE="pipe"
		;;
		b)
			oTYPE="block device"
		;;
		c)
			oTYPE="character device"
		;;
	esac

	uPn=`perm_num $uPerm`
	gPn=`perm_num $gPerm`
	oPn=`perm_num $oPerm`

	OWNER=`echo $TARGET_PROP | awk '{print $3}'`
	GROUP=`echo $TARGET_PROP | awk '{print $4}'`
}

#================================================================================
# Solaris version 확인
#================================================================================
sol_ver_check() {
	SOL_VERSION=`uname -r | awk -F. '{print $2}'`
	if [ $OS_STR = "SunOS" ]
	then
		if [ $SOL_VERSION -le "9" ]
		then
			SOL_VER_PART="1"
			SOL_VER_NOICE="Solaris 9 이하"
		elif [ $SOL_VERSION -ge "10" ]
			then
				SOL_VER_PART="2"
				SOL_VER_NOICE="Solaris 10 이상"
		fi
	fi
}

#================================================================================
# 결과 파일 존재 여부 확인
#================================================================================
file_check() {
	CHECK_RESULT_FILE=`ls ./$RESULT_FILE 2>/dev/null | wc -l`
	CHECK_RESULT_TXT=`ls ./$RESULT_TXT 2>/dev/null | wc -l`
	CHECK_REF_FILE=`ls ./$REF_FILE 2>/dev/null | wc -l`
	CHECK_TAR_FILE=`ls ./$TAR_FILE 2>/dev/null | wc -l`
	
    if [ $CHECK_RESULT_FILE -ne 0 -o  $CHECK_RESULT_TXT -ne 0 -o  $CHECK_REF_FILE -ne 0 -o  $CHECK_TAR_FILE -ne 0 ]
		then
			if [ $START_CHECK = "true" ]
				then
					echo "* Result files are exist. Overwrite?[y/n] : [ENTER = y]"
					read ANSWER
					
					if [ "$ANSWER" = "y" -o "$ANSWER" = "Y" -o "$ANSWER" = "" ]
						then
							rm -rf $RESULT_FILE
							rm -rf $RESULT_TXT
							rm -rf $REF_FILE
							rm -rf $TAR_FILE
						else
							echo "*** Terminated by user ***"
							exit 0
					fi
				else
							rm -rf $RESULT_FILE
							rm -rf $RESULT_TXT
							rm -rf $REF_FILE
							rm -rf $TAR_FILE
			fi
	fi
	
    echo ""
	echo "Start the diagnosis..."
	echo ""
	
	unset CHECK_RESULT_FILE
	unset CHECK_RESULT_TXT
	unset CHECK_REF_FILE
	unset CHECK_TAR_FILE
	unset ANSWER
}

#================================================================================
# Apache 사용 확인
#================================================================================
APACHE_check(){

	if [ `ps -ef | grep httpd | grep -v "grep" | wc -l` -ne 0 ]
		then
			if [ `ps -ef | grep httpd | grep -v "grep" | grep "apachectl" | wc -l` -eq 0 ]
				then
					ps -ef | grep httpd | grep -v "grep" | awk '{ print $8 }' | grep httpd >> httpd_tmp.txt
					ps -ef | grep httpd | grep -v "grep" | awk '{ print $9 }' | grep httpd >> httpd_tmp.txt					
				else
					ps -ef | grep httpd | grep -v "grep" | awk '{ print $8 }' | grep httpd | grep -v apachectl >> httpd_tmp.txt
					ps -ef | grep httpd | grep -v "grep" | awk '{ print $9 }' | grep httpd | grep -v apachectl >> httpd_tmp.txt
					
					ps -ef | grep httpd | grep -v "grep" | awk ' { print $10 }' | grep conf >> httpd_conf_tmp.txt
					ps -ef | grep httpd | grep -v "grep" | awk ' { print $11 }' | grep conf >> httpd_conf_tmp.txt
			fi
			
			HTTP_SVR="true"
		else
			HTTP_SVR="false"
	fi
	
	if [ $HTTP_SVR = "true" ]
		then
			if [ -s httpd_conf_tmp.txt ]
				then
					cat httpd_conf_tmp.txt >> httpdconf_tmp.txt
			fi
			if [ -s httpd_tmp.txt ]
				then
					for httpconf in `cat httpd_tmp.txt`
					do
						if [ $OS_STR = "SunOS" ]
							then
								CONF_PATH=`$httpconf -V | egrep "(SERVER\_CONFIG\_FILE)" | awk -F'"' '{print $2}'`
								echo "$CONF_PATH" >> httpdconf_tmp.txt
							else
								WEB_BASE=`$httpconf -V | egrep "(HTTPD\_ROOT)" | awk -F'["]' '{ print $2 }'`
								CONF_PATH=$WEB_BASE"/"`$httpconf -V | egrep "(SERVER\_CONFIG\_FILE)" | awk -F'["]' '{print $2}'`
								echo "$CONF_PATH" >> httpdconf_tmp.txt
						fi
					done
			fi

			cat httpdconf_tmp.txt | sort -u > httpdconf.txt
			cat httpdconf.txt > tmp_httpd.txt
			echo "" >> tmp_httpd.txt
			echo "" >> tmp_httpd.txt
			for httpconf in `cat httpdconf.txt`
			do
				echo "[[ $httpconf 설정파일 ]]" >> tmp_httpd.txt
				cat $httpconf >> tmp_httpd.txt
				echo "================================================================================" >> tmp_httpd.txt
				echo "" >> tmp_httpd.txt
			done
			
			rm -rf httpd_tmp.txt
			rm -rf httpd_conf_tmp.txt
			rm -rf httpdconf_tmp.txt
			rm -rf httpdconf.txt
	fi
	
#	if [ `ps -ef | grep httpd | grep -v "grep" | wc -l` -eq 0 ]
#		then
#			HTTP_SVR="false"
#		else
#			HTTP_SVR="true"
#			echo "Apache Checking..........."
#			find / -name "httpd.conf" > path_httpd 
#			cat `cat path_httpd` >> tmp_httpd.txt
#			echo "Apache Check complete!"
#	fi
}

#================================================================================
# FTP 사용 확인
#================================================================================
FTP_check() {
	case $OS_STR in
		AIX | HP-UX)
		# AIX HP-UX:
			if [ `cat /etc/inetd.conf | grep "ftp" | grep -v "tftp" | grep -v "^#" | wc -l` -eq 0 -a `ps -ef | grep ftp | grep -v "grep" | grep -v "sftp" | wc -l` -eq 0 ]
				then
					#프로세스 동작 안함
					FTP_SVR="false"
				else
					#프로세스 동작 중
					FTP_SVR="true"
					FTP_CHK=`cat /etc/inetd.conf | grep "ftp" | grep -v "tftp"`
			fi
		;;
		
		Linux)
		#Linux
			if [ `chkconfig --list | grep ftp | grep -i on | wc -l` -eq 0 -a `ps -ef | grep ftp | grep -v "grep" | grep -v "ssh" | wc -l` -eq 0 ]
				then
					#프로세스 동작 안함
					FTP_SVR="false"
				else
					#프로세스 동작 중
					FTP_SVR="true"
					FTP_CHK=`chkconfig --list | grep ftp | grep -i on`
			fi
			
			if [ `systemctl list-unit-files --type=service | grep ftp | grep -i enabled | wc -l` -eq 0 -a `ps -ef | grep ftp | grep -v "grep" | grep -v "ssh" | wc -l` -eq 0 ]
				then
					#프로세스 동작 안함
					FTP_SVR="false"
				else
					#프로세스 동작 중
					FTP_SVR="true"
					FTP_CHK=`systemctl list-unit-files --type=service | grep ftp | grep -i enabled`
			fi
		;;
		
		SunOS)
		#SunOS:
			if [ $SOL_VER_PART = "1" ]
				then
					if [ -f /etc/inetd.conf ]
					then
						FTP_RESULT=`cat /etc/inetd.conf | grep -v "^ *#" | grep "ftp"`
						FTP_CHK=`cat /etc/inetd.conf | grep "ftp"`
					fi
				else
					FTP_RESULT=`inetadm | grep ftp | grep enabled | grep -v tftp`
					FTP_CHK=`inetadm | grep ftp | grep -v tftp`
			fi
			
			CHK_VALUE_1=`echo $FTP_RESULT | egrep -vc "^$"`
			FTP_PS_RESULT=`ps -ef | grep ftp | egrep -v "grep|sftp"`
			CHK_VALUE_2=`echo $FTP_PS_RESULT | egrep -vc "^$"`
			
			if [ $CHK_VALUE_2 -eq 0 -a $CHK_VALUE_1 -eq 0 ]
				then
					#프로세스 동작 안함
					FTP_SVR="false"
				else
					#프로세스 동작 중
					FTP_SVR="true"
			fi
			
	#		unset FTP_RESULT
			unset CHK_VALUE_1
			unset CHK_VALUE_2
	#		unset FTP_PS_RESULT
		;;
		
		*)
		#
		;;
	esac
}

#================================================================================
# Telnet 사용 확인
#================================================================================
TELNET_check() {	
	TELNET_SERVICE="disabled"
	
	case $OS_STR in
		AIX | HP-UX)
		#Linux AIX HP-UX:
			if [ `cat /etc/inetd.conf | grep "telnet" | grep -v "^#" | wc -l` -eq 0 ]
				then
					#프로세스 동작 안함
					TELNET_SVR="false"
				else
					#프로세스 동작 중
					TELNET_SVR="true"
					
			fi
			
			TELNET_SERVICE=`cat /etc/inetd.conf | grep "telnet"`
		;;
		
		#Linux:
		Linux)
			if [ `cat /etc/xinetd.d/telnet 2>/dev/null | grep disable | grep yes | wc -l` -eq 0 ]
				then
					#프로세스 동작 안함
					TELNET_SVR="false"
				else
					#프로세스 동작 중
					TELNET_SVR="true"
					TELNET_SERVICE=`cat /etc/xinetd.d/telnet | grep disable`
			fi
		;;
		
		SunOS)
		#SunOS:
			if [ $SOL_VER_PART = "1" ]
				then
					if [ -f /etc/inetd.conf ]
					then
						TELNET_RESULT=`cat /etc/inetd.conf | grep -v "^ *#" | grep "telnetd"`
						TELNET_SERVICE=`cat /etc/inetd.conf | grep "telnetd"`
					fi
				else
					TELNET_RESULT=`inetadm | grep telnet | grep enabled`
					TELNET_SERVICE=`inetadm | grep telnet`
			fi
			
			CHK_VALUE_1=`echo $TELNET_RESULT | egrep -vc "^$"`
			TELNET_PS_RESULT=`ps -ef | grep telnetd | grep -v "grep"`
			CHK_VALUE_2=`echo $TELNET_PS_RESULT | egrep -vc "^$"`
			
			if [ $CHK_VALUE_2 -eq 0 -a $CHK_VALUE_1 -eq 0 ]
				then
					#프로세스 동작 안함
					TELNET_SVR="false"
				else
					#프로세스 동작 중
					TELNET_SVR="true"
			fi
			
			unset TELNET_RESULT
			unset CHK_VALUE_1
			unset CHK_VALUE_2
			unset TELNET_PS_RESULT
		;;
		
		*)
		#
		;;
	esac
}

#================================================================================
# Solaris TCP Wrapper 사용 여부 확인
#================================================================================
TCPWrapper_check() {
		if [ $SOL_VER_PART = "1" ]
			then
				CHK=`cat /etc/inetd.conf | grep $1`
				ONLINE_CHECK=`echo "$CHK" | grep -v "^ *#"`
			else
				CHK=`inetadm | grep $1`
				ONLINE_CHECK=`echo "$CHK" | grep enabled`
		fi
		CHK_VALUE=`echo "$ONLINE_CHECK" | egrep -vc "^$"`
		
		if [ $CHK_VALUE -gt 0 ]
			then
				TMP_MSG=`inetadm -l $1 | grep "tcp_wrappers"`
				CHK_RESULT=`echo $TMP_MSG | awk 'BEGIN {FS="="}{print $2}'`
				if [ "$CHK_RESULT" = "TRUE" ]
					then
						TMP_STR="사용하고"
						TMP_RESULT=1
					else
						TMP_STR="사용하지 않고"
						TMP_RESULT=0
				fi
				TMP_MSG="$1:\nTCP-Wrapper를 $TMP_STR 있음\n$TMP_MSG"
			else
				TMP_MSG="$1:\n서비스를 사용하지 않고 있음\n"
				TMP_RESULT=1
		fi
	  return
}

#================================================================================
# xml 시작
#================================================================================
xml_start() {
	echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> $RESULT_FILE 2>&1
	echo "<CVCResult>" >> $RESULT_FILE 2>&1
	echo "	<matchingCODE>CVCM-SULX-001</matchingCODE>" >> $RESULT_FILE 2>&1
	echo "	<ResultData>" >> $RESULT_FILE 2>&1
}

#================================================================================
# Item 노드 생성
#================================================================================
Item_head(){
	echo "[$1] $2"
	printf "    Checking"
	
	echo "		<Item>" >> $RESULT_FILE 2>&1
	echo "			<iCode>$1</iCode>" >> $RESULT_FILE 2>&1
	echo "			<iTitle>$2</iTitle>" >> $RESULT_FILE 2>&1
	echo "			<InspectionCode>CVCI-0111</InspectionCode>" >> $RESULT_FILE 2>&1
	printf "......."
	
	echo " " >> $RESULT_TXT 2>&1
	echo " " >> $RESULT_TXT 2>&1
	echo "######################################################################" >> $RESULT_TXT 2>&1
	echo " " >> $RESULT_TXT 2>&1
	echo "[$1] $2" >> $RESULT_TXT 2>&1
#	echo " " >> $RESULT_TXT 2>&1
	printf "......."
	
#	if [ $Item_No -eq 17 -o $Item_No -eq 26 -o $Item_No -eq 35 -o $Item_No -eq 48 -o $Item_No -eq 51 -o $Item_No -eq 52 ]
#		then
			echo " " >> $REF_FILE 2>&1
			echo "######################################################################" >> $REF_FILE 2>&1
			echo "[$1] $2" >> $REF_FILE 2>&1
			echo " " >> $REF_FILE 2>&1
			printf "......."
#	fi
	
	
	Item_No=`expr $Item_No + 1`
}

Item_foot() {
	echo "			<Result>$1</Result>" >> $RESULT_FILE 2>&1
	echo "			<Evidence>" >> $RESULT_FILE 2>&1
	echo "<![CDATA[" >> $RESULT_FILE 2>&1

	echo "<RESULT>$1" >> $RESULT_TXT 2>&1
	
	printf "$2" >> $RESULT_FILE 2>&1
	printf "$2" >> $RESULT_TXT 2>&1
	printf "......."
	
	if [ "$3" != "" ]
		then
			printf "\n$3\n" >> $RESULT_FILE 2>&1
			printf "\n$3\n" >> $RESULT_TXT 2>&1
	fi
	printf "......."

	echo "]]>" >> $RESULT_FILE 2>&1
	echo "			</Evidence>" >> $RESULT_FILE 2>&1
	echo "		</Item>" >> $RESULT_FILE 2>&1
	
	echo "<END>" >> $RESULT_TXT 2>&1
	
	printf "done\n"
}

# 현재 사용 안 함
REF_body(){
	echo "[$1]" >> $REF_FILE 2>&1
	echo "$2" >> $REF_FILE 2>&1
	echo "---------" >> $REF_FILE 2>&1
	echo " " >> $REF_FILE 2>&1
}

#================================================================================
# 시간 표시
#================================================================================
run_time() {
    echo "		<LastTime>" >> $RESULT_FILE 2>&1
	echo "			<![CDATA[" >> $RESULT_FILE 2>&1
	echo "------------------------------------------------[TIME] `date +%Y-%m-%d` `date +%X`" >> $RESULT_FILE 2>&1
	echo "			]]>" >> $RESULT_FILE 2>&1
	echo "		</LastTime>" >> $RESULT_FILE 2>&1
}

#================================================================================
# 진단 스크립트 시작
#================================================================================
# root 계정 원격 접속 제한
U_01_remote_root() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="root 계정 원격 접속 제한"
	Item_head "U-01" "$iTitle" "$iCODE"
	
	SSH_SVR="false"
	TELNET_CHK="true"
	case $OS_STR in
	Linux)
	#Linux: root 계정 원격 접속 제한
		if [ -f /etc/pam.d/remote ]
			then
				pam_file="/etc/pam.d/remote"
		elif [ -f /etc/pam.d/login ]
			then
				pam_file="/etc/pam.d/login"
		fi
		
		if [ $TELNET_SVR = "false" ]
			then
				Result="양호"
				Exp="TELNET 서비스가 비실행중이고,"
				Evi=""
			else
				if [ `cat $pam_file | grep "pam_securetty.so" | grep -v "^#" | wc -l` -eq 0 ]
					then
						Result="취약"
						Exp="$pam_file에 pam_securetty.so 설정이 없음,"
						Evi=`cat $pam_file | grep "pam_securetty.so"`
						
						TELNET_CHK="false"
					else
						if [ -f /etc/securetty ]
							then
								if [ `cat /etc/securetty | grep -i "^pts" | grep -v "^#" | wc -l` -eq 0 ] 
									then
										Result="양호"
										Exp="TELNET의 root 계정 원격 접속 제한 설정이 되어 있고,(pts 설정 없음)"
										Evi=`cat $pam_file | grep "pam_securetty.so"`
									else
										Result="취약"
										Exp="TELNET의 root 계정 원격 접속이 허용되어 있고,"
										Evi=`cat /etc/securetty | grep -i "^pts" | grep -v "^#"`
										
										TELNET_CHK="false"
								fi
							else
								Result="취약"
								Exp="/etc/securetty 파일이 존재하지 않고"
								Evi=""
								
								TELNET_CHK="false"
						fi
				fi
		fi

		if [ -f /etc/securetty ]
			then
				#REF_body "/etc/securetty 내용" "`cat /etc/securetty`"
				echo "# /etc/securetty 내용" >> $RESULT_TXT 2>&1
				cat /etc/securetty >> $RESULT_TXT 2>&1
		fi
		
		#REF_body "$pam_file 내용" "`cat $pam_file`"
		echo " " >> $RESULT_TXT 2>&1
		echo "# $pam_file" >> $RESULT_TXT 2>&1
		cat $pam_file >> $RESULT_TXT 2>&1
	;;
	
	SunOS)
	#SunOS: root 계정 원격 접속 제한
		if [ $TELNET_SVR = "false" ]
			then
				Result="양호"
				Exp="TELNET 서비스가 비실행중이고,"
				Evi=""
			else
				if [ -f /etc/default/login ]
					then
						if [ `cat /etc/default/login | grep -i "^console=" | grep -v "^#" | wc -l` -eq 1 ] 
							then
								Result="양호"
								Exp="TELNET의 root 계정 원격 접속 제한 설정이 되어 있고,"
								Evi=`cat /etc/default/login | grep -i "^console="`
							
							else
								Result="취약"
								Exp="TELNET의 root 계정 원격 접속 제한 설정이 되어 있지 않고,"
								Evi=`cat /etc/default/login | grep -i "console="`
						
								TELNET_CHK="false"
						fi
					else
						Result="수동점검"
						Exp="/etc/default/login 파일이 존재하지 않고,"
						Evi=""
			
						TELNET_CHK="false"
				fi
		
				if [ -f /etc/default/login ]
					then
						echo "#cat /etc/default/login" >> $REF_FILE 2>&1
						cat /etc/default/login >> $REF_FILE 2>&1
				fi
		fi
	;;
	
	AIX)
	#AIX: root 계정 원격 접속 제한
		if [ $TELNET_SVR = "false" ]
			then
				Result="양호"
				Exp="TELNET 서비스가 비실행중이고,"
				Evi=""
			else
				if [ `lsuser -a rlogin root | grep "false" | wc -l` -eq 1 ] 
					then
						Result="양호"
						Exp="TELNET의 root 계정 원격 접속 제한 설정이 되어 있고,"
						Evi=`lsuser -a rlogin root`
					else
						Result="취약"
						Exp="TELNET의 root 계정 원격 접속 제한 설정이 되어 있지 않고,"
						Evi=`lsuser -a rlogin root`
				
						TELNET_CHK="false"
				fi
	
				echo "#lsuser -a rlogin root" >> $RESULT_TXT 2>&1
				lsuser -a rlogin root >> $RESULT_TXT 2>&1
		fi
	;;
	
	HP-UX)
	#HP-UX: root 계정 원격 접속 제한
		if [ $TELNET_SVR = "false" ]
			then
				Result="양호"
				Exp="TELNET 서비스가 비실행중이고,"
				Evi=""
			else
				if [ -f /etc/securetty ]
					then
						if [ `cat /etc/securetty | grep -i "^console" | grep -v "^#" | wc -l` -eq 1 ] 
							then
								Result="양호"
								Exp="TELNET의 root 계정 원격 접속 제한 설정이 되어 있고,"
								Evi=`cat /etc/securetty | grep -i "^console"`
							else
								Result="취약"
								Exp="TELNET의 root 계정 원격 접속 제한 설정이 되어 있지 않고,"
								Evi=`cat /etc/securetty | grep -i "console="`
						
								TELNET_CHK="false"
						fi
					else
						Result="수동점검"
						Exp="/etc/securetty 파일이 존재하지 않고,"
						Evi=""
				
						TELNET_CHK="false"
				fi
		
				if [ -f /etc/securetty ]
					then
						echo "#cat /etc/securetty" >> $REF_FILE 2>&1
						echo " " >> $REF_FILE 2>&1
						cat /etc/securetty >> $REF_FILE 2>&1
				fi
		fi
	;;
	
	*)
	;;
	esac

	if [ `ps -ef | grep ssh | grep -v "grep" | wc -l` -ne 0 ]
		then
			if [ -f /etc/ssh/sshd_config ]
				then
					SSH_CONFIG=/etc/ssh/sshd_config
				elif [ -f /opt/ssh/newconfig/opt/ssh/etc/sshd_config ]
					then
						SSH_CONFIG=/opt/ssh/newconfig/opt/ssh/etc/sshd_config
				elif [ -f /etc/opt/ssh/sshd_config ]
					then
						SSH_CONFIG=/etc/opt/ssh/sshd_config
			fi
			
			
			if [ -f $SSH_CONFIG ]
				then
					if [ `cat $SSH_CONFIG | grep -i "PermitRootLogin" | egrep -v "setting|without" | grep -v "^#" | grep "no" | wc -l` -eq 1 ]
						then
							if [ $TELNET_CHK = "false" ]
								then
									Result="취약"
									Exp="$Exp SSH의 root 원격 접속을 제한하고 있으므로 취약함"
								else
									Result="양호"
									Exp="$Exp SSH의 root 원격 접속을 제한하고 있으므로 양호함"
							fi
						else
							if [ $TELNET_CHK = "false" ]
								then
									Exp="$Exp SSH의 root 원격 접속을 제한하지 않으므로 취약함"
								else
									Result="취약"
									Exp="$Exp SSH의 root 원격 접속을 제한하지 않으므로 취약함"
							fi
					fi
					echo "" >> $RESULT_TXT 2>&1
					echo "[ssh 프로세스 구동여부확인]" 	 >> $RESULT_TXT 2>&1	
					ps -ef | egrep sshd | egrep -v "grep" >> $RESULT_TXT 2>&1
					echo " " >> $RESULT_TXT 2>&1
	
					echo "#SSH root 원격접속 차단여부 $SSH_CONFIG 확인">> $RESULT_TXT 2>&1
					cat $SSH_CONFIG | grep -i "PermitRootLogin" | grep -v "setting">> $RESULT_TXT 2>&1
					echo " " >> $RESULT_TXT 2>&1
				else
					Result="수동점검"
					Exp="$Exp sshd_config 파일이 존재하지 않으므로 수동점검"
			fi

			
		else
		if [ $TELNET_CHK = "false" ]
			then
				Exp="$Exp SSH가 비실행되고 있으므로 취약함"
			else
				Result="양호"
				Exp="$Exp SSH가 비실행되고 있으므로 양호함"
		fi

	fi
	
	echo " " >> $RESULT_TXT 2>&1
	echo "[#TELNET_SERVICE 상태] " >> $RESULT_TXT 2>&1
	echo "$TELNET_SERVICE" >> $RESULT_TXT 2>&1
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"

}

# 비밀번호 관리정책 설정
U_02_password_complex() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="비밀번호 관리정책 설정"
	Item_head "U-02" "$iTitle" "$iCODE"
	
	Result="수동점검"
	Exp="비밀번호 관리정책 설정 파일을 확인하여 수동점검(REF 파일 참조)"
	Evi=""

	case $OS_STR in
	Linux)
	#Linux: 
		if [ -f /etc/login.defs ]
			then
				echo "1) /etc/login.defs 파일 내 비밀번호 최소/최대 사용기간 설정 확인" >> $REF_FILE 2>&1
				echo "※PASS_MAX_DAYS: 비밀번호 최대 사용 기간(90일 이상), PASS_MIN_DAYS: 비밀번호 최소 사용 기간(1일 이상)" >> $REF_FILE 2>&1
				cat /etc/login.defs |grep -E "PASS_MAX_DAYS|PASS_MIN_DAYS" | grep -v 'number' >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
		fi
		
		if [ -f /etc/security/pwquality.conf ]
			then
				echo "2) /etc/security/pwquality.conf 파일 내 비밀번호 관리 정책 설정 확인" >> $REF_FILE 2>&1
				echo "※minlen: 최소 비밀번호 길이, dcredit: 최소 숫자 n개 이상 요구, ucredit: 최소 대문자 n개 이상 요구" >> $REF_FILE 2>&1
				echo "※lcredit: : 최소 소문자 n개 이상 요구, ocredit: 최소 특수문자 n개 이상 요구, enforce_for_root: root를 포함한 모든 사용자에게 비밀번호 관리 정책 강제" >> $REF_FILE 2>&1
				cat /etc/security/pwquality.conf | grep -E "minlen|dcredit|ucredit|lcredit|ocredit|enforce_for_root" >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
		fi
		
		if [ -f /etc/security/pwhistory.conf ]
			then
				echo "3) /etc/security/pwhistory.conf 파일 내 비밀번호 관리 정책 설정 확인" >> $REF_FILE 2>&1
				echo "※enforce_for_root: root를 포함한 모든 사용자에게 비밀번호 관리 정책 강제" >> $REF_FILE 2>&1
				echo "※remember: 최근 비밀번호 n개 이상 기억, file = /etc/security/opasswd 주석 해제 필요" >> $REF_FILE 2>&1
				cat /etc/security/pwhistory.conf | grep -E "enforce_for_root|remember =|file = /etc/security/opasswd" >> $REF_FILE 2>&1
		fi
	;;
	
	SunOS)
	#SunOS: 
		if [ -f /etc/default/passwd ]
			then
				echo "/etc/default/passwd 파일 내 비밀번호 관리 정책 설정 확인" >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
				cat /etc/default/passwd >> $REF_FILE 2>&1
		fi
	;;
	
	AIX)
	#AIX: 
		if [ -f /etc/security/user ]
			then
				echo "/etc/security/user 파일 내 비밀번호 관리 정책 설정 확인" >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
				cat /etc/security/user | grep -v "*" >> $REF_FILE 2>&1
		fi
	;;
	
	HP-UX)
	#HP-UX: 
		if [ -f /etc/default/security ]
			then
				echo "/etc/default/security 파일 내 비밀번호 관리 정책 설정 확인" >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
				cat /etc/default/security >> $REF_FILE 2>&1
		fi
	;;
	
	*)
	#
	;;
	
	esac
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 계정 잠금 임계값 설정
U_03_account_lock() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="계정 잠금 임계값 설정"
	Item_head "U-03" "$iTitle" "$iCODE"
	
	
	case $OS_STR in
	Linux)
	#Linux:
		echo " " >> $RESULT_TXT 2>&1
		echo "※red-hat 계열 6.0 미만 system-auth 설정 확인, 6.0 이상 password-auth 설정 확인, 8.0 이상 authselect 설정 확인" >> $RESULT_TXT 2>&1
		echo "※x86(32비트)는 pam_tally.so 모듈, x86_64(64비트)는 pam_tally2.so 모듈 설정확인" >> $RESULT_TXT 2>&1
		echo " " >> $RESULT_TXT 2>&1
		
		echo "#Linux release 확인" >> $RESULT_TXT 2>&1
		cat /etc/*-release | grep release | sort -u  >> $RESULT_TXT 2>&1
		echo "#시스템 아키텍처 확인" >> $RESULT_TXT 2>&1
		uname -m  >> $RESULT_TXT 2>&1
		echo " " >> $RESULT_TXT 2>&1
		
		Result="수동점검"
		Exp="리눅스 배포판, 릴리즈, 아키텍처 확인 후 해당하는 설정 파일을 확인하여 수동점검(REF 파일 참조)"
						
		if [ -f /etc/pam.d/system-auth ]
			then
				echo "#cat /etc/pam.d/system-auth (Redhat 계열)" >> $RESULT_TXT 2>&1
				grep "pam_tally" /etc/pam.d/system-auth  >> $RESULT_TXT 2>&1
				echo " " >> $RESULT_TXT 2>&1
				Evi=""			
			else
				echo "/etc/pam.d/system-auth 파일이 존재하지 않음" >> $RESULT_TXT 2>&1
				Evi=""
		fi
		
		if [ -f /etc/pam.d/password-auth ]
			then
				echo "#cat /etc/pam.d/password-auth (Redhat 계열)" >> $RESULT_TXT 2>&1
				grep "pam_tally" /etc/pam.d/password-auth  >> $RESULT_TXT 2>&1
				echo " " >> $RESULT_TXT 2>&1
				Evi=""
			else
				echo "/etc/pam.d/password-auth 파일이 존재하지 않음" >> $RESULT_TXT 2>&1
				Evi=""
		fi
		
		if [ -f /etc/security/faillock.conf ]
			then
				echo "#cat /etc/security/faillock.conf (Redhat 계열)" >> $RESULT_TXT 2>&1
				grep -E "silent|deny|unlock_time" /etc/security/faillock.conf  >> $RESULT_TXT 2>&1
				echo " " >> $RESULT_TXT 2>&1
				Evi=""
			else
				echo "/etc/security/faillock.conf 파일이 존재하지 않음" >> $RESULT_TXT 2>&1
				Evi=""
		fi
		
		echo "#Linux release 확인" >> $REF_FILE 2>&1
		cat /etc/*-release >> $REF_FILE 2>&1
		echo "====================================================================================" >> $REF_FILE 2>&1
		echo " " >> $REF_FILE 2>&1
		echo "#system-auth 확인 " >> $REF_FILE 2>&1
		echo "#cat /etc/pam.d/system-auth (Redhat 계열)" >> $REF_FILE 2>&1
		cat /etc/pam.d/system-auth  | grep -v "#"  >> $REF_FILE 2>&1
		echo "====================================================================================" >> $REF_FILE 2>&1
		echo " " >> $REF_FILE 2>&1
		echo "#password-auth 설정파일 확인" >> $REF_FILE 2>&1
		echo "#cat /etc/pam.d/password-auth (Redhat 계열)" >> $REF_FILE 2>&1
		cat /etc/pam.d/password-auth | grep -v "#"  >> $REF_FILE 2>&1
		echo "====================================================================================" >> $REF_FILE 2>&1
		echo " " >> $REF_FILE 2>&1
		echo "#faillock.conf 설정파일 확인" >> $REF_FILE 2>&1
		echo "#cat /etc/security/faillock.conf (Redhat 계열)" >> $REF_FILE 2>&1
		cat /etc/security/faillock.conf | grep -v "#"  >> $REF_FILE 2>&1
		echo "====================================================================================" >> $REF_FILE 2>&1
		
		# Devian 계열
		if [ -f /etc/pam.d/common-auth ]
		then
			echo " " >> $REF_FILE 2>&1
			echo "#cat /etc/pam.d/common-auth (일반))" >> $REF_FILE 2>&1
			cat /etc/pam.d/common-auth  | grep -v "#"  >> $REF_FILE 2>&1
			echo "====================================================================================" >> $REF_FILE 2>&1
		fi
		echo " " >> $REF_FILE 2>&1
		echo "#telnet 임계값 설정파일 확인" >> $REF_FILE 2>&1
		echo "#cat /etc/pam.d/remote" >> $REF_FILE 2>&1
		cat /etc/pam.d/remote  | grep -v "#" >> $REF_FILE 2>&1
		echo "====================================================================================" >> $REF_FILE 2>&1
		echo " " >> $REF_FILE 2>&1
		echo "#ssh 임계값 설정파일 확인" >> $REF_FILE 2>&1 
		echo "#cat /etc/pamd.d/sshd" >> $REF_FILE 2>&1
		cat /etc/pam.d/sshd  | grep -v "#"  >> $REF_FILE 2>&1
		echo "====================================================================================" >> $REF_FILE 2>&1		
		
	;;
	
	SunOS)
	#SunOS: 
		if [ -f /etc/default/login ]
			then
				if [ `grep RETRIES= /etc/default/login | grep -v "^#" | wc -l` -eq 0 ]
					then
						Result="취약"
						Exp="RETRIES가 설정되어 있지 않으므로 취약함"
						Evi=`grep RETRIES= /etc/default/login`
						if [ $SOL_VER_PART = "2" ]
							then
								cat "" >> $RESULT_TXT 2>&1
								echo "/etc/security/policy.conf파일 LOCK_AFTER_RETRIES 설정확인" >> $RESULT_TXT 2>&1
								cat /etc/security/policy.conf | grep "LOCK\_AFTER\_RETRIES=" >> $RESULT_TXT 2>&1
						fi
					else
						if [ `grep RETRIES= /etc/default/login | awk -F= '($2) < 10 || ($2) == 10 { print $2 }' | wc -l` -eq 0 ]
							then
								Result="취약"
								Exp="계정 잠금 임계값이 10 초과의 값으로 설정되어 있으므로 취약함"
								Evi=`grep RETRIES= /etc/default/login`
								
								if [ $SOL_VER_PART = "2" ]
									then
										echo "" >> $RESULT_TXT 2>&1
										echo "#/etc/security/policy.conf파일 LOCK_AFTER_RETRIES 설정확인" >> $RESULT_TXT 2>&1
										cat /etc/security/policy.conf | grep "LOCK\_AFTER\_RETRIES=" >> $RESULT_TXT 2>&1
								fi
							else								
								if [ $SOL_VER_PART = "2" ]
									then
										if [ `cat /etc/security/policy.conf | grep "LOCK\_AFTER\_RETRIES=" | grep -v "^#" | grep -i "YES" | wc -l` -eq 1 ]
											then
												Result="양호"
												Exp="계정 잠금 임계값이 10 이하의 값으로 설정되어 있고, LOCK_AFTER_RETRIES 값도 YES로 설정되어 있으므로 양호함"
											else
												Result="취약"
												Exp="계정 잠금 임계값이 10 이하의 값으로 설정되어 있으나, LOCK_AFTER_RETRIES 값도 YES로 설정되어 있지 않으므로 취약함"
										fi
												Evi="`grep RETRIES= /etc/default/login`
												
#/etc/security/policy.conf 파일의 LOCK_AFTER_RETRIES 설정확인
`cat /etc/security/policy.conf | grep 'LOCK\_AFTER\_RETRIES='`"
								fi
						fi
				fi
			else
				Result="수동점검"
				Exp="/etc/default/login 파일이 존재하지 않음"
				Evi=""
		fi
		
		if [ -f /etc/default/login ]
			then
				echo "#cat /etc/default/login" >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
				cat /etc/default/login >> $REF_FILE 2>&1
		fi
		
		if [ -f /etc/security/policy.conf ]
			then
				echo "#cat /etc/security/policy.conf" >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
				cat /etc/security/policy.conf >> $REF_FILE 2>&1
		fi
	;;
	
	AIX)
	#AIX: 
		lsuser -a loginretries ALL >> a.txt
		
		if [ -f a.txt ]
			then
				if [ `cat a.txt | awk -F"=" '($2) > 10 || ($2) == 0 { print $2 }' | wc -l` -ne 0 ]
					then
						Result="취약"
						Exp="계정 잠금 임계값이 설정되어 있지 않거나 10 초과의 값으로 설정되어 있으므로 취약함"
						Evi=""
					else
						Result="양호"
						Exp="계정 잠금 임계값이 10 이하의 값으로 설정되어 있으므로 양호함"
						Evi=""
				fi
		fi		
		rm -rf a.txt
		
		echo "#lsuser -a loginretries ALL" >> $RESULT_TXT 2>&1
		lsuser -a loginretries ALL >> $RESULT_TXT 2>&1
		echo " " >> $RESULT_TXT 2>&1
	;;
	
	HP-UX)
	#HP-UX: 
		if [ `grep -i maxtries= /etc/default/security | grep -v "^#" | wc -l` -eq 0 ]
			then
				Result="취약"
				Exp="계정 잠금 임계값이 설정되어 있지 않으므로 취약함"
				Evi=`grep -i maxtries= /etc/default/security`
			else
				if [ `grep -i maxtries= /etc/default/security | awk -F= '($2) < 10 || ($2) == 10 { print $2 }' | wc -l` -eq 0 ]
					then
						Result="취약"
						Exp="계정 잠금 임계값이 10 초과의 값으로 설정되어 있으므로 취약함"
						Evi=`grep maxtries= /etc/default/security`
					else
						Result="양호"
						Exp="계정 잠금 임계값이 10 이하의 값으로 설정되어 있으므로 양호함"
						Evi=`grep -i maxtries= /etc/default/security`
				fi
		fi
		
		if [ -f /etc/default/security ]
			then
				echo "#cat /etc/default/security" >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
				cat /etc/default/security >> $REF_FILE 2>&1
		fi
		
		if [ -f /tcb/files/auth/system/default ]
			then
				echo "#cat /tcb/files/auth/system/default" >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
				cat /tcb/files/auth/system/default >> $REF_FILE 2>&1
		fi
	;;
	
	*)
	#
	;;
	
	esac
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 비밀번호 파일 보호
U_04_shadow() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="비밀번호 파일 보호"
	Item_head "U-04" "$iTitle" "$iCODE"
	
	case $OS_STR in
	Linux | SunOS)
	#Linux, SunOS: 
		if [ -f /etc/shadow ]
			then 
				if [ `ls -alL /etc/shadow | grep "...-------.*[root or bin].*" | wc -l` -eq 1 ]
					then
						Result="양호"
						Exp="shadow 파일을 사용하고 있으므로 양호함"
						Evi=`ls -alL /etc/shadow`
					else
						Result="취약"
						Exp="shadow 파일을 사용하고 있지 않으므로 취약함"
						Evi=`ls -alL /etc/shadow`
				fi
			else
				Result="취약"
				Exp="shadow 파일이 존재하지 않으므로 취약함"
				Evi=""
		fi
		
		if [ -f /etc/passwd ]
			then
				echo "#cat /etc/passwd" >> $REF_FILE 2>&1
				cat /etc/passwd >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
		fi
		
		if [ -f /etc/shadow ]
			then
				echo "#cat /etc/shadow" >> $REF_FILE 2>&1
				cat /etc/shadow >> $REF_FILE 2>&1
		fi
	;;
	
	AIX)
	#AIX: 
		if [ -f /etc/security/passwd ]
			then 
				if [ `ls -alL /etc/security/passwd | grep "...-------.*[root or bin].*" | wc -l` -eq 1 ]
					then
						Result="양호"
						Exp="/etc/security/passwd 파일을 사용하고 있으므로 양호함"
						Evi=`ls -alL /etc/security/passwd`
					else
						Result="취약"
						Exp="/etc/security/passwd 파일을 사용하고 있지 않으므로 취약함"
						Evi=`ls -alL /etc/security/passwd`
				fi
			else
				Result="취약"
				Exp="/etc/security/passwd 파일이 존재하지 않으므로 취약함"
				Evi=""
		fi
		
		if [ -f /etc/passwd ]
			then
				echo "#cat /etc/passwd" >> $REF_FILE 2>&1
				cat /etc/passwd >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
		fi
		
		if [ -f /etc/security/passwd  ]
			then
				echo "#cat /etc/security/passwd " >> $REF_FILE 2>&1
				cat /etc/security/passwd  >> $REF_FILE 2>&1
		fi
	;;
	
	HP-UX)
	#HP-UX: 
		Result="수동점검"
		Exp="$REF_FILE 및 passwd 파일참고 /etc/passwd 파일에 패스워드 저장할 경우 취약"
		Evi=""

		if [ -f /etc/passwd ]
			then
				echo "#cat /etc/passwd" >> $RESULT_TXT 2>&1
				cat /etc/passwd >> $RESULT_TXT 2>&1
				echo " " >> $RESULT_TXT 2>&1
				echo "#cat /etc/passwd" >> $REF_FILE 2>&1
				cat /etc/passwd >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
		fi
		
		if [ -f /etc/shadow ]
			then
				echo "#cat /etc/shadow" >> $RESULT_TXT 2>&1
				cat /etc/shadow >> $RESULT_TXT 2>&1
				echo "#cat /etc/shadow" >> $REF_FILE 2>&1
				cat /etc/shadow >> $REF_FILE 2>&1
		fi
	;;
	
	*)
	#
	;;
		
	esac
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# root 이외의 UID가 '0' 금지
U_05_root_uid() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="root 이외의 UID가 '0' 금지"
	Item_head "U-05" "$iTitle" "$iCODE"
	
	case $OS_STR in
	Linux | SunOS | AIX | HP-UX)
	#Linux, SunOS: 
		if [ `awk -F: '$3==0 { print $1 " -> UID=" $3 "  GID=" $4 }' /etc/passwd | wc -l` -eq 1 ] 
			then
				Result="양호"
				Exp="root 이외의 UID가 '0'인 계정이 존재하지 않으므로 양호함"
				Evi=`awk -F: '$3==0 { print $1 " -> UID=" $3 "  GID=" $4 }' /etc/passwd`
			else
				Result="취약"
				Exp="root 이외의 UID가 '0'인 계정이 존재하므로 취약함"
				Evi=`awk -F: '$3==0 { print $1 " -> UID=" $3 "  GID=" $4 }' /etc/passwd`
		fi
		
		if [ -f /etc/passwd ]
			then
				echo "#cat /etc/passwd" >> $REF_FILE 2>&1
				cat /etc/passwd >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
		fi
	;;
	
	*)
	#
	;;
	
	esac
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 사용자 계정 su 기능 제한
U_06_su_restrict() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="사용자 계정 su 기능 제한"
	Item_head "U-06" "$iTitle" "$iCODE"
	
	case $OS_STR in
		Linux)
		#Linux:
			if [ -f /bin/su ]
				then					
					perm_check /bin/su
					
					if [ $sPn -eq 4 -a $gPn -eq 5 -a $oPn -eq 0 -a $OWNER = "root" -a $GROUP = "root" ]
						then
							Exp_tmp="/bin/su 파일의 권한 정상(4x50, 소유자 root, 그룹 root)"
						else
							Exp_tmp="/bin/su 파일의 권한 확인 필요(4x50, 소유자 root, 그룹 root 아님)"
					fi
					
					if [ `cat /etc/pam.d/su | grep pam_wheel.so | grep -v "^#" | wc -l` -eq 0 ]
						then
							if [ `ls -al /bin/su | grep ".r...-.---.*root.*" | wc -l` -eq 1  ]
								then
									Result="양호"
									Exp="/bin/su 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
									SUGROUPTMP=`ls -al /bin/su | awk '{ print $4 }'`
									Evi=`ls -al /bin/su; echo ""; echo [bin/su 파일 소유 그룹 계정 확인]; cat /etc/group | grep $SUGROUPTMP`
								else
									SUGROUPTMP=`ls -al /bin/su | awk '{ print $4 }'`
									Result="취약"
									Exp="/bin/su 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
									Evi="/bin/su 파일이 $SUGROUPTMP 그룹으로 설정되어 있음"
							fi
						elif [ `cat /etc/pam.d/su | grep pam_wheel.so | grep -v "^#" | grep "use_uid" | wc -l` -eq 1 ]
							then
								echo " " >> $RESULT_TXT 2>&1
								echo "※x86(32비트)는 /lib 디렉터리 하위 모듈, x86_64(64비트)는 /lib64 디렉터리 하위 모듈 설정확인" >> $RESULT_TXT 2>&1
								echo " " >> $RESULT_TXT 2>&1
		
								echo "#Linux release 확인" >> $RESULT_TXT 2>&1
								cat /etc/*-release | grep release | sort -u  >> $RESULT_TXT 2>&1
								echo "#시스템 아키텍처 확인" >> $RESULT_TXT 2>&1
								uname -m  >> $RESULT_TXT 2>&1
								echo " " >> $RESULT_TXT 2>&1
		
								echo "※ pam.d/su에 pam_wheel.so로 su 사용을 제한할 경우 'use_uid' 라인만 설정" >> $RESULT_TXT 2>&1
								echo "※ 다음라인에 debug group=wheel 설정 시 취약, use_uid 라인에 추가시엔 양호" >> $RESULT_TXT 2>&1
								echo "※ auth requited는 use_uid를 포함하는 라인 '하나만' 설정" >> $RESULT_TXT 2>&1
								echo " " >> $RESULT_TXT 2>&1
								if [ `cat /etc/pam.d/su | grep pam_wheel.so | grep -v "^#" | grep  -v "use_uid" | grep debug | wc -l` -eq 0 ]
									then
										Result="양호"
										Exp="/etc/pam.d/su에 pam_wheel.so 설정이 있으므로 양호함. wheel 그룹에 적절한 사용자가 포함되어 있는지 확인 필요. $Exp_tmp"
										Evi=`cat /etc/pam.d/su | grep pam_wheel.so; echo " "; cat /etc/group | grep wheel; echo " "; ls -al /bin/su`
									else
										Result="취약"
										Exp="/etc/pam.d/su pam_wheel.so 설정에 debug group=wheel 설정 불필요"
										Evi=`cat /etc/pam.d/su | grep pam_wheel.so; echo " "; cat /etc/group | grep wheel; echo " "; ls -al /bin/su`
								fi
						else
							Result="취약"
							Exp="/bin/su 파일의 접근권한이 설정되어 있지 않으므로 취약함"
							Evi=""
							
							echo "1) 파일권한 설정" >> $RESULT_TXT 2>&1
							ls -al /bin/su >> $RESULT_TXT 2>&1
							echo "2) /etc/pam.d/su 설정" >> $RESULT_TXT 2>&1
							cat /etc/pam.d/su | grep pam_wheel.so >> $RESULT_TXT 2>&1
						
					fi
				else
					Result="양호"
					Exp="/bin/su 파일이 존재하지 않음"
					Evi=""
			fi

			if [ -f /etc/pam.d/su ]
				then
					echo "#cat /etc/pam.d/su" >> $REF_FILE 2>&1
					cat /etc/pam.d/su >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/group ]
				then
					echo "#cat /etc/group" >> $REF_FILE 2>&1
					cat /etc/group >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
			
		unset SUGROUPTMP
		;;
		
		SunOS)
		#SunOS: 
			if [ -f /usr/bin/su ]
				then
					perm_check /usr/bin/su
					
					if [ $sPn -eq 4 -a $gPn -eq 5 -a $oPn -eq 0 -a $OWNER = "root" ]
						then
							Result="양호"
							Exp="/usr/bin/su 파일의 접근권한이 적절하게 설정되어 있으므로 양호함(4x50, 소유자 root). 그룹에 적절한 사용자가 포함되어 있는지 확인 필요."
							Evi=`ls -al /usr/bin/su; echo " "; cat /etc/group | grep $GROUP`
						else
							Result="취약"
							Exp="/usr/bin/su 파일의 접근권한이 적절하게 설정되지 않으므로 취약함(4x50, 소유자 root 아님). 그룹에 적절한 사용자가 포함되어 있는지 확인 필요."
							Evi=`ls -al /usr/bin/su; echo " "; cat /etc/group | grep $GROUP`
					fi
				else
					Result="양호"
					Exp="/usr/bin/su 파일이 존재하지 않으므로 양호함"
					Evi=""
			fi
			
			if [ -f /etc/pam.d/su ]
				then
					echo "#cat /etc/pam.d/su" >> $REF_FILE 2>&1
					cat /etc/pam.d/su >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
				
			if [ -f /etc/group ]
				then
					echo "#cat /etc/group" >> $REF_FILE 2>&1
					cat /etc/group >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
		;;
		
		AIX)
		#AIX: 
			if [ `ls -al /bin/su | wc -l` -eq 0 ]
				then
					Result="양호"
					Exp="/bin/su 파일이 존재하지 않으므로 양호함"
					Evi=""
				else
					if [ `ls -al /bin/su | grep ".r...-.---.*[root or bin].*" | wc -l` -eq 1  ]
						then
							Result="양호"
							Exp="/bin/su 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
							Evi=`ls -al /bin/su`
						else
							SUGROUPTMP=`ls -al /bin/su | awk '{ print $4 }'`
							Result="취약"
							Exp="/bin/su 파일의 접근권한이 과도하게 설정되어 있으므로 취약함
/bin/su 파일이 $SUGROUPTMP 그룹으로 설정되어 있음"
							
							Evi=`ls -al /bin/su`
					fi
			fi
			
			echo "#lsuser -a sugroups root" >> $RESULT_TXT 2>&1
			lsuser -a sugroups root >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
		;;
		
		HP-UX)
		#HP-UX: 
			if [ `ls -al /bin/su | wc -l` -eq 0 ]
				then
					Result="양호"
					Exp="/bin/su 파일이 존재하지 않으므로 양호함"
					Evi=""
				else
					if [ `ls -al /bin/su | grep ".r...-.---.*root.*" | wc -l` -eq 1  ]
						then
							Result="양호"
							Exp="/bin/su 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
							Evi=`ls -al /bin/su`
						else
							SUGROUPTMP=`ls -al /bin/su | awk '{ print $4 }'`
							Result="취약"
							Exp="/bin/su 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
							Evi="/bin/su 파일이 $SUGROUPTMP 그룹으로 설정되어 있음"
					fi
			fi
				
			if [ -f /bin/su ]
				then
					echo "#ls -al /bin/su" >> $RESULT_TXT 2>&1
					ls -al /bin/su >> $RESULT_TXT 2>&1
				else
					if [ `ls -al /bin/su | awk '{ print $4 }'` = wheel ]
						then
							echo "/bin/su 파일의 그룹이 wheel로 설정되어 있음" >> $RESULT_TXT 2>&1
							echo " " >> $RESULT_TXT 2>&1
							ls -al /bin/su >> $RESULT_TXT 2>&1
						else
							echo "/bin/su 파일의 그룹이 wheel로 설정있지 않음" >> $RESULT_TXT 2>&1
							echo " " >> $RESULT_TXT 2>&1
							SUGROUPTMP=`ls -al /bin/su | awk '{ print $4 }'`
							echo "/bin/su 파일이 $SUGROUPTMP 그룹으로 설정되어 있음" >> $RESULT_TXT 2>&1
					fi
			fi
			if [ -f /etc/default/security ]
				then
					echo "#cat /etc/default/security" >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
					cat /etc/default/security >> $REF_FILE 2>&1
			fi
		;;
		
		*)
		#
		;;
		
	esac
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
	
	unset Exp_tmp
}

# 불필요한 계정 제거 - 확인 필요
U_07_disused_account() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="불필요한 계정 제거"
	Item_head "U-07" "$iTitle" "$iCODE"
	
	Result="수동점검"
	Exp="/etc/passwd 내용을 참고하여 인터뷰 실시. 불필요한 계정이 존재하지 않으면 양호"
	Evi=""

	if [ -f /etc/passwd ]
		then
			echo "#cat /etc/passwd" >> $RESULT_TXT 2>&1
			cat /etc/passwd >> $RESULT_TXT 2>&1
	fi
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 관리자 그룹에 최소한의 계정 포함
U_08_root_group() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="관리자 그룹에 최소한의 계정 포함"
	Item_head "U-08" "$iTitle" "$iCODE"
	
	Result="수동점검"
	Exp="관리자 그룹에 불필요한 계정이 등록되어 있는 경우 취약"
	
	case $OS_STR in
		Linux | SunOS | HP-UX)
			Evi=`cat /etc/group | grep "^root"`
			;;
		AIX)
			Evi=`cat /etc/group | grep "^system"`
			;;
	esac
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 계정이 존재하지 않는 GID 금지
U_09_gid_not_account() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="계정이 존재하지 않는 GID 금지"
	Item_head "U-09" "$iTitle" "$iCODE"

	ACCOUNT=`cat /etc/group | awk -F: '$4!="" { print $1":"$4}'`
	NOT_EXIST=0

	for acc in $ACCOUNT
	do
		GROUP_NAME=`echo $acc | awk -F: '{print $1}'`
		CHECK_ACC=`echo $acc | awk -F: '{print $2}' | sed "s/,/ /g"`
		
		RESULT=$RESULT"Group : $GROUP_NAME\n"
		
		for check in $CHECK_ACC
		do
			RESULT=$RESULT"     $check"
			
			if [ `cat /etc/passwd | grep "^$check" | wc -l` -eq 0 ]
				then
					RESULT=$RESULT"[ not exist ]"
					NOT_EXIST=1
			fi
			RESULT=$RESULT"\n"
		done
	done

	if [ $NOT_EXIST -eq 0 ]
		then
			Result="양호"
			Exp="구성원이 없는 그룹(그룹에 계정이 설정되어 있으나 실제로 계정이 없음)이 없으므로 양호함"
			Evi=`echo "$RESULT"`
		else
			Result="취약"
			Exp="구성원이 없는 그룹(그룹에 계정이 설정되어 있으나 실제로 계정이 없음)이 존재하므로 취약함"
			Evi=`echo "$RESULT"`
	fi

	if [ -f /etc/group ]
		then
			echo "#cat /etc/group" >> $REF_FILE 2>&1
			cat /etc/group >> $REF_FILE 2>&1
			echo " " >> $REF_FILE 2>&1
	fi
	
	if [ -f /etc/passwd ]
		then
			echo "#cat /etc/passwd" >> $REF_FILE 2>&1
			cat /etc/passwd >> $REF_FILE 2>&1
	fi
	
	if [ -f /etc/gshadow ]
		then
			echo "#cat /etc/gshadow" >> $REF_FILE 2>&1
			cat /etc/gshadow >> $REF_FILE 2>&1
	fi

	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 동일한 UID 금지
U_10_same_uid() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="동일한 UID 금지"
	Item_head "U-10" "$iTitle" "$iCODE"
	
	Evi=`awk -F: '{print $1 " = " $3}' /etc/passwd`
	
	if [ `awk -F: '{print $1}' /etc/passwd | sort -u | wc -l` -eq `awk -F: '{print $3}' /etc/passwd | sort -u | wc -l` ]
		then
			Result="양호"
			Exp="동일한 UID로 설정된 사용자 계정이 존재하지 않으므로 양호함"
		else
			Result="취약"
			Exp="동일한 UID로 설정된 사용자 계정이 존재하므로 취약함"
	fi
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 사용자 Shell 점검
U_11_user_shell() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="사용자 Shell 점검"
	Item_head "U-11" "$iTitle" "$iCODE"
	GREPWORD=""
	
	case $OS_STR in
		Linux)
		#Linux
			GREPWORD="^bin|^adm|^daemon|^shutdown|^sync|^halt|^operator|^nobody|^nobody4|^gopher|^listen|^noaccess|^diag|^games"
		;;
		
		SunOS)
		#SunOS:
			GREPWORD="^bin|^adm|^daemon|^shutdown|^sync|^halt|^mail|^news|^operator|^nobody|^nobody4|^gopher|^ntp"
		;;
		
		AIX)
		#AIX:
			GREPWORD="^bin|^adm|^daemon|^shutdown|^sync|^halt|^operator|^nobody|^nobody4|^gopher|^listen|^noaccess|^diag|^games"
		;;
			
		HP-UX)
		#HP-UX:
			GREPWORD="^bin|^adm|^daemon|^shutdown|^sync|^halt|^operator|^nobody|^nobody4|^gopher|^listen|^noaccess|^diag|^games|^lp|^lpd|^smmsp|^webservd"
		;;
		
		*)
		#
		;;
		
	esac
	
	if [ `cat /etc/passwd | egrep $GREPWORD | grep -v "admin" |  awk -F: '{print $7}'| egrep -v "false|nologin|null|halt|sync|shutdown" | wc -l` -eq 0 ]
		then
			Result="양호"
			Exp="/bin/false or /sbin/nologin or noshell로 설정되어 있으므로 양호함"
			Evi=`cat /etc/passwd | egrep $GREPWORD | grep -v "admin"`
		else
			Result="취약"
			Exp="/bin/false or /sbin/nologin or noshell로 설정되어 있지 않으므로 취약함"
			Evi=`cat /etc/passwd | egrep $GREPWORD | grep -v "admin"`
	fi
	
	if [ -f /etc/passwd ]
		then
			echo "#cat /etc/passwd" >> $REF_FILE 2>&1
			cat /etc/passwd >> $REF_FILE 2>&1
	fi
	case $OS_STR in
	SunOS)
	#SunOS: 		
		if [ -f /etc/shadow ]
			then
				echo "#cat /etc/shadow" >> $REF_FILE 2>&1
				cat /etc/shadow >> $REF_FILE 2>&1
		fi
	;;
	*)
	#
	;;
		
	esac
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
	
	unset GREPWORD
}

# 세션 종료 시간 설정
U_12_session_timeout() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="세션 종료 시간 설정"
	Item_head "U-12" "$iTitle" "$iCODE"
	
	case $OS_STR in
		Linux)
			if [ -f /etc/profile ]
				then
					grep -i "TMOUT" /etc/profile | grep -v "^#" | awk -F"=" '{ print $2 }' > u15_tmp
					
					if [ `cat u15_tmp` ]
						then
							STIMEOUT=`cat u15_tmp`
							if [ $STIMEOUT -gt 600 ]
								then
									Result="취약"
									Exp="TIMEOUT설정이 600이상으로 설정되어 있으므로 취약함"
									Evi=`grep -i "TMOUT" /etc/profile`
								else
									Result="양호"
									Exp="TIMEOUT설정이 600이하로 설정되어 있으므로 양호함"
									Evi=`grep -i "TMOUT" /etc/profile`
							fi
						else
							Result="취약"
							Exp="TIMEOUT설정이 적용되어 있지 않으므로 취약함"
							Evi=""
					fi
				else
					Result="수동점검"
					Exp="/etc/profile 파일이 존재하지 않음"
					Evi=""
			fi
			
			rm -rf u15_tmp
			
			if [ -f /etc/profile ]
			then
				echo "#cat /etc/profile" >> $REF_FILE 2>&1
				cat /etc/profile >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/csh.login ]
			then
				echo "#cat /etc/csh.login" >> $REF_FILE 2>&1
				cat /etc/csh.login >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/csh.cshrc ]
			then
				echo "#cat /etc/csh.cshrc" >> $REF_FILE 2>&1
				cat /etc/csh.cshrc >> $REF_FILE 2>&1
			fi
			

			echo " " >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
		;;
		
		SunOS)
		#SunOS:
			if [ -f /etc/profile ]
				then
					grep -i "TMOUT" /etc/profile | grep -v "^#" | awk -F"=" '{ print $2 }' > u15_tmp
					
					if [ `cat u15_tmp` ]
						then
							STIMEOUT=`cat u15_tmp`
							if [ $STIMEOUT -gt 600 ]
								then
									Result="취약"
									Exp="TIMEOUT설정이 600이상으로 설정되어 있으므로 취약함"
									Evi=`grep -i "TMOUT" /etc/profile`
								else
									Result="양호"
									Exp="TIMEOUT설정이 600이하로 설정되어 있으므로 양호함"
									Evi=`grep -i "TMOUT" /etc/profile`
							fi
						else
							Result="취약"
							Exp="TIMEOUT설정이 적용되어 있지 않으므로 취약함"
							Evi=""
					fi
				else
					Result="수동점검"
					Exp="/etc/profile 파일이 존재하지 않음"
					Evi=""
			fi
			
			rm -rf u15_tmp
			
			if [ -f /etc/profile ]
			then
				echo "#cat /etc/profile" >> $REF_FILE 2>&1
				cat /etc/profile >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/csh.login ]
			then
				echo "#cat /etc/csh.login" >> $REF_FILE 2>&1
				cat /etc/csh.login >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/csh.cshrc ]
			then
				echo "#cat /etc/csh.cshrc" >> $REF_FILE 2>&1
				cat /etc/csh.cshrc >> $REF_FILE 2>&1
			fi
			

			echo " " >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
		;;
		
		AIX)
		#AIX:
			grep -i "TMOUT" /etc/profile | grep -v "^#" | awk -F"=" '{ print $2 }' > u15_tmp
			
			if [ `cat u15_tmp` ]
				then
					STIMEOUT=`cat u15_tmp`
					if [ $STIMEOUT -gt 600 ]
						then
							Result="취약"
							Exp="TIMEOUT설정이 과도하게 설정되어 있으므로 취약함"
							Evi=`grep -i "TMOUT" /etc/profile`
						else
							Result="양호"
							Exp="TIMEOUT설정이 적절하게 설정되어 있으므로 양호함"
							Evi=`grep -i "TMOUT" /etc/profile`
					fi
				else
					Result="취약"
					Exp="TIMEOUT설정이 적용되어 있지 않으므로 취약함"
					Evi=`grep -i "TMOUT" /etc/profile`
			fi
			rm -rf u15_tmp
			
			if [ -f /etc/profile ]
				then
					echo "#cat /etc/profile" >> $REF_FILE 2>&1
					cat /etc/profile >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/csh.login ]
				then
					echo "#cat /etc/csh.login" >> $REF_FILE 2>&1
					cat /etc/csh.login >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/csh.cshrc ]
				then
					echo "#cat /etc/csh.cshrc" >> $REF_FILE 2>&1
					cat /etc/csh.cshrc >> $REF_FILE 2>&1
			fi

			echo " " >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
		;;
			
		HP-UX)
		#HP-UX:
			NO_PW_SET_FILE=1
			NO_TMOUT_FILE=1
			if [ -f $PW_SET_FILE_HP ]
				then
					CHK=`cat $PW_SET_FILE_HP | grep -i "t_login_timeout=" | grep -v "^ *#"`
					CHK_VALUE=`echo $CHK | awk 'BEGIN {FS="="}{print $2}'`
				else
					NO_PW_SET_FILE=0
			fi

			
			if [ -f $TMOUT_FILE ]
				then
					CHK=`cat $TMOUT_FILE | grep -i "TMOUT=" | grep -v "^ *#"`
					CHK_VALUE=`echo $CHK | awk 'BEGIN {FS="="}{print $2}'`
				else
					NO_TMOUT_FILE=0
			fi
			
			if [ $NO_PW_SET_FILE -eq 0 -a $NO_TMOUT_FILE -eq 0 ]
				then
					Result="취약"
					Exp="$PW_SET_FILE_HP 과 $TMOUT_FILE 파일이 모두 존재하지 않으므로 취약함"
					Evi=""
				else
					if [ "$CHK_VALUE" != "" ]
						then
							if [ "$CHK_VALUE" -lt "900" ]
								then
									Result="양호"
									Exp="TIMEOUT 값이 적절하게 설정되어 있으므로 양호함"
									Evi="$CHK"
								else
									Result="취약"
									Exp="TIMEOUT 값이 과도하게 설정되어 있으므로 취약함"
									Evi="$CHK"
							fi
						else
							Result="취약"
							Exp="TIMEOUT 설정이 존재하지 않으므로 취약함"
							Evi=""
					fi
			fi
			
			if [ -f /etc/profile ]
				then
					echo "#cat /etc/profile" >> $REF_FILE 2>&1
					cat /etc/profile >> $REF_FILE 2>&1
			fi
			
			if [ -f /tcb/files/auth/system/default ]
				then
					echo "#cat /tcb/files/auth/system/default" >> $REF_FILE 2>&1
					cat /tcb/files/auth/system/default >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/csh.login ]
				then
					echo "#cat /etc/csh.login" >> $REF_FILE 2>&1
					cat /etc/csh.login >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/csh.cshrc ]
				then
					echo "#cat /etc/csh.cshrc" >> $REF_FILE 2>&1
					cat /etc/csh.cshrc >> $REF_FILE 2>&1
			fi
			

			echo " " >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
			
			unset RESULT
			unset CHK_VALUE
		;;
		
		*)
		#
		;;
		
	esac
}

# 안전한 비밀번호 암호화 알고리즘 사용
U_13_password_encrypt() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="안전한 비밀번호 암호화 알고리즘 사용"
	Item_head "U-13" "$iTitle" "$iCODE"
	
	Result="수동점검"
	Exp="$REF_FILE 참고하여 수동진단"
	Evi=""

	case $OS_STR in
	Linux)
	#Linux: 
		if [ -f /etc/shadow ]
			then
				echo "Linux: /etc/shadow 파일 내 암호화 필드 값 확인 및 /etc/login.defs 파일의 ENCRYPT_METHOD 값이 SHA512(256)이면 양호함" >> $REF_FILE 2>&1
				echo "cat /etc/shadow" >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
				cat /etc/shadow >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
		fi
		
		if [ -f /etc/login.defs ]
			then
				echo "cat /etc/login.defs" >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
				cat /etc/login.defs | grep 'ENCRYPT_METHOD' | grep -v '#' >> $REF_FILE 2>&1
		fi
	;;
	
	SunOS)
	#SunOS: 
		if [ -f /etc/passwd ]
			then
				echo "SunOS: /etc/passwd 파일 내 비밀번호 암호화 알고리즘 확인 및 /etc/security/policy.conf 파일의 CRYPT_DEFAULT 값이 5 또는 6이면 양호함" >> $REF_FILE 2>&1
				echo "cat /etc/passwd" >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
				cat /etc/passwd >> $REF_FILE 2>&1
		fi
		
		if [ -f /etc/security/policy.conf ]
			then
				echo "cat /etc/security/policy.conf" >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
				cat /etc/security/policy.conf >> $REF_FILE 2>&1
		fi
	;;
	
	AIX)
	#AIX: 
		if [ -f /etc/security/passwd ]
			then
				echo "AIX: /etc/security/passwd 파일 내 비밀번호 암호화 알고리즘 확인(password = {암호화 알고리즘 ssha256 또는 512}<해시값>)" >> $REF_FILE 2>&1
				echo "cat /etc/security/passwd" >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
				cat /etc/security/passwd >> $REF_FILE 2>&1
		fi
	;;
	
	HP-UX)
	#HP-UX: 
		echo "HP-UX: /etc/passwd 파일 내 비밀번호 암호화 알고리즘 확인 및 /etc/default/security 파일의 CRYPT_DEFAULT 값이 5 또는 6이면 양호함" >> $REF_FILE 2>&1
		echo "1) $PW_FILE 파일 내용" >> $REF_FILE 2>&1
		
		if [ -f $PW_FILE ]
			then
				cat $PW_FILE >> $REF_FILE 2>&1
			else
				echo "$PW_FILE 파일이 존재하지 않음" >> $REF_FILE 2>&1
		fi
		
		echo " " >> $REF_FILE 2>&1
		echo "2) /etc/default/security 파일 내용" >> $REF_FILE 2>&1
		
		if [ -f /etc/default/security ]
			then
				cat /etc/default/security >> $REF_FILE 2>&1
			else
				echo "/etc/default/security 파일이 존재하지 않음" >> $REF_FILE 2>&1
		fi		
	;;
	
	*)
	#
	;;
	
	esac
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# root 홈, 패스 디렉터리 권한 및 패스 설정 - 보완
U_14_root_path() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="root 홈, 패스 디렉터리 권한 및 패스 설정"
	Item_head "U-14" "$iTitle" "$iCODE"
	
	echo $PATH > path_tmp
	if [ `cat path_tmp | grep "\.:" | wc -l` -eq 0 ]
		then
			Result="양호"
			Exp="PATH 설정에 '.'이 맨 앞이나 중간에 포함되어 있지 않으므로 양호함"
			Evi=`cat path_tmp`
		else
			Result="취약"
			Exp="PATH 설정에 '.'이 맨 앞이나 중간에 포함되어 있으므로 취약함"
			Evi=`cat path_tmp`
	fi
	rm -rf path_tmp
	
	echo "#echo \$PATH" >> $REF_FILE 2>&1
	echo $PATH  >> $REF_FILE 2>&1
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 파일 및 디렉터리 소유자 설정
U_15_nouser_nogroup() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="파일 및 디렉터리 소유자 설정"
	Item_head "U-15" "$iTitle" "$iCODE"
	
	if [ $FIND_RUN = "true" ]
		then
			Result="수동점검"
			Exp="$REF_FILE 참고하여 인터뷰 실시"
			Evi=""

			case $OS_STR in
				Linux)
				#Linux:
					echo "#find / -nouser -print 2> /dev/null " >> $REF_FILE 2>&1
					find / -nouser -print 2> /dev/null >> $REF_FILE 2>&1
					echo "=============================================================================" >> $REF_FILE 2>&1
					echo "#find / -nogroup -print 2> /dev/null " >> $REF_FILE 2>&1
					find / -nogroup -print 2> /dev/null >> $REF_FILE 2>&1
				;;
				
				SunOS | AIX)
				#SunOS AIX:
					echo "#find / -nouser -o -nogroup -xdev -ls 2> /dev/null" >> $REF_FILE 2>&1
					find / -nouser -o -nogroup -xdev -ls 2> /dev/null >> $REF_FILE 2>&1
				;;
				
				HP-UX)
				#HP-UX:
					echo "#find / \( -nouser -o -nogroup \) -xdev -exec ls -al {} \; 2> /dev/null " >> $REF_FILE 2>&1
					find / \( -nouser -o -nogroup \) -xdev -exec ls -al {} \; 2> /dev/null >> $REF_FILE 2>&1
				;;
				*)
				;;
			esac
		else
			Result="수동점검"
			Exp="FIND 실행 안함으로 수동진단 필요"
			Evi=""
			
			echo "FIND 실행 안함으로 수동진단 필요" >> $REF_FILE 2>&1
	fi
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# /etc/passwd 파일 소유자 및 권한 설정
U_16_passwd_permission() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="/etc/passwd 파일 소유자 및 권한 설정"
	Item_head "U-16" "$iTitle" "$iCODE"
	
	if [ `ls -alL /etc/passwd | grep "...-.--.--.*[root or bin].*" | wc -l` -eq 1 ]
		then
			Result="양호"
			Exp="/etc/passwd 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
			Evi=`ls -alL /etc/passwd`
		else
			Result="취약"
			Exp="/etc/passwd 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
			Evi=`ls -alL /etc/passwd`
	fi
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

U_17_start_script_permission() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="시스템 시작 스크립트 권한 설정"
	Item_head "U-17" "$iTitle" "$iCODE"
	
	Result="수동점검"
	Exp="시스템 시작 스크립트에 일반 사용자 쓰기 권한이 제거된 경우 양호함(REF 파일 참조)"
	Evi=""

	case $OS_STR in
	Linux)
	#Linux: 
		echo "1) init 시작 스크립트 파일 권한 확인" >> $REF_FILE 2>&1
		ls -al `readlink -f /etc/rc.d/*/* | sed 's/$/*/'` >> $REF_FILE 2>&1
		echo " " >> $REF_FILE 2>&1
		echo "2) systemd 시작 스크립트 파일 권한 확인" >> $REF_FILE 2>&1
		ls -al `readlink -f /etc/systemd/system/* | sed 's/$/*/'` | grep -vE "drwx|lrwx" >> $REF_FILE 2>&1
	;;
	
	SunOS)
	#SunOS: 
		echo "시작 스크립트 파일 권한 확인" >> $REF_FILE 2>&1
		ls -al `readlink -f /etc/rc*.d/ | sed 's/$/*/'` >> $REF_FILE 2>&1
	;;
	
	AIX)
	#AIX: 
		echo "시작 스크립트 파일 권한 확인" >> $REF_FILE 2>&1
		ls -al /etc/inittab >> $REF_FILE 2>&1
		ls -al /etc/rc.* | grep -v "drwx">> $REF_FILE 2>&1
		ls -al /etc/rc.d/init.d/* >> $REF_FILE 2>&1
		ls -al /etc/rc.d/rc2.d/S* >> $REF_FILE 2>&1
	;;
	
	HP-UX)
	#HP-UX: 
		echo "시작 스크립트 파일 권한 확인" >> $REF_FILE 2>&1
		find /sbin/rc*.d/ -type l -exec ls -l {} + >> $REF_FILE 2>&1
	;;
	
	*)
	#
	;;
	
	esac
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# /etc/shadow 파일 소유자 및 권한 설정
U_18_shadow_permission() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="/etc/shadow 파일 소유자 및 권한 설정"
	Item_head "U-18" "$iTitle" "$iCODE"
	
	case $OS_STR in
		Linux | SunOS)
		#Linux, SunOS:
			if [ `ls -alL /etc/shadow | grep "..--------.*[root or bin].*" | wc -l` -eq 1 ]
				then
					Result="양호"
					Exp="/etc/shadow 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
					Evi=`ls -alL /etc/shadow`
				else
					Result="취약"
					Exp="/etc/shadow 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
					Evi=`ls -alL /etc/shadow`
			fi
			
			echo " " >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
		;;
				
		AIX)
		#AIX:
			if [ `ls -alL /etc/security/passwd | grep "..--------.*[root or bin].*" | wc -l` -eq 1 ]
				then
					Result="양호"
					Exp="/etc/security/passwd 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
					Evi=`ls -alL /etc/security/passwd`
				else
					Result="취약"
					Exp="/etc/security/passwd 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
					Evi=`ls -alL /etc/security/passwd`
			fi
			
			echo " " >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
		;;
			
		HP-UX)
		#HP-UX:
			if [ -f /etc/shadow ]
				then
					if [ `ls -alL /etc/shadow | grep "..--------.*[root or bin].*" | wc -l` -eq 1 ]
						then
							Result="양호"
							Exp="/etc/shadow 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
							Evi=`ls -alL /etc/shadow`
						else
							Result="취약"
							Exp="/etc/shadow 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
							Evi=`ls -alL /etc/shadow`
					fi
				else
					
					Result="수동점검"
					Exp="REF파일에서 패스워드 저장여부를 확인, passwd파일에 패스워드를 저장할 경우 취약하고, 저장하지 않을 경우 REF파일에서 tcb 디렉토리에 저장하는지 확인"
					Evi=`ls -alL /etc/passwd`
					
			fi
				
			if [ -f /etc/passwd ]
				then
					echo "#ls -al /etc/passwd" >> $RESULT_TXT 2>&1
					ls -al /etc/passwd >> $RESULT_TXT 2>&1
					cat /etc/passwd >> $RESULT_TXT 2>&1
			fi
			
			if [ -f /etc/shadow ]
				then
					echo "#ls -al /etc/shadow" >> $RESULT_TXT 2>&1
					ls -al /etc/shadow >> $RESULT_TXT 2>&1
			fi
			
			echo "1) /tcb/files/auth/*/* 파일 내용" >> $RESULT_TXT 2>&1
			
			if [ -d tcb/files/auth ]
				then
					find /tcb/files/auth/ -type f -exec ls -ldb {} \; >> $RESULT_TXT 2>&1
					find /tcb/files/auth/ -type f -exec cat {} \; -exec echo "" \; -exec echo "" \; >> $RESULT_TXT 2>&1
				else
					echo "/tcb/files/auth/ 디렉토리가 존재하지 않음" >> $RESULT_TXT 2>&1
			fi
			

			echo " " >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
		;;
		
		*)
		#
		;;
		
	esac	
}

# /etc/hosts 파일 소유자 및 권한 설정
U_19_hosts_permission() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="/etc/hosts 파일 소유자 및 권한 설정"
	Item_head "U-19" "$iTitle" "$iCODE"
	
	if [ -f /etc/hosts ] 
			then
				if [ `ls -alL /etc/hosts | egrep -c "...-.--.--.*(root|bin).*"` -eq 1 ]
					then
						Result="양호"
						Exp="/etc/hosts 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
						Evi=`ls -alL /etc/hosts`
					else
						Result="취약"
						Exp="/etc/hosts 파일의 접근권한이 과도하게 설정되어 있으므로 취약함(운영환경에 따른 판단 필요)"
						Evi=`ls -alL /etc/hosts`
				fi
			else
			
				Exp="/etc/hosts 파일 사용여부 확인 후 양호, 취약 판단"
				Evi=""
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# /etc/(x)inetd.conf 파일 소유자 및 권한 설정
U_20_xindetd_permission() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="/etc/(x)inetd.conf 파일 소유자 및 권한 설정"
	Item_head "U-20" "$iTitle" "$iCODE"
	
	if [ -f /etc/inetd.conf ]
		then 
			if [ `ls -alL /etc/inetd.conf | grep "...-------.*[root or bin].*" | wc -l` -eq 1 ]
				then
					Result="양호"
					Exp="/etc/inetd.conf 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
					Evi=`ls -alL /etc/inetd.conf`
				else
					Result="취약"
					Exp="/etc/inetd.conf 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
					Evi=`ls -alL /etc/inetd.conf`
			fi
		else
			if [ -f /etc/xinetd.conf ]
			then
				if [ `ls -alL /etc/xinetd.conf | grep "...-------.*[root or bin].*" | wc -l` -eq 1 ]
					then
						Result="양호"
						Exp="/etc/xinetd.conf 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
						Evi=`ls -alL /etc/xinetd.conf`
					else
						Result="취약"
						Exp="/etc/xinetd.conf 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
						Evi=`ls -alL /etc/xinetd.conf`
				fi
				
			else
				Result="양호"
				Exp="/etc/inetd.conf or /etc/xinetd.conf 파일이 존재하지 않으므로 양호함"
				Evi=""
		fi
			
	fi
	echo " " >> $RESULT_TXT 2>&1
	if [ -d /etc/xinetd.d ] 
		then
			ls -alL /etc/xinetd.d/* >> $REF_FILE 2>&1
			ls -alL /etc/xinetd.d/* >> $RESULT_TXT 2>&1
	fi
	
	if [ -f /etc/inetd.conf ]
		then
			echo "ls -alL /etc/inetd.conf" >> $REF_FILE 2>&1
			ls -alL /etc/inetd.conf >> $REF_FILE 2>&1
	fi
	
	#Solaris
	if [ -f /etc/xinetd.conf ]
		then
			echo "#ls -alL /etc/xinetd.conf" >> $RESULT_TXT 2>&1
			ls -alL /etc/xinetd.conf >> $RESULT_TXT 2>&1
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# /etc/(r)syslog.conf 파일 소유자 및 권한 설정
U_21_syslog_permission() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="/etc/(r)syslog.conf 파일 소유자 및 권한 설정"
	Item_head "U-21" "$iTitle" "$iCODE"
	
	if [ -f /etc/syslog.conf ]
		then
			
			if [ `ls -alL /etc/syslog.conf | grep "...-.-----.*[root or bin].*" | wc -l` -eq 1 ]
				then
					Result="양호"
					Exp="/etc/syslog.conf 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
					Evi=`ls -alL /etc/syslog.conf | grep "...-.-----.*[root or bin].*"`
				else
					Result="취약"
					Exp="/etc/syslog.conf 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
					Evi=`ls -alL /etc/syslog.conf`
			fi
			

		
		elif [ -f /etc/rsyslog.conf ]
			then
			
				if [ `ls -alL /etc/rsyslog.conf | grep "...-.-----.*[root or bin].*" | wc -l` -eq 1 ]
					then
						Result="양호"
						Exp="/etc/rsyslog.conf 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
						Evi=`ls -alL /etc/rsyslog.conf | grep "...-.-----.*[root or bin].*"`
					else
						Result="취약"
						Exp="/etc/rsyslog.conf 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
						Evi=`ls -alL /etc/rsyslog.conf`
				fi
			
		else
					Result="수동점검"
					Exp="/etc/(r)syslog.conf 파일이 존재하지 않음"
					Evi=""
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# /etc/services 파일 소유자 및 권한 설정
U_22_services_permission() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="/etc/services 파일 소유자 및 권한 설정"
	Item_head "U-22" "$iTitle" "$iCODE"
	
	if [ -f /etc/services ]
		then
			if [ `ls -alL /etc/services | grep "...-.--.--.*[root or bin].*" | wc -l` -eq 1 ]
				then
					Result="양호"
					Exp="/etc/services 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
					Evi=`ls -alL /etc/services | grep "...-.--.--.*[root or bin].*"`
				else
					Result="취약"
					Exp="/etc/services 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
					Evi=`ls -alL /etc/services`
			fi
			
		else
			Result="양호"
			Exp="/etc/services 파일이 존재하지 않으므로 양호함"
			Evi=""
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# SUID,SGID,Stick bit 설정 파일 점검
U_23_suid_sgid_sticky() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="SUID,SGID,Stick bit 설정 파일 점검"
	Item_head "U-23" "$iTitle" "$iCODE"
	

		Result="수동점검"
		Exp="결과 참고하여 수동진단"
		Evi=""

		case $OS_STR in
			Linux)
			#LINUX
				checkDIR="/sbin/dump /usr/bin/lpq-lpd /usr/bin/newgrp /sbin/restore /usr/bin/lpr /usr/sbin/lpc /sbin/unix_chkpwd /usr/bin/lpr-lpd /usr/sbin/lpc-lpd /usr/bin/at /usr/bin/lprm /usr/sbin/traceroute /usr/bin/lpq /usr/bin/lprm-lpd"
				;;
			SunOS)
			#SunOS
				checkDIR="/usr/bin/admintool /usr/dt/bin/dtprintinfo /usr/sbin/arp /usr/bin/at /usr/dt/bin/sdtcm_convert /usr/sbin/lpmove /usr/bin/atq /usr/lib/fs/ufs/ufsdump /usr/sbin/prtconf /usr/bin/atrm /usr/lib/fs/ufs/ufsrestore /usr/sbin/sysdef /usr/bin/lpset /usr/lib/lp/bin/netpr /usr/sbin/sparcv7/prtconf /usr/bin/newgrp /usr/openwin/bin/ff.core /usr/sbin/sparcv7/sysdef /usr/bin/nispasswd /usr/openwin/bin/kcms_calibrate /usr/sbin/sparcv9/prtconf /usr/bin/rdist /usr/openwin/bin/kcms_configure /usr/sbin/sparcv9/sysdef /usr/bin/yppasswd /usr/openwin/bin/xlock /usr/dt/bin/dtappgather /usr/platform/sun4u/sbin/prtdiag"
				;;
			AIX)
			#AIX
				checkDIR="/usr/dt/bin/dtaction /usr/dt/bin/dtterm /usr/bin/X11/xlock /usr/sbin/mount /usr/sbin/lchangelv"
				;;
			HP-UX)
			#HP-UX
				checkDIR="/opt/perf/bin/glance /usr/dt/bin/dtprintinfo /usr/sbin/swreg /opt/perf/bin/gpm /usr/sbin/arp /usr/sbin/swremove /opt/video/lbin/camServer /usr/sbin/lanadmin /usr/contrib/bin/traceroute /usr/bin/at /usr/sbin/landiag /usr/dt/bin/dtappgather /usr/bin/lpalt /usr/sbin/lpsched /usr/sbin/swmodify /usr/bin/mediainit /usr/sbin/swacl /usr/sbin/swpackage /usr/bin/newgrp /usr/sbin/swconfig /usr/bin/rdist /usr/sbin/swinstall"
				;;
		esac
		echo "#find $checkDIR  -user root -type f \( -perm -04000 -o -perm -02000 \) -exec ls -al {} \;" >> $RESULT_TXT 2>&1
		find $checkDIR -user root -type f \( -perm -04000 -o -perm -02000 \) -exec ls -al {} \; >> $RESULT_TXT 2>&1
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 사용자, 시스템 환경변수 파일 소유자 및 권한 설정
U_24_profile_permission() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="사용자, 시스템 환경변수 파일 소유자 및 권한 설정"
	Item_head "U-24" "$iTitle" "$iCODE"
	
	if [ -f /etc/profile ]
		then 
			
			if [ `ls -alL /etc/profile | grep ".....-..-..*[root or bin].*" | wc -l` -eq 1 ]
				then
					Result="양호"
					Exp="/etc/profile 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
					Evi=`ls -alL /etc/profile`
				else
					Result="취약"
					Exp="/etc/profile 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
					Evi=`ls -alL /etc/profile`
			fi
			
		else
			Result="양호"
			Exp="/etc/profile 파일이 존재하지 않으므로 양호함"
			Evi=""
	fi
	

	if [ -f /.profile ]
		then
			echo "ls -l /.profile" >> $RESULT_TXT 2>&1
			ls -l /.profile >> $RESULT_TXT 2>&1
	fi
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# world writable 파일 점검 - /proc 제외, socket,  chatacter device 파일 제외
U_25_world_writable() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="world writable 파일 점검"
	Item_head "U-25" "$iTitle" "$iCODE"
	
	if [ $FIND_RUN = "true" ]
		then
			Result="수동점검"
			Exp="$REF_FILE 참고하여 수동진단"
			Evi=""
			
			case $OS_STR in
				HP-UX)
				#HP-UX
					echo "#find / ! \( -path '/proc*' -prune \) -perm -2 -type f -exec ls -alL {} \;" >> $REF_FILE 2>&1
					find / ! \( -path '/proc*' -prune \) -perm -2 -type f -exec ls -alL {} \; | grep -v "/var/opt/dce/rpc/local" | grep -v "/var/opt/dsau/tmp" | grep -v "/var/opt/cifsclient/" | grep -v "/var/opt/wbem/" | grep -v "/var/opt/hpservices/contrib/SysInfo" | grep -v "/dev/" | grep -v "/var/spool/" | grep -v "/tmp/" | grep -v "/var/opt/dce/security/" | grep -v "/var/tmp" | grep -v "/var/adm/streams" | grep -v "/var/home" | grep -v "/var/evm/sockets/evmd" | grep -v "/var/vx/isis/vea_portal" | grep -v "/var/stm/logs/ui_activity_log" | grep -v "/var/stm/catalog" | grep -v "/var/news" | grep -v "/var/asx" | grep -v "/var/asx/.serverlist" | grep -v "/var/jail/wp_internet/tmp" | grep -v "/var/preserve" | grep -v "/sbin/fsdaemondir/SOCKETS/fsdaemonSocket" | grep -v "/tmp" | grep -v "/etc/useracct/utmpd_read" | grep -v "/var/jail/wp_intranet/tmp" >> $REF_FILE 2>&1
					;;
					
				SunOS)
				#SunOS
					echo "#find / -xdev -perm -2 -ls | grep -v 'lrwxrwxrwx' | grep -v 'srwxrwxrwx' | grep -v 'srw-rw-rw-' | grep -v 'crw-rw-rw-' | grep -v '/dev/' | grep -v 'drwxrwxrwt' | tail -15000" >> $REF_FILE 2>&1
					find / -xdev -perm -2 -ls | grep -v 'lrwxrwxrwx' | grep -v 'srwxrwxrwx' | grep -v 'srw-rw-rw-' | grep -v 'crw-rw-rw-' | grep -v '/dev/' | grep -v 'drwxrwxrwt' | tail -15000 >> $REF_FILE 2>&1
					;;
					
				AIX)
				#AIX
					echo "#find / -xdev -perm -2 -ls | grep -v 'lrwxrwxrwx' | grep -v 'srwxrwxrwx' | grep -v 'srw-rw-rw-' | grep -v 'crw-rw-rw-' | grep -v '/dev/' | grep -v 'drwxrwxrwt' | tail -15000" >> $REF_FILE 2>&1
					find / -xdev -perm -2 -ls | grep -v 'lrwxrwxrwx' | grep -v 'srwxrwxrwx' | grep -v 'srw-rw-rw-' | grep -v 'crw-rw-rw-' | grep -v '/dev/' | grep -v 'drwxrwxrwt' | tail -15000 >> $REF_FILE 2>&1
					;;
					
				Linux)
				#Linux
					echo "find / -xdev -perm -2 -ls | grep -v 'lrwxrwxrwx' | grep -v 'srwxrwxrwx' | grep -v 'srw-rw-rw-' | grep -v 'crw-rw-rw-' | grep -v '/dev/' | grep -v 'drwxrwxrwt' | tail -15000" >> $REF_FILE 2>&1
					find / -xdev -perm -2 -ls | grep -v 'lrwxrwxrwx' | grep -v 'srwxrwxrwx' | grep -v 'srw-rw-rw-' | grep -v 'crw-rw-rw-' | grep -v '/dev/' | grep -v 'drwxrwxrwt' | tail -15000 >> $REF_FILE 2>&1
					;;
			esac
		else
			Result="수동점검"
			Exp="FIND 실행 안함으로 수동진단 필요"
			Evi=""
			
			echo "FIND 실행 안함으로 수동진단 필요" >> $REF_FILE 2>&1
	fi
		
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# /dev에 존재하지 않는 device 파일 점검
U_26_device_not_exists() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="/dev에 존재하지 않는 device 파일 점검"
	Item_head "U-26" "$iTitle" "$iCODE"
	
	Result="수동점검"
	Exp="결과 참고하여 인터뷰 실시, 양호시 출력 내용 없음"
	Evi=""

	echo "#find /dev -type f -exec ls -l {} \;" >> $RESULT_TXT 2>&1
	find /dev -type f -exec ls -l {} \; >> $RESULT_TXT 2>&1
	
	echo " " >> $RESULT_TXT 2>&1	
	Item_foot "$Result" "$Exp" "$Evi"
}

# $HOME/.rhosts, hosts.equiv 사용 금지
U_27_rhosts() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="\$HOME/.rhosts, hosts.equiv 사용 금지"
	Item_head "U-27" "$iTitle" "$iCODE"
	
	dir="/etc/xinetd.d"
	
	TMP_1=0
	TMP=0
	if [ -f /etc/hosts.equiv ]
		then
			if [ `cat /etc/hosts.equiv | grep -v "^#" | grep "\+" | wc -l` -eq 1 ]
				then
				TMP=`expr $TMP + 1`
			fi
		
			if [ `ls -alL /etc/hosts.equiv | egrep -c "...-------.*(root|bin).*"` -eq 0 ]
				then
				TMP_1=`expr $TMP_1 + 1`
			fi
	fi 
					
	case $OS_STR in
		Linux)
		#Linux:
		
			SERVICE="rlogin|rsh|rexec"
			
			if [ `chkconfig --list | egrep $SERVICE | egrep on | wc -l` -eq 0 ]
				then
					#프로세스 동작 안함
					R_SVR="false"
				else
					#프로세스 동작 중
					R_SVR="true"
			fi
			
			if [ `systemctl list-unit-files --type=service | egrep $SERVICE | egrep enabled | wc -l` -eq 0 ]
				then
					#프로세스 동작 안함
					R_SVR="false"
				else
					#프로세스 동작 중
					R_SVR="true"
			fi
			
			if [ $R_SVR = "true" ]
				then
					HOMEDIRS=`cat $PW_FILE | awk -F":" 'length($6) > 0 {print $6}' | sort -u`
					
					FILES=".rhosts"
					#TMP=0
					#TMP_1=0
					
					for dir in $HOMEDIRS
					do
						for file in $FILES
						do
							if [ -f $dir/$file ]
								then
									FILE_LIST="$FILE_LIST$dir/$file "
									HOST_CHECK="$dir/$file\n"`cat $dir/$file`
									HOST_CHECK_LIST="$HOST_CHECK_LIST$HOST_CHECK\n"
									
									ANY_HOST=`echo "$HOST_CHECK" | egrep "\+"`
									
									if [ `ls -alL $dir/$file | egrep -c "...-------.*"` -eq 0 ]
										then
											TMP_1=`expr $TMP_1 + 1`
									fi
										
									echo "" >> $RESULT_TXT 2>&1
									echo "#$dir/$file 소유자 $ACCOUNT_HOME" >> $RESULT_TXT 2>&1
									ls -alL $dir/$file >> $RESULT_TXT 2>&1
									
									if [ "$ANY_HOST" != "" ]
										then
											ANY_HOST_CHECK="$ANY_HOST_CHECK\n$dir/$file\n$ANY_HOST\n"
									fi
									TMP=`expr $TMP + 1`
							fi
						done
					done
					if [ $TMP -eq 0 -a $TMP_1 -eq 0 ]
						then
							Result="양호"
							Exp="R 서비스가 실행중이나 hosts.equiv과 .rhosts 파일이 미존재 또는 파일 권한과 접근제어 설정에 + + 설정이 없으므로 양호함"
							Evi=""
						else
							Result="수동점검"
							Exp="R 명령어 관련 설정파일의 내용에 + + 포함여부와 파일의 소유자 및 권한 확인"
							Evi=""
							echo "$ANY_HOST_CHECK" >> $RESULT_TXT 2>&1
					fi
				else
					Result="양호"
					Exp="R (rlogin|rsh|rexec) 서비스가 비실행중이므로 양호함"
					Evi="#chkconfig --list | egrep 'rlogin|rsh|rexec' #systemctl list-unit-files --type=service 결과 확인"
			fi
			
			if [ $R_SVR = "true" ]
				then
					if [ "$FILE_LIST" != "" ]
						then
							echo " " >> $RESULT_TXT 2>&1
							echo "#R 명령어 관련 설정 파일 내용" >> $RESULT_TXT 2>&1
							echo "$HOST_CHECK_LIST" >> $RESULT_TXT 2>&1
					fi
					
					if [ -f /etc/hosts.equiv ]
						then
							if [ `cat /etc/hosts.equiv | grep -v "^#" | grep "\+" | wc -l` -eq 0 ]
								then
									echo "etc/hosts.equiv 파일이 존재하나 + 옵션이 설정되어 있지 않음" >> $RESULT_TXT 2>&1

									echo "#cat /etc/hosts.equiv" >> $RESULT_TXT 2>&1
									cat /etc/hosts.equiv >> $RESULT_TXT 2>&1
								else
									echo "etc/hosts.equiv 파일이 존재하나 + 옵션이 설정되어 있음. 상세내역은 REF 파일 참조" >> $RESULT_TXT 2>&1
									echo "#cat /etc/hosts.equiv | grep '\+' 결과 확인" >> $RESULT_TXT 2>&1
									cat /etc/hosts.equiv | grep -v "^#" | grep "\+"  >> $RESULT_TXT 2>&1
				
									echo "#cat /etc/hosts.equiv" >> $REF_FILE 2>&1
									cat /etc/hosts.equiv >> $REF_FILE 2>&1
			
							fi
		
							if [ `ls -alL /etc/hosts.equiv | egrep -c "...-------.*(root|bin).*"` -eq 1 ]
								then
									echo "#ls -alL /etc/hosts.equiv 결과 확인" >> $RESULT_TXT 2>&1
									ls -alL /etc/hosts.equiv >> $RESULT_TXT 2>&1
								else
									echo "etc/hosts.equiv 소유자 및 권한이 과하게 설정되어 있음(권고 600)" >> $RESULT_TXT 2>&1
									ls -alL /etc/hosts.equiv >> $RESULT_TXT 2>&1
									echo "" >> $RESULT_TXT 2>&1
							fi
					fi 
			fi
			
			
			if [ $R_SVR = "true" ]
				then
					if [ -f /etc/inetd.conf ]
					then
						echo "#cat /etc/inetd.conf" >> $REF_FILE 2>&1
						echo " " >> $REF_FILE 2>&1
						cat /etc/inetd.conf >> $REF_FILE 2>&1
				fi
			
				if [ -f $dir/rlogin ]
					then
						echo "#cat $dir/rlogin" >> $RESULT_TXT 2>&1				
						cat "$dir/rlogin" | grep disable >> $RESULT_TXT 2>&1
						echo " " >> $RESULT_TXT 2>&1
				fi
			
				if [ -f $dir/rsh ]
					then
						echo "#cat $dir/rsh" >> $RESULT_TXT 2>&1
						cat "$dir/rsh" | grep disable >> $RESULT_TXT 2>&1
						echo " " >> $RESULT_TXT 2>&1
				fi
			
				if [ -f $dir/rexec ]
					then
						echo "#cat $dir/rexec" >> $RESULT_TXT 2>&1
						cat "$dir/rexec" | grep disable >> $RESULT_TXT 2>&1
						echo " " >> $RESULT_TXT 2>&1
				fi
			
				if [ -f /etc/hosts.equiv ]
					then
						echo "#ls -al /etc/hosts.equiv" >> $REF_FILE 2>&1
						ls -al /etc/hosts.equiv >> $REF_FILE 2>&1
						echo "#cat /etc/hosts.equiv" >> $REF_FILE 2>&1
						cat /etc/hosts.equiv >> $REF_FILE 2>&1
						echo " " >> $REF_FILE 2>&1
				fi
			fi
			
			unset HOMEDIRS
			unset FILES
			unset TMP
			unset TMP_1
		;;
		AIX | HP-UX)
		# AIX HP-UX:
			SERVICE="rlogin|rsh|rexec"
			if [ `cat /etc/inetd.conf | egrep $SERVICE | egrep -v "^#" | wc -l` -eq 0 ]
				then
					#프로세스 동작 안함
					CHK_VALUE=0
				else
					#프로세스 동작 중
					CHK_VALUE=1
					R_SVR="true"
			fi
				
			if [ $CHK_VALUE -eq 0 ]
				then
					Result="양호"
					Exp="R (rlogin|rsh|rexec)서비스가 비실행중이므로 양호함"
					Evi=`cat /etc/inetd.conf | egrep $SERVICE`
				else	
					HOMEDIRS=`cat $PW_FILE | awk -F":" 'length($6) > 0 {print $6}' | sort -u`
					
					FILES=".rhosts"
					#TMP=0
					#TMP_1=0
					for dir in $HOMEDIRS
					do
						for file in $FILES
						do
							if [ -f $dir/$file ]
								then
									FILE_LIST="$FILE_LIST$dir/$file "
									HOST_CHECK="$dir/$file\n"`cat $dir/$file`
									HOST_CHECK_LIST="$HOST_CHECK_LIST$HOST_CHECK\n"
									
									if [ `ls -alL $dir/$file | egrep -c "...-------.*"` -eq 0 ]
										then
											TMP_1=`expr $TMP_1 + 1`
									fi
										
									echo "" >> $RESULT_TXT 2>&1
									echo "#$dir/$file 소유자 $ACCOUNT_HOME" >> $RESULT_TXT 2>&1
									ls -alL $dir/$file >> $RESULT_TXT 2>&1
									
									ANY_HOST=`echo "$HOST_CHECK" | egrep "\+"`
																
									if [ "$ANY_HOST" != "" ]
										then
											ANY_HOST_CHECK="$ANY_HOST_CHECK\n$dir/$file\n$ANY_HOST\n"
									fi
									TMP=`expr $TMP + 1`
							fi
						done
					done
					if [ $TMP -eq 0 -a $TMP_1 -eq 0 ]
						then
							Result="양호"
							Exp="R 서비스가 실행중이나 hosts.equiv과 .rhosts 파일이 미존재 또는 파일 권한과 접근제어 설정에 + + 설정이 없으므로 양호함"
							Evi=""
						else
							Result="수동점검"
							Exp="R 명령어 관련 설정파일의 내용에 + + 포함여부와 파일의 소유자 및 권한 확인"
							Evi=""
							echo "$ANY_HOST_CHECK" >> $RESULT_TXT 2>&1
					fi				
			fi
		
			if [ $R_SVR = "true" ]
				then
					if [ "$FILE_LIST" != "" ]
						then
							echo " " >> $RESULT_TXT 2>&1
							echo "#R 명령어 관련 설정 파일 내용" >> $RESULT_TXT 2>&1
							echo "$HOST_CHECK_LIST" >> $RESULT_TXT 2>&1
					fi
					
					if [ -f /etc/hosts.equiv ]
						then
							if [ `cat /etc/hosts.equiv | grep -v "^#" | grep "\+" | wc -l` -eq 0 ]
								then
									echo "etc/hosts.equiv 파일이 존재하나 + 옵션이 설정되어 있지 않음" >> $RESULT_TXT 2>&1

									echo "#cat /etc/hosts.equiv" >> $RESULT_TXT 2>&1
									cat /etc/hosts.equiv >> $RESULT_TXT 2>&1
								else
									echo "etc/hosts.equiv 파일이 존재하나 + 옵션이 설정되어 있음. 상세내역은 REF 파일 참조" >> $RESULT_TXT 2>&1
									echo "#cat /etc/hosts.equiv | grep '\+' 결과 확인" >> $RESULT_TXT 2>&1
									cat /etc/hosts.equiv | grep -v "^#" | grep "\+"  >> $RESULT_TXT 2>&1
				
									echo "#cat /etc/hosts.equiv" >> $REF_FILE 2>&1
									cat /etc/hosts.equiv >> $REF_FILE 2>&1
			
							fi
		
							if [ `ls -alL /etc/hosts.equiv | egrep -c "...-------.*(root|bin).*"` -eq 1 ]
								then
									echo "#ls -alL /etc/hosts.equiv 결과 확인" >> $RESULT_TXT 2>&1
									ls -alL /etc/hosts.equiv >> $RESULT_TXT 2>&1
								else
									echo "etc/hosts.equiv 소유자 및 권한이 과하게 설정되어 있음(권고 600)" >> $RESULT_TXT 2>&1
									ls -alL /etc/hosts.equiv >> $RESULT_TXT 2>&1
									echo "" >> $RESULT_TXT 2>&1
							fi
					fi 
			fi
			
			if [ $CHK_VALUE -eq 1 ]
				then
					cat /etc/inetd.conf | egrep $SERVICE >> $RESULT_TXT 2>&1
					echo " " >> $RESULT_TXT 2>&1
					if [ -f /etc/hosts.equiv ]
						then
							echo "#ls -al /etc/hosts.equiv" >> $REF_FILE 2>&1
							ls -al /etc/hosts.equiv >> $REF_FILE 2>&1
					fi
					
					if [ -f /etc/hosts.equiv ]
					then
							echo "#cat /etc/hosts.equiv" >> $REF_FILE 2>&1
							cat /etc/hosts.equiv >> $REF_FILE 2>&1
					fi
			
					if [ -f $dir/rlogin ]
						then
							echo "#cat $dir/rlogin" >> $REF_FILE 2>&1
							cat "$dir/rlogin" | grep disable >> $REF_FILE 2>&1
							echo " " >> $REF_FILE 2>&1
					fi
			
					if [ -f $dir/rsh ]
						then
							echo "#cat $dir/rsh" >> $REF_FILE 2>&1
							cat "$dir/rsh" | grep disable >> $REF_FILE 2>&1
							echo " " >> $REF_FILE 2>&1
					fi
			
					if [ -f $dir/rexec ]
						then
							echo "#cat $dir/rexec" >> $REF_FILE 2>&1
							cat "$dir/rexec" | grep disable >> $REF_FILE 2>&1
							echo " " >> $REF_FILE 2>&1
					fi
			fi
			unset CHK_VALUE
			unset HOMEDIRS
			unset FILES
			unset TMP
			unset TMP_1
			unset dir
		;;
		
		SunOS)
		#SunOS:
			SERVICE_INETD="shell|login|exec"
			
			if [ $SOL_VER_PART = "1" ]
				then
					if [ -f /etc/inetd.conf ]
						then
							CHK_TEXT=`cat /etc/inetd.conf | grep -v "^ *#" | egrep $SERVICE_INETD`
							CHK_REF=$CHK_TEXT
							CHK_REF1=`cat /etc/inetd.conf | egrep $SERVICE_INETD`
							CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
					fi
				else
					CHK_REF=`inetadm | egrep $SERVICE_INETD`
					CHK_REF1=`inetadm | egrep $SERVICE_INETD`
					CHK_TEXT=`echo "$CHK_REF" | egrep "enabled"`
					CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
			fi
			
			if [ $CHK_VALUE -ne 0 ]
				then
					R_SVR="true"
			fi
			if [ $R_SVR = "true" ]
				then
					HOMEDIRS=`cat $PW_FILE | awk -F":" 'length($6) > 0 {print $6}' | sort -u`
					FILES=".rhosts"
					#TMP=0
					#TMP_1=0
					for dir in $HOMEDIRS
					do
						for file in $FILES
						do
							if [ -f $dir/$file ]
								then
									FILE_LIST="$FILE_LIST$dir/$file "
									HOST_CHECK="$dir/$file\n"`cat $dir/$file`
									HOST_CHECK_LIST="$HOST_CHECK_LIST$HOST_CHECK\n"


									if [ `ls -alL $dir/$file | egrep -c "...-------.*"` -eq 0 ]
										then
											TMP_1=`expr $TMP_1 + 1`
									fi
										
									echo "" >> $RESULT_TXT 2>&1
									echo "#$dir/$file 소유자 $ACCOUNT_HOME" >> $RESULT_TXT 2>&1
									ls -alL $dir/$file >> $RESULT_TXT 2>&1
						
									
									ANY_HOST=`echo "$HOST_CHECK" | egrep "\+"`
																		
									if [ "$ANY_HOST" != "" ]
										then
											ANY_HOST_CHECK="$ANY_HOST_CHECK\n$dir/$file\n$ANY_HOST\n"
									fi
									TMP=`expr $TMP + 1`
							fi
						done
					done
					
					if [ $TMP -eq 0 -a $TMP_1 -eq 0 ]
						then
							Result="양호"
							Exp="R 서비스가 실행중이나 hosts.equiv과 .rhosts 파일이 미존재 또는 파일 권한과 접근제어 설정에 + + 설정이 없으므로 양호함"
							Evi=""
						else
							Result="수동점검"
							Exp="R 명령어 관련 설정파일의 내용에 + + 포함여부와 파일의 소유자 및 권한 확인"
							Evi=""
							echo "$ANY_HOST_CHECK" >> $RESULT_TXT 2>&1
						
					fi
				else
					Result="양호"
					Exp="R (rlogin|rsh|rexec)서비스가 비실행중이므로 양호함"
					Evi="$CHK_REF1"
			fi
			
			if [ $R_SVR = "true" ]
				then
					if [ "$FILE_LIST" != "" ]
						then
							echo " " >> $RESULT_TXT 2>&1
							echo "#R 명령어 관련 설정 파일 내용" >> $RESULT_TXT 2>&1
							echo "$HOST_CHECK_LIST" >> $RESULT_TXT 2>&1
					fi
					
					if [ -f /etc/hosts.equiv ]
						then
							if [ `cat /etc/hosts.equiv | grep -v "^#" | grep "\+" | wc -l` -eq 0 ]
								then
									echo "etc/hosts.equiv 파일이 존재하나 + 옵션이 설정되어 있지 않음" >> $RESULT_TXT 2>&1

									echo "#cat /etc/hosts.equiv" >> $RESULT_TXT 2>&1
									cat /etc/hosts.equiv >> $RESULT_TXT 2>&1
								else
									echo "etc/hosts.equiv 파일이 존재하나 + 옵션이 설정되어 있음. 상세내역은 REF 파일 참조" >> $RESULT_TXT 2>&1
									echo "#cat /etc/hosts.equiv | grep '\+' 결과 확인" >> $RESULT_TXT 2>&1
									cat /etc/hosts.equiv | grep -v "^#" | grep "\+"  >> $RESULT_TXT 2>&1
				
									echo "#cat /etc/hosts.equiv" >> $REF_FILE 2>&1
									cat /etc/hosts.equiv >> $REF_FILE 2>&1
			
							fi
		
							if [ `ls -alL /etc/hosts.equiv | egrep -c "...-------.*(root|bin).*"` -eq 1 ]
								then
									echo "#ls -alL /etc/hosts.equiv 결과 확인" >> $RESULT_TXT 2>&1
									ls -alL /etc/hosts.equiv >> $RESULT_TXT 2>&1
								else
									echo "etc/hosts.equiv 소유자 및 권한이 과하게 설정되어 있음(권고 600)" >> $RESULT_TXT 2>&1
									ls -alL /etc/hosts.equiv >> $RESULT_TXT 2>&1
									echo "" >> $RESULT_TXT 2>&1
							fi
					fi 
			fi
			unset TMP_1
			unset TMP
		;;
				
		*)
		#
		;;
		
	esac
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 접속 IP 및 포트 제한
U_28_hosts_allow() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="접속 IP 및 포트 제한"
	Item_head "U-28" "$iTitle" "$iCODE"
	case $OS_STR in
		
		SunOS)
		#SunOS:
			TCPWrapper_check ftp
			FTP_MSG=$TMP_MSG
			FTP_RESULT1=$TMP_RESULT
			TCPWrapper_check telnet
			TEL_MSG=$TMP_MSG
			TEL_RESULT1=$TMP_RESULT
	
			if [ -f /etc/hosts.allow ]
				then
					HOST_ALLOW=`cat /etc/hosts.allow`
					ALLOW_RESULT=1
				else
					HOST_ALLOW="파일이 존재하지 않음"
					ALLOW_RESULT=0
			fi
			
			if [ -f /etc/hosts.deny ]
				then
					HOST_DENY=`cat /etc/hosts.deny`
					DENY_RESULT=1
				else
					HOST_DENY="파일이 존재하지 않음"
					DENY_RESULT=0
			fi
			
			if [ $FTP_RESULT1 -eq 1 -a $TEL_RESULT1 -eq 1 -a $ALLOW_RESULT -eq 1 -a $DENY_RESULT -eq 1 ]
				then
					Result="수동점검"
					Exp="설정파일을 참고하여 수동진단"
					Evi=""
				else
					Result="취약"
					Exp="접속 IP 및 포트 제한 설정이 존재하지 않으므로 취약함"
					echo "#inetadm -p " >> $RESULT_TXT 2>&1
					inetadm -p                   >> $RESULT_TXT 2>&1 
					echo "cat /etc/ipf/ipf.conf" >> $RESULT_TXT 2>&1
					cat /etc/ipf/ipf.conf >> $RESULT_TXT 2>&1
					
					
					Evi=""
			fi
			
			echo "1) 서비스 진단 결과" >> $RESULT_TXT 2>&1
			echo $FTP_MSG >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
			echo $TEL_MSG >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
			
			echo "2) hosts.allow 파일의 설정내용" >> $RESULT_TXT 2>&1
			echo "$HOST_ALLOW" >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
			echo "3) hosts.deny 파일의 설정내용" >> $RESULT_TXT 2>&1
			echo "$HOST_DENY" >> $RESULT_TXT 2>&1
			
			echo " " >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
			
			unset SERVICE_INETD
			unset SERVICES
			unset FTP_MSG
			unset FTP_RESULT1
			unset TEL_MSG
			unset TEL_RESULT1
			unset HOST_ALLOW
			unset ALLOW_RESULT
			unset HOST_DENY
			unset DENY_RESULT
		;;
		
		Linux)
		#Linux:
			if [ -f /etc/hosts.allow ]
				then
					HOST_ALLOW=`cat /etc/hosts.allow`
					ALLOW_RESULT=1
				else
					HOST_ALLOW="/etc/hosts.allow 파일이 존재하지 않음"
					ALLOW_RESULT=0
			fi
			
			if [ -f /etc/hosts.deny ]
				then
					HOST_DENY=`cat /etc/hosts.deny`
					DENY_RESULT=1
				else
					HOST_DENY="/etc/hosts.deny 파일이 존재하지 않음"
					DENY_RESULT=0
			fi
			
			if [ -f /etc/sysconfig.iptables ]
				then
					SYSCONFIG_IPTABLES=`cat /etc/sysconfig.iptables`
					IPTABLES_RESULT=1
				else
					SYSCONFIG_IPTABLES="/etc/sysconfig.iptables 파일이 존재하지 않음"
					IPTABLES_RESULT=0
			fi
			
			if [ $ALLOW_RESULT -eq 1 -a $DENY_RESULT -eq 1 ]
				then
					Result="수동점검"
					Exp="설정 파일 결과 참고하여 수동진단"
					Evi=""
				else
					Result="취약"
					Exp="Tcp Wrappers 접속 IP 및 포트 제한 설정이 존재하지 않으므로 취약함"
					Evi=""
			fi
			
			if [ $IPTABLES_RESULT -eq 1 ]
				then
					Result="수동점검"
					Exp="설정 파일 결과 참고하여 수동진단"
					Evi=""
				else
					Result="취약"
					Exp="Iptables 접속 IP 및 포트 제한 설정이 존재하지 않으므로 취약함"
					Evi=""
			fi
			
			echo "1) 방화벽 서비스 설치 여부 확인" >> $RESULT_TXT 2>&1
			rpm -qa | grep wrappers | grep iptables | grep firewalld >> $RESULT_TXT 2>&1
			
			echo "2) hosts.allow 파일의 설정내용" >> $RESULT_TXT 2>&1
			echo "$HOST_ALLOW" >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
			echo "3) hosts.deny 파일의 설정내용" >> $RESULT_TXT 2>&1
			echo "$HOST_DENY" >> $RESULT_TXT 2>&1
			echo "4) sysconfig.iptables 파일의 설정내용" >> $RESULT_TXT 2>&1
			echo "$SYSCONFIG_IPTABLES" >> $RESULT_TXT 2>&1
			echo "5) Firewall 서비스의 설정내용" >> $RESULT_TXT 2>&1
			firewall-cmd --list-all >> $RESULT_TXT 2>&1
			
			echo " " >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
			
			unset HOST_ALLOW
			unset ALLOW_RESULT
			unset HOST_DENY
			unset DENY_RESULT
			unset SYSCONFIG_IPTABLES
			unset IPTABLES_RESULT
		;;
		
		AIX | HP-UX)
		#AIX HP-UX:
			if [ -f /etc/hosts.allow ]
				then
					HOST_ALLOW=`cat /etc/hosts.allow`
					ALLOW_RESULT=1
				else
					HOST_ALLOW="파일이 존재하지 않음"
					ALLOW_RESULT=0
			fi
			if [ -f /etc/hosts.deny ]
				then
					HOST_DENY=`cat /etc/hosts.deny`
					DENY_RESULT=1
				else
					HOST_DENY="파일이 존재하지 않음"
					DENY_RESULT=0
			fi
			if [ -f /etc/ipf/ipf.conf ]
				then
					IPF_CONF=`cat /etc/ipf/ipf.conf`
					IPF_RESULT=1
				else
					IPF_CONF="/etc/ipf/ipf.conf 파일이 존재하지 않음"
					IPF_RESULT=0
			fi
			
			if [ $ALLOW_RESULT -eq 1 -a $DENY_RESULT -eq 1 ]
				then
					Result="수동점검"
					Exp="설정 파일 결과 참고하여 수동진단"
					Evi=""
				else
					Result="취약"
					Exp="Tcp Wrappers 접속 IP 및 포트 제한 설정이 존재하지 않으므로 취약함"
					Evi=""
			fi
			
			if [ $IPF_RESULT -eq 1 ]
				then
					Result="수동점검"
					Exp="설정 파일 결과 참고하여 수동진단"
					Evi=""
				else
					Result="취약"
					Exp="IPfilter 접속 IP 및 포트 제한 설정이 존재하지 않으므로 취약함"
					Evi=""
			fi
			
			echo "1) 방화벽 서비스 진단 결과" >> $RESULT_TXT 2>&1
			rpm -qa | grep wrappers >> $RESULT_TXT 2>&1
			
			echo "2) hosts.allow 파일의 설정내용" >> $RESULT_TXT 2>&1
			echo "$HOST_ALLOW" >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
			echo "3) hosts.deny 파일의 설정내용" >> $RESULT_TXT 2>&1
			echo "$HOST_DENY" >> $RESULT_TXT 2>&1
			echo "4) ipf.conf 파일의 설정내용" >> $RESULT_TXT 2>&1
			echo "$IPF_CONF" >> $RESULT_TXT 2>&1
			if [ -f /var/adm/inetd.sec ]
				then
					echo "#cat /var/adm/inetd.sec" >> $RESULT_TXT 2>&1
					cat /var/adm/inetd.sec >> $RESULT_TXT 2>&1
			fi
			
			echo " " >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
			
			unset HOST_ALLOW
			unset ALLOW_RESULT
			unset HOST_DENY
			unset DENY_RESULT
			unset IPF_CONF
			unset IPF_RESULT
		;;
				
		*)
		#
		;;
		
	esac
}

# host.lpd 파일 소유자 및 권한 설정
U_29_host_lpd() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="host.lpd 파일 소유자 및 권한 설정"
	Item_head "U-29" "$iTitle" "$iCODE"
	
	if [ -f /etc/hosts.lpd ] 
		then	
			if [ `ls -alL /etc/hosts.lpd | grep ".r.-------.*[root or bin].*" | wc -l` -eq 1 ]
				then
					Result="양호"
					Exp="/etc/hosts.lpd 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
					Evi=`ls -alL /etc/hosts.lpd`
				else
					Result="취약"
					Exp="/etc/hosts.lpd 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
					Evi=`ls -alL /etc/hosts.lpd`
			fi
		else
			Result="양호"
			Exp="/etc/hosts.lpd 파일이 없으므로 양호함"
			Evi="#ls -alL /etc/hosts.lpd 결과 확인"
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# UMASK 설정 관리
U_30_user_umask() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="UMASK 설정 관리"
	Item_head "U-30" "$iTitle" "$iCODE"
	
	Result="수동점검"
	Exp="umask 값 및 profile 설정 참고하여 수동진단"
	if [ $OS_STR = "Linux" ]
		then
			Evi=`grep -i "UMASK" -C3 /etc/profile | grep -v "^#"`
		else
			Evi=`grep -i "UMASK" /etc/profile | grep -v "^#"`
	fi
	echo "" >> $RESULT_TXT 2>&1
	echo "umask 명령어 실행결과" >> $RESULT_TXT 2>&1
	umask >> $RESULT_TXT 2>&1
	
	cat /etc/profile >> $REF_FILE 2>&1
	echo "" >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 관리자 UMASK 설정 관리
root_umask() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="관리자 UMASK 설정 관리"
	Item_head "FSU" "$iTitle" "$iCODE"
	
	if [ `umask` = 0022 ]
		then
			Result="양호"
			Exp="UMASK의 값이 022이므로 양호함"
			Evi=`umask`
		else	
			if [ `umask` = 0077 ]
				then
					Result="양호"
					Exp="UMASK의 값이 077이므로 양호함"
					Evi=`umask`
				else
					Result="취약"
					Exp="UMASK의 값이 적절하게 설정되어 있지 않으므로 취약함"
					Evi=`umask`
			fi
	fi
	
	echo "#Umask의 값" >> $RESULT_TXT 2>&1
	umask >> $RESULT_TXT 2>&1
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 홈 디렉토리 소유자 및 권한 설정
U_31_user_home_dir() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="홈 디렉토리 소유자 및 권한 설정"
	Item_head "U-31" "$iTitle" "$iCODE"
	
	FILE=`awk -F: '{print $1":"$6}' $PW_FILE`
	
	for check_own in $FILE
	do
	
		FILE_OWN=`echo $check_own | awk -F: '{print $1}'`
		CHECK_DIR=`echo $check_own | awk -F: '{print $2}'`
		
		if [ "$CHECK_DIR" != "" ]
			then
				if [ -d $CHECK_DIR ]
					then

						perm_check $CHECK_DIR
						MARK=""

						if [ "$FILE_OWN" != "$OWNER" ]
							then
								if  [ "$OWNER" != "root" -a "$OWNER" != "uucp" -a "$OWNER" != "bin" ]
									then
										REGUL_SET="$REGUL_SET
$CHECK_DIR[$FILE_OWN] : $OWNER"
										MARK="<"
								fi
						fi
						
						FILE_AUTH_CHK=`ls -alLd $CHECK_DIR | awk '{print $1}'`
						if [ `echo $FILE_AUTH_CHK | grep "d.......-..*" | wc -l` -eq 0 ]
							then
								FILE_OTHER_AUTH="other 쓰기 권한 확인($FILE_AUTH_CHK)"
								MARK="<"
								
								REGUL_SET1="$REGUL_SET1
$CHECK_DIR[$FILE_OWN] : $FILE_OTHER_AUTH"
							else
								FILE_OTHER_AUTH=""							
						fi

						
						FILE_OWN_RESULT="$FILE_OWN_RESULT
$CHECK_DIR[$FILE_OWN] : $OWNER : $FILE_OTHER_AUTH $MARK"

				fi
		fi
	done

	if [ "$REGUL_SET" != "" -o "$REGUL_SET1" != "" ]
		then
			Result="취약"
			Exp="사용자와 홈디렉토리의 소유자가 일치하지 않거나, 파일의 접근권한이 적절하게 부여되어 있지 않으므로 취약함(root, bin, uucp외)"
			Evi="#홈디렉토리 소유자 미일치
$REGUL_SET

#other 사용자 쓰기 권한 부여
$REGUL_SET1"
			
			
		else
			Result="양호"
			Exp="홈디렉토리 사용자 및 소유자가 일치하며, 해당 디렉토리 및 파일의 접근권한이 적절하게 부여되어 있어 양호함(root, bin, uucp외)"
			Evi=""
	fi
	
	echo "" >> $RESULT_TXT 2>&1
	echo "# 사용자와 홈디렉토리의 소유자 비교" >> $RESULT_TXT 2>&1
	echo "" >> $RESULT_TXT 2>&1
	echo "홈 dir[계정] : dir 소유자 형식 : 권한(other 사용자에 쓰기 권한 부여시 출력)" >> $RESULT_TXT 2>&1
	echo "========================================================================" >> $RESULT_TXT 2>&1
	echo "$FILE_OWN_RESULT" >> $RESULT_TXT 2>&1
	echo " " >> $RESULT_TXT 2>&1
	
	echo "# $PW_FILE 의 홈디렉토리 권한" >> $RESULT_TXT 2>&1
	HOMEDIRS=`cat $PW_FILE | awk -F":" 'length($6) > 0 {print $6}' | grep -wv "\/" | sort -u`
  
	for dir in $HOMEDIRS
	 do
	    if [ -f $dir ]
	    then
            ls -dal $dir | grep '\d.........' >> $RESULT_TXT 2>&1
	    fi
         done
	
	if [ -f $PW_FILE ]
		then
			cat $PW_FILE >> $REF_FILE 2>&1
	fi
	
	echo "" >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
	
    unset FILE_OWN
    unset CHECK_DIR
    unset REGUL_SET
	unset REGUL_SET1
    unset FILES
	unset FILE_AUTH_CHK
	unset FILE_OTHER_AUTH
    unset TMP
}

# 홈 디렉토리로 지정한 디렉토리의 존재 관리
U_32_user_home_not_exists() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="홈 디렉토리로 지정한 디렉토리의 존재 관리"
	Item_head "U-32" "$iTitle" "$iCODE"
	
	TEMP_STR=`cat /etc/passwd | awk -F: '{ print $1":"$6 }'`
	
	for HOME_DATA in $TEMP_STR
	do
		HOME_OWNER=`echo $HOME_DATA | awk -F: '{ print $1 }'`
		HOME=`echo $HOME_DATA | awk -F: '{ print $2 }'`
		
		if [ -d $HOME ]
			then
				RESULT=""
			else
				RESULT="[없음]"
				REGUL_SET="$REGUL_SET
$HOME_OWNER->$HOME"
		fi

		DIR_LIST="$DIR_LIST$HOME_OWNER->$HOME $RESULT\n"
	done
	
	if [ "$REGUL_SET" != "" ]
		then
			Result="취약"
			Exp="홈 디렉토리로 지정한 디렉토리 중 존재하지 않는 디렉토리가 있으므로 취약함"
			Evi=$REGUL_SET
		else
			Result="양호"
			Exp="홈 디렉토리로 지정한 디렉토리가 모두 존재하므로 양호함"
			Evi=""
	fi

	echo "계정 -> 홈dir 형식" >> $RESULT_TXT 2>&1
	printf "$DIR_LIST" >> $RESULT_TXT 2>&1

	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"

	unset TEMP_STR
	unset HOME_DATA
	unset HOME_OWNER
	unset HOME
	unset REGUL_SET
	unset DIR_LIST
	unset DIR
	unset RESULT
}

# 숨겨진 파일 및 디렉토리 검색 및 제거
U_33_hidden_files() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="숨겨진 파일 및 디렉토리 검색 및 제거"
	Item_head "U-33" "$iTitle" "$iCODE"
	
	if [ $FIND_RUN = "true" ]
		then
			Result="수동점검"
			Exp="$REF_FILE 참고하여 인터뷰 실시"
			Evi=""
			
			echo "find / -name '.*' -print -xdev | cat '-v'" >> $REF_FILE 2>&1
			find / -xdev -name '.*' -print | cat -v >> $REF_FILE 2>&1
		else
			Result="수동점검"
			Exp="FIND 실행 안함으로 수동진단 필요"
			Evi=""
			
			echo "FIND 실행 안함으로 수동진단 필요" >> $REF_FILE 2>&1
	fi
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# root PATH의 디렉토리 소유자 및 접근권한
root_path_permission() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="root PATH의 디렉토리 소유자 및 접근권한"
	Item_head "ETC" "$iTitle" "$iCODE"
	
	DIR=`echo $PATH | awk 'BEGIN{FS=":"; OFS="\n"} {i=1; while(i<=NF) {print $i; i++}}'`
	
	for check_dir in $DIR
	do
		if [ -d $check_dir ]
			then
				perm_check $check_dir

				DIR_LIST="$DIR_LIST$check_dir "
				
				if [ "$OWNER" != "root" -o "$oPn" -gt 5 ]
					then
						## BIN 일경우 제외
						#if [ RESULT_OWNER != "bin" ]
						#	then
						#		REGUL_SET=$REGUL_SET+$check_dir
						#fi
						REGUL_SET="$REGUL_SET$check_dir "
				fi
		fi
	done
	
	if [ "$REGUL_SET" != "" ]
		then
			Result="취약"
			Exp="디렉토리의 소유자가 root가 아니거나, other 사용자의 권한이 과도하게 설정되어 있으므로 취약함"
			Evi=`ls -alLd $REGUL_SET`
		else
			Result="양호"
			Exp="디렉토리의 소유자가 root이고, other 사용자의 권한이 적절하게 설정되어 있으므로 양호함"
			Evi=`ls -alLd $REGUL_SET`
	fi
	
	echo "1) root PATH directories" >> $RESULT_TXT 2>&1
	ls -alLd $DIR_LIST >> $RESULT_TXT 2>&1
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
	
	 unset REGUL_SET
	 unset DIR_LIST
	 unset DIR
}

# Default Skeleton 파일의 실행권한
Default_Skeleton() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="Default Skeleton 파일의 실행권한"
	Item_head "ETC" "$iTitle" "$iCODE"
	
	TARGET_FILE="/etc/skel/local.cshrc /etc/skel/local.login /etc/skel/local.profile"
	
	for check_file in $TARGET_FILE
	do
	if [ -f $check_file ]
		then
			perm_check $check_file

			FILE_LIST="$FILE_LIST$check_file "
			
			if [ $uPn -gt 6 -o $gPn -gt 4 -o $oPn -gt 0 ]
				then
					REGUL_SET="$REGUL_SET$check_file "
			fi
	fi
	done
	if [ "$REGUL_SET" != "" ]
		then
			Result="취약"
			Exp="Default Skeleton 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
			Evi=`ls -alL $REGUL_SET`
		else
			Result="양호"
			Exp="Default Skeleton 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
			Evi=`ls -alL $REGUL_SET`
	fi
	
	echo "1) Default Skeleton 파일의 접근권한" >> $RESULT_TXT 2>&1
	echo " " >> $RESULT_TXT 2>&1
	ls -alL $FILE_LIST >> $RESULT_TXT 2>&1
	
	Item_foot "$Result" "$Exp" "$Evi"
	
    unset TARGET_FILE
    unset OWNER_PERM
    unset GROUP_PERM
    unset OTHER_PERM
    unset REGUL_SET
    unset FILE_LIST
}

# Kernel 파라메터 설정
kernel_param() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="Kernel 파라메터 설정"
	Item_head "ETC" "$iTitle" "$iCODE"
	
	if [ -f $KERNEL_FILE ]
		then
			Result="수동점검"
			Exp="$KERNEL_FILE 파일 내용"
			Evi=`cat $KERNEL_FILE |  grep -v "^ *#" | grep "ndd" | sed -e 's/\"/\"\"/g'`
		else
			Result="취약"
			Exp="$KERNEL_FILE 파일이 존재하지 않음"
			Evi=""
	fi
	
	Item_foot "$Result" "$Exp" "$Evi"
	
    unset RESULT
}

# TCP sequence 파라메터 설정
tcp_sequence() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="TCP sequence 파라메터 설정"
	Item_head "ETC" "$iTitle" "$iCODE"
    if [ -f $D_KERNEL_FILE ]
		then
			CHK=`cat $D_KERNEL_FILE | grep -i "TCP_STRONG_ISS=" | grep -v "^ *#"`
			CHK_VALUE=`echo $CHK | awk 'BEGIN {FS="="}{print $2}'`
		else
			Result="취약"
			Exp="$D_KERNEL_FILE 파일이 존재하지 않음"
			Evi=""
	fi
	
	if [ "$CHK_VALUE" != "" ]
		then
			if [ "$CHK_VALUE" = "1" ]
				then
					Result="양호"
					Exp="TIMEOUT 설정이 정상입니다"
					Evi="$CHK"
				else
					Result="취약"
					Exp="TIMEOUT 값이 취약하게 설정되어 있음"
					Evi="$CHK"
				fi
		else
			Result="취약"
			Exp="TIMEOUT 설정이 존재하지 않음"
			Evi=""
	fi
	
	echo "1) $D_KERNEL_FILE 파일 내용" >> $RESULT_TXT 2>&1
	cat $D_KERNEL_FILE | grep -i "TCP_STRONG_ISS=" >> $RESULT_TXT 2>&1
	
	Item_foot "$Result" "$Exp" "$Evi"
	
    unset TIMEOUT
    unset RESULT
    unset CHK_VALUE
}

# Finger 서비스 비활성화 - chkconfig로 체크
U_34_finger() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="Finger 서비스 비활성화"
	Item_head "U-34" "$iTitle" "$iCODE"
	
	case $OS_STR in
		AIX | HP-UX)
		#AIX HP-UX:
			SERVICE="finger"
			FINGER=""
			if [ `cat /etc/inetd.conf | egrep $SERVICE | egrep -v "^#" | wc -l` -eq 0 ]
				then
					#프로세스 동작 안함
					CHK_VALUE=0
				else
					#프로세스 동작 중
					CHK_VALUE=1
			fi
			
			if [ $CHK_VALUE -eq 1 ]
				then
					Result="취약"
					Exp="현재 finger 서비스가 실행중이므로 취약함"
					Evi=`cat /etc/inetd.conf | grep finger`
				else
					Result="양호"
					Exp="현재 finger 서비스가 비실행중이므로 양호함"
					Evi=`cat /etc/inetd.conf | grep finger`
			fi
			
			echo " " >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
			unset SERVICE
			unset CHK_VALUE
		;;
		
		Linux)
		#Linux
			SERVICE="finger"
			FINGER=""
			if [ -f /etc/xinetd.d/finger ]
				then
					if [ `cat /etc/xinetd.d/finger | egrep disable | egrep yes | wc -l` -eq 1 ]
						then
							#프로세스 동작 안함
							CHK_VALUE=0
						else
							#프로세스 동작 중
							CHK_VALUE=1
					fi
			
					if [ $CHK_VALUE -eq 1 ]
						then
							Result="취약"
							Exp="현재 finger 서비스가 실행중이므로 취약함"
							Evi=`cat /etc/xinetd.d/finger | egrep disable`					
						else
							Result="양호"
							Exp="현재 finger 서비스가 비실행중이므로 양호함"
							Evi=`cat /etc/xinetd.d/finger | egrep disable`
					fi
				else
					Result="양호"
					Exp="finger 파일이 존재하지 않으므로 양호함"
					Evi="#cat /etc/xinetd.d/finger 파일 확인"
			fi
			
			echo " " >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
			unset SERVICE
			unset CHK_VALUE
		;;
		
		SunOS)
		#SunOS:
			SERVICE_INETD="finger"
			
			if [ $SOL_VER_PART = "1" ]
				then
					if [ -f /etc/inetd.conf ]
						then
							CHK_TEXT=`cat /etc/inetd.conf | grep -v "^ *#" | egrep $SERVICE_INETD`
							CHK_REF=$CHK_TEXT
							CHK_REF1=`cat /etc/inetd.conf | egrep $SERVICE_INETD`
							CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
						else
							$CHK_VALUE=-1
					fi
				else
					CHK_REF=`inetadm | egrep $SERVICE_INETD`
					CHK_REF1=`inetadm | egrep $SERVICE_INETD`
					CHK_TEXT=`echo "$CHK_REF" | egrep "enabled"`
					CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
			fi
			
			if [ $CHK_VALUE -eq -1 ]
				then
					Result="수동점검"
					Exp="inetd.conf 파일이 존재하지 않음"
					Evi="$CHK_TEXT"
				elif [ $CHK_VALUE -eq 0 ]
				then
					Result="양호"
					Exp="내부 사용자 정보 노출 서비스가 비실행중이므로 양호함"
					Evi="$CHK_REF1"
				else
					Result="취약"
					Exp="내부 사용자 정보 노출 서비스가 실행중이므로 취약함"
					Evi="$CHK_TEXT"
				fi
			
			echo "1) 내부 사용자 정보 노출 서비스 현황" >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
			echo "$CHK_REF" >> $RESULT_TXT 2>&1
			
			echo " " >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
			
			unset SERVICE_INETD
			unset CHK_REF
			unset CHK_REF1
			unset CHK_TEXT
			unset CHK_VALUE
		;;
		
		*)
		#
		;;
		
	esac
}

# 공유 서비스에 대한 익명 접근 제한 설정
U_35_anonymous_disabled() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="공유 서비스에 대한 익명 접근 제한 설정"
	Item_head "U-35" "$iTitle" "$iCODE"
	SERVICE="ftp|nfsd|samba"
	case $OS_STR in
		Linux | AIX | HP-UX)
		#Linux AIX HP-UX:
			if [ $FTP_SVR = "false" ]
				then
					Result="양호"
					Exp="공유 서비스가 비실행중이므로 양호함"
					Evi=""
				else
					Result="수동점검"
					Exp="공유 서비스가 실행중으로 anonymous 접속 확인 필요"
					Evi=`ps -ef | egrep "ftp|nfsd|samba" | egrep -v "grep|sftp"`
			fi
			
			if [ $FTP_SVR = "true" ]
				then 
					if [ -f /etc/passwd ]
						then
							echo "#cat /etc/passwd" ftp 계정확인 >> $RESULT_TXT 2>&1
							cat /etc/passwd | grep ftp >> $RESULT_TXT 2>&1
							echo "#cat /etc/passwd" ftp 계정확인 >> $REF_FILE 2>&1
							cat /etc/passwd >> $REF_FILE 2>&1
					fi
			
					if [ -f /etc/vsftpd/vsftpd.conf ]
						then
							echo "#cat /etc/vsftpd/vsftpd.conf | grep anonymous_enable" >> $RESULT_TXT 2>&1
							cat /etc/vsftpd/vsftpd.conf | grep "anonymous\_enable">> $RESULT_TXT 2>&1
							echo "#cat /etc/vsftpd/vsftpd.conf" >> $REF_FILE 2>&1
							cat /etc/vsftpd/vsftpd.conf >> $REF_FILE 2>&1
					fi
					
					if [ -f /etc/vsftpd.conf ]
						then
							echo "#cat /etc/vsftpd.conf | grep anonymous_enable" >> $RESULT_TXT 2>&1
							cat /etc/vsftpd.conf | grep "anonymous_enable" >> $RESULT_TXT 2>&1
							echo "#cat /etc/vsftpd.conf" >> $REF_FILE 2>&1
							cat /etc/vsftpd.conf >> $REF_FILE 2>&1
					fi
			fi
			ps -ef | egrep "ftp|nfsd|samba" | egrep -v "grep|sftp" >> $RESULT_TXT 2>&1
			echo "" >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
			
			unset SERVICE
			unset CHK_VALUE
		;;
		
		SunOS)
		#SunOS:
			if [ $FTP_SVR = "false" ]
				then
					Result="양호"
					Exp="FTP 서비스가 비실행중이므로 양호함"
					Evi=""
				else
					Result="수동점검"
					Exp="FTP 서비스가 실행중으로 anonymous 접속 확인 필요"
					Evi="$FTP_RESULT"
					
					FTP_SVR="true"
				
		# /etc/passwd에서 FTP 계정 확인
		#		if [ $FTP_SVR = "true" ]
		#    		then
		#			FTP_PASSWD_RESULT=`cat $PW_FILE | grep -v "^ *#" | grep "^ftp"`
		#			FTP_PASSWD_CHK_VALUE=`echo $FTP_PASSWD_RESULT | egrep -vc "^$"`
		#
		#				if [ $FTP_PASSWD_CHK_VALUE -eq 0 ]
		#				then
		#					Result="양호"
		#					echo "$PW_FILE 파일에 ftp 계정이 존재하지 않으므로 양호함" >> $RESULT_FILE 2>&1
		#				else
		#					Result="취약"
		#					echo "$PW_FILE 파일에 ftp 계정이 존재합니다." >> $RESULT_FILE 2>&1
		#				fi
		#		fi
			fi
			
			if [ -f /etc/passwd ]
				then
					echo "#cat /etc/passwd | grep ftp" >> $RESULT_TXT 2>&1
					cat /etc/passwd | grep ftp>> $RESULT_TXT 2>&1
					echo "#cat /etc/passwd" >> $REF_FILE 2>&1
					cat /etc/passwd >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/vsftpd/vsftpd.conf ]
				then
					echo "#cat /etc/vsftpd/vsftpd.conf | grep anonymous_enable" >> $RESULT_TXT 2>&1
					cat /etc/vsftpd/vsftpd.conf | grep "anonymous_enable" >> $RESULT_TXT 2>&1
					echo "#cat /etc/vsftpd/vsftpd.conf" >> $REF_FILE 2>&1
					cat /etc/vsftpd/vsftpd.conf >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/vsftpd.conf ]
				then
					echo "#cat /etc/vsftpd.conf | grep anonymous_enable" >> $RESULT_TXT 2>&1
					cat /etc/vsftpd.conf | grep "anonymous_enable" >> $RESULT_TXT 2>&1
					echo "#cat /etc/vsftpd.conf" >> $REF_FILE 2>&1
					cat /etc/vsftpd.conf >> $REF_FILE 2>&1
			fi
			
			echo " " >> $RESULT_TXT 2>&1
			Item_foot "$Result" "$Exp" "$Evi"
			
			echo " " >> $RESULT_TXT 2>&1
			echo "#ftp 설정 확인" >> $RESULT_TXT 2>&1
			echo "$FTP_CHK" >> $RESULT_TXT 2>&1
			
			unset FTP_TEST_RESULT
			unset CHK_VALUE
			unset FTP_PASSWD_RESULT
			unset FTP_PASSWD_CHK_VALUE
			unset FTP_MSG
			unset FTP_USERS_RESULT
			unset FTP_USERS_CHK_VALUE
			unset RESULT
			unset RESULT_CODE
		;;
		
		*)
		#
		;;
		
	esac
}

# r계열 서비스 비활성화
U_36_r_services() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="r 계열 서비스 비활성화"
	Item_head "U-36" "$iTitle" "$iCODE"
	
	case $OS_STR in
		Linux)
		#Linux:
			dir="/etc/xinetd.d"
			SERVICE="rsh|rlogin|rexec"
			
			if [ $R_SVR = "true" ]
				then
					Result="취약"
					Exp="현재 rsh, rlogin, rexec 서비스가 실행중이므로 취약함"
					Evi=`systemctl list-unit-files --type=service | egrep $SERVICE | egrep enabled`
				else
					Result="양호"
					Exp="현재 rsh, rlogin, rexec 서비스가 비실행 중이므로 양호함"
					Evi=""
			fi
			
			if [ -d $dir ]
				then
					echo "#ls -alL $dir | egrep $SERVICE" >> $RESULT_TXT 2>&1
					ls -alL $dir | egrep $SERVICE >> $RESULT_TXT 2>&1
					echo " " >> $RESULT_TXT 2>&1
					
					if [ -f $dir/rsh ]
						then
							echo "#cat $dir/rsh" >> $RESULT_TXT 2>&1				
							cat "$dir/rsh" | grep disable >> $RESULT_TXT 2>&1
							echo " " >> $RESULT_TXT 2>&1
					fi
					
					if [ -f $dir/rlogin ]
						then
							echo "#cat $dir/rlogin" >> $RESULT_TXT 2>&1
							cat "$dir/rlogin" | grep disable >> $RESULT_TXT 2>&1
							echo " " >> $RESULT_TXT 2>&1
					fi
					
					if [ -f $dir/rexec ]
						then
							echo "#cat $dir/rexec" >> $RESULT_TXT 2>&1
							cat "$dir/rexec" | grep disable >> $RESULT_TXT 2>&1
					fi
			fi
			
			unset SERVICE
			unset R_SVR
			unset dir
		;;
		AIX | HP-UX)
		#AIX HP-UX:
			SERVICE="rsh|rlogin|rexec"
			
			if [ $R_SVR = "true" ]
				then
					Result="취약"
					Exp="현재 rsh, rlogin, rexec 서비스가 실행중이므로 취약함"
					Evi=""
					
					if [ -f /etc/inetd.conf ]
						then
							Evi=`cat /etc/inetd.conf | egrep $SERVICE`
					fi
					
				else
					Result="양호"
					Exp="현재 rsh, rlogin, rexec 서비스가 비실행중이므로 양호함"
					Evi=`cat /etc/inetd.conf | egrep $SERVICE`
			fi
			
			if [ -d /etc/xinetd.d ]
				then
					echo "#ls -alL /etc/xinetd.d" >> $RESULT_TXT 2>&1
					ls -alL /etc/xinetd.d >> $RESULT_TXT 2>&1
			fi
			unset SERVICE
			unset R_SVR
		;;
		
		SunOS)
		#SunOS:
			SERVICE_INETD="shell|login|exec"
			if [ $SOL_VER_PART = "1" ]
				then
					if [ -f /etc/inetd.conf ]
						then
							CHK_TEXT=`cat /etc/inetd.conf | grep -v "^ *#" | egrep $SERVICE_INETD`
							CHK_REF=$CHK_TEXT
							CHK_REF1=`cat /etc/inetd.conf | egrep $SERVICE_INETD`
							CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
						else
							$CHK_VALUE=-1
					fi
				else
					CHK_REF=`inetadm | egrep $SERVICE_INETD`
					CHK_REF1=`inetadm | egrep $SERVICE_INETD`
					CHK_TEXT=`echo "$CHK_REF" | egrep "enabled"`
					CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
			fi
			
			if [ $CHK_VALUE -eq -1 ]
				then
					Result="수동점검"
					Exp="inetd.conf 파일이 존재하지 않음"
					Evi=""
				elif [ $CHK_VALUE -eq 0 ]
				then
					Result="양호"
					Exp="R 서비스가 비실행중이므로 양호함"
					Evi="$CHK_REF1"
				else
					Result="취약"
					Exp="R 현재 rsh, rlogin, rexec 서비스가 실행중이므로 취약함"
					Evi="$CHK_TEXT"
			fi
			
			if [ -f /etc/inetd.conf ]
				then
					echo " " >> $RESULT_TXT 2>&1
					echo "ls -alL /etc/inetd.conf" >> $RESULT_TXT 2>&1
					ls -alL /etc/inetd.conf >> $RESULT_TXT 2>&1
			fi
			
			if [ -f /etc/xinetd.conf ]
				then
					echo " " >> $RESULT_TXT 2>&1
					echo "#ls -alL /etc/xinetd.conf" >> $RESULT_TXT 2>&1
					ls -alL /etc/xinetd.conf >> $RESULT_TXT 2>&1
			fi
			
			
			unset SERVICE_INETD
			unset CHK_REF
			unset CHK_REF1
			unset CHK_TEXT
			unset CHK_VALUE
		;;
		
		*)
		#
		;;
		
	esac
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# crontab 설정파일 권한 설정 미흡
U_37_cron_permission() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="crontab 설정파일 권한 설정 미흡"
	Item_head "U-37" "$iTitle" "$iCODE"
	
	if [ $OS_STR = "SunOS" ]
		then
			# /usr/bin/crontab 추가 - 2021.04.22 (2021년도 주정통)
			# /usr/bin/at 추가 - 2026.02.26 (2026년도 주정통)
			TARGET_FILE="/usr/bin/crontab /etc/crontab /etc/cron.d/cron.allow /etc/cron.d/cron.deny /etc/cron.d/at.allow /etc/cron.d/at.deny /usr/bin/at"
		else
			# /var/adm/cron/cron.allow /var/adm/cron/cron.deny 누락부분 추가 - 2018.04.26 by yang
			# /etc/at.allow /etc/at.deny 누락부분 추가 - 2026.02.26
			# /usr/bin/at 추가 - 2026.02.26 (2026년도 주정통)
			TARGET_FILE="/usr/bin/crontab /etc/crontab /etc/cron.allow /etc/cron.deny /etc/at.allow /etc/at.deny /var/adm/cron/cron.allow /var/adm/cron/cron.deny /usr/bin/at"
	fi
	
		
    TMP=0
	
	
	for check_file in $TARGET_FILE
	do
		if [ -f $check_file ]
			then
				perm_check $check_file

				FILE_LIST="$FILE_LIST$check_file "
				
				if [ $uPn -gt 6 -o $gPn -gt 4 -o $oPn -gt 0 ]
					then
						REGUL_SET="$REGUL_SET$check_file "
				fi
				
				#crontab 체크 2021.04.22
				if [ $uPn -gt 7 -o $gPn -gt 5 -o $oPn -gt 0 ]
					then
						REGUL_SET2="$REGUL_SET$check_file "
				fi
				
				TMP=`expr $TMP + 1`
		fi
	done
	
	if [ $TMP -eq 0 ]
		then	 # TARGET_FILE이 없는 경우
			Result="양호"
			Exp="$TARGET_FILE 파일이 존재하지 않음"
			Evi=""
		else	 # TARGET_FILE이 있는 경우	
			if [ "$REGUL_SET" != "" ]
				then
					Result="수동점검"
					Exp="REF.txt, txt 파일 모두 참고하여 수동진단 실시"
					Evi=`ls -alL $REGUL_SET`
				else
					Result="수동점검"
					Exp="REF.txt, txt 파일 모두 참고하여 수동진단 실시"
					Evi=`ls -alL $FILE_LIST`
			fi
			
			if [ "$REGUL_SET2" != "" ]
				then
					Result="수동점검"
					Exp="REF.txt, txt 파일 모두 참고하여 수동진단 실시"
					Evi=`ls -alL $REGUL_SET2`
				else
					Result="수동점검"
					Exp="REF.txt, txt 파일 모두 참고하여 수동진단 실시"
					Evi=`ls -alL $FILE_LIST`
			fi
			
			
	fi
	
	if [ $OS_STR = "SunOS" ]
		then
			if [ -f /etc/cron.d/cron.allow ]
				then
					echo "1) cron 접근제어 파일(allow) 권한 및 내용" >> $REF_FILE 2>&1
					ls -alL /etc/cron.d/cron.allow >> $REF_FILE 2>&1
					cat /etc/cron.d/cron.allow >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/cron.d/cron.deny ]
				then
					echo "2) cron 접근제어 파일(deny) 권한 및 내용" >> $REF_FILE 2>&1
					ls -alL /etc/cron.d/cron.deny >> $REF_FILE 2>&1
					cat /etc/cron.d/cron.deny >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/cron.d/at.allow ]
				then
					echo "3) at 접근제어 파일(allow) 권한 및 내용" >> $REF_FILE 2>&1
					ls -alL /etc/cron.d/at.allow >> $REF_FILE 2>&1
					cat /etc/cron.d/at.allow >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/cron.d/at.deny ]
				then
					echo "4) at 접근제어 파일(deny) 권한 및 내용" >> $REF_FILE 2>&1
					ls -alL /etc/cron.d/at.deny >> $REF_FILE 2>&1
					cat /etc/cron.d/at.deny >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
			
			if [ -f /usr/bin/at ]
				then
					echo "5) at 명령어 권한" >> $REF_FILE 2>&1
					ls -alL /usr/bin/at >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
			
		else
			if [ -f /etc/cron.allow ]
				then
					echo "1) cron 접근제어 파일(allow) 권한 및 내용" >> $REF_FILE 2>&1
					ls -alL /etc/cron.allow >> $REF_FILE 2>&1
					cat /etc/cron.allow >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/cron.deny ]
				then
					echo "2) cron 접근제어 파일(deny) 권한 및 내용" >> $REF_FILE 2>&1
					ls -alL /etc/cron.deny >> $REF_FILE 2>&1
					cat /etc/cron.deny >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi			
			
			if [ -f /etc/at.allow ]
				then
					echo "3) at 접근제어 파일(allow) 권한 및 내용" >> $REF_FILE 2>&1
					ls -alL /etc/cron.deny >> $REF_FILE 2>&1
					cat /etc/cron.deny >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi	
			
			if [ -f /etc/at.deny ]
				then
					echo "4) at 접근제어 파일(deny) 권한 및 내용" >> $REF_FILE 2>&1
					ls -alL /etc/cron.deny >> $REF_FILE 2>&1
					cat /etc/cron.deny >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi	
			
			if [ -f /var/adm/cron/cron.allow ]
				then
					echo "#ls -alL /var/adm/cron/cron.allow" >> $REF_FILE 2>&1
					ls -alL /var/adm/cron/cron.allow >> $REF_FILE 2>&1
					cat /var/adm/cron/cron.allow >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
			
			if [ -f /var/adm/cron/cron.deny ]
				then
					echo "#ls -alL /var/adm/cron/cron.deny" >> $REF_FILE 2>&1
					ls -alL /var/adm/cron/cron.deny >> $REF_FILE 2>&1
					cat /var/adm/cron/cron.deny >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
			
			if [ -f /var/adm/cron/at.allow ]
				then
					echo "#ls -alL /var/adm/cron/at.allow" >> $REF_FILE 2>&1
					ls -alL /var/adm/cron/at.allow >> $REF_FILE 2>&1
					cat /var/adm/cron/at.allow >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
			
			if [ -f /var/adm/cron/at.deny ]
				then
					echo "#ls -alL /var/adm/cron/at.deny" >> $REF_FILE 2>&1
					ls -alL /var/adm/cron/at.deny >> $REF_FILE 2>&1
					cat /var/adm/cron/at.deny >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
			
			if [ -f /usr/bin/at ]
				then
					echo "5) at 명령어 권한" >> $REF_FILE 2>&1
					ls -alL /usr/bin/at >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
			
	fi
	
	#추가 - 2021.04.27 (2021년도 주정통)
	DIRECTORY_FILE="/var/spool/cron /var/spool/cron/crontabs /etc/cron.d/cron.hourly /etc/cron.d/cron.daily /etc/cron.d/cron.weekly /etc/cron.d/cron.monthly /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /var/adm/cron/cron.hourly /var/adm/cron/cron.daily /var/adm/cron/cron.weekly /var/adm/cron/cron.monthly"

	echo "6) cron 관련파일 목록 확인" >> $REF_FILE 2>&1
	for check_directory in $DIRECTORY_FILE
	do
		if [ -d $check_directory ]
			then
				echo $check_directory >> $REF_FILE 2>&1 
				ls -alL $check_directory >> $REF_FILE 2>&1
				echo " " >> $REF_FILE 2>&1
			else
				echo $check_directory "가 존재하지 않음" >> $REF_FILE 2>&1
		fi
	done
	
	
	
	Item_foot "$Result" "$Exp" "$Evi"
	
	unset DIRECTORY_FILE
    unset TARGET_FILE
    unset OWNER_PERM
    unset GROUP_PERM
    unset OTHER_PERM
    unset REGUL_SET
    unset FILE_LIST
	unset check_file
	unset TMP
}

# DoS 공격에 취약한 서비스 비활성화
U_38_dos() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="DoS 공격에 취약한 서비스 비활성화"
	Item_head "U-38" "$iTitle" "$iCODE"
	
	SERVICE="echo|discard|daytime|chargen"
	
	case $OS_STR in
		Linux)
		#Linux
			dir="/etc/xinetd.d"
			
		if [ `chkconfig --list | egrep $SERVICE | egrep on | wc -l` -eq 0 ]
			then
				#프로세스 동작 안함
				CHK_VALUE=0
			else
				#프로세스 동작 중
				CHK_VALUE=1
			fi
			
			if [ $CHK_VALUE -eq 1 ]
				then
					Result="취약"
					Exp="echo, discard, daytime, chargen 서비스가 실행중이므로 취약함"
					Evi=`chkconfig --list | egrep $SERVICE`
				else
					Result="양호"
					Exp="echo, discard, daytime, chargen 서비스가 비실행 중이므로 양호함"
					Evi=`chkconfig --list | egrep $SERVICE`
			fi
			
			if [ -f /etc/inetd.conf ]
				then
					echo "#cat /etc/inetd.conf" >> $REF_FILE 2>&1
					cat /etc/inetd.conf >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
			fi
			
			if [ -d /etc/xinetd.d ]
				then
					echo "#ls -alL $dir | egrep $SERVICE " >> $RESULT_TXT 2>&1
					ls $dir | egrep $SERVICE >> $RESULT_TXT 2>&1
					echo " " >> $RESULT_TXT 2>&1
					
					echo "#cat $dir/echo | grep disable " >> $RESULT_TXT 2>&1
					cat $dir/echo* 2>/dev/null | grep disable >> $RESULT_TXT 2>&1
					echo " " >> $RESULT_TXT 2>&1
					echo "#cat $dir/discard | grep disable " >> $RESULT_TXT 2>&1
					cat $dir/discard* 2>/dev/null | grep disable >> $RESULT_TXT 2>&1
					echo " " >> $RESULT_TXT 2>&1
					
					echo "#cat $dir/daytime | grep disable " >> $RESULT_TXT 2>&1
					cat $dir/daytime* 2>/dev/null | grep disable >> $RESULT_TXT 2>&1
					echo " " >> $RESULT_TXT 2>&1
					echo "#cat $dir/chargen | grep disable " >> $RESULT_TXT 2>&1
					cat $dir/chargen* 2>/dev/null | grep disable >> $RESULT_TXT 2>&1
			fi
			
			unset SERVICE
			unset CHK_VALUE
			unset dir
		;;
		
		AIX | HP-UX)
		#AIX HP-UX:
			if [ `cat /etc/inetd.conf | egrep $SERVICE | egrep -v "^#" | wc -l` -eq 0 ]
				then
					#프로세스 동작 안함
					CHK_VALUE=0
				else
					#프로세스 동작 중
					CHK_VALUE=1
			fi
			if [ $CHK_VALUE -eq 1 ]
				then
					Result="취약"
					Exp="echo, discard, daytime, chargen 서비스가 실행중이므로 취약함"
					Evi=""
					
					if [ -f /etc/inetd.conf ]
						then
							Evi=`cat /etc/inetd.conf | egrep $SERVICE`
					fi
					
				else
					Result="양호"
					Exp="echo, discard, daytime, chargen 서비스가 비실행 중이므로 양호함"
					Evi=`cat /etc/inetd.conf | egrep $SERVICE`
			fi
			
			unset SERVICE
			unset CHK_VALUE
		;;
		
		SunOS)
		#SunOS:
			if [ $SOL_VER_PART = "1" ]
				then
					if [ -f /etc/inetd.conf ]
						then
							CHK_TEXT=`cat /etc/inetd.conf | grep -v "^ *#" | egrep $SERVICE`
							CHK_REF=$CHK_TEXT
							CHK_REF1=`cat /etc/inetd.conf | egrep $SERVICE`
							CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
						else
							$CHK_VALUE=-1
					fi
				else
					CHK_REF=`inetadm | egrep $SERVICE`
					CHK_REF1=`inetadm | egrep $SERVICE`
					CHK_TEXT=`echo "$CHK_REF" | egrep "enabled"`
					CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
			fi
			if [ $CHK_VALUE -eq -1 ]
				then
					Result="수동점검"
					Exp="inetd.conf 파일이 존재하지 않음"
					Evi=""
				elif [ $CHK_VALUE -eq 0 ]
				then
					Result="양호"
					Exp="echo, discard, daytime, chargen 서비스가 비실행 중이므로 양호함"
					Evi="$CHK_REF1"
				else
					Result="취약"
					Exp="echo, discard, daytime, chargen 서비스가 실행중이므로 취약함"
					Evi="$CHK_TEXT"
			fi
			
			if [ -f /etc/inetd.conf ]
				then
					echo "#cat /etc/inetd.conf" >> $REF_FILE 2>&1
					cat /etc/inetd.conf | egrep $SERVICE >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/xinetd.conf ]
				then
					echo "#cat /etc/xinetd.conf" >> $REF_FILE 2>&1
					cat /etc/xinetd.conf | egrep $SERVICE >> $REF_FILE 2>&1
			fi
			
			unset SERVICE
			unset CHK_REF
			unset CHK_REF1
			unset CHK_TEXT
			unset CHK_VALUE
		;;
		
		*)
		#
		;;
		
	esac
	
	echo " " >> $RESULT_TXT 2>&1	
	Item_foot "$Result" "$Exp" "$Evi"
}

# 불필요한 NFS 서비스 비활성화
U_39_nfs() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="불필요한 NFS 서비스 비활성화"
	Item_head "U-39" "$iTitle" "$iCODE"
	
	SERVICE="mountd|nfs"
	
	case $OS_STR in
		Linux | AIX | HP-UX)
		#Linux AIX HP-UX:
			dir="/etc/xinetd.d"			
			if [ `ps -ef | egrep "mountd|nfs" | egrep -v "grep" | wc -l` -eq 0 ]
				then
					#프로세스 동작 안함
					CHK_VALUE=0
				else
					#프로세스 동작 중
					CHK_VALUE=1
			fi
			if [ $CHK_VALUE -eq 1 ]
				then
					Result="수동점검"
					Exp="현재 NFS 서비스가 실행중이므로 사용여부 확인 필요"
					Evi=""
					
					#AIX, HP-UX
					if [ -f /etc/inetd.conf ]
						then
							Evi=""
					fi
					
					#Linux
					if [ -f $dir/nfs ]
						then
							Evi=""
					fi
					
					NFS_SVR="true"
					
				else
					Result="양호"
					Exp="현재 NFS 서비스가 비실행중이므로 양호함"
					Evi=""
			fi
			
			ps -ef | egrep "mountd|nfs" >> $RESULT_TXT 2>&1
			#AIX, HP-UX
			if [ -f /etc/inetd.conf ]
			then
				echo "#cat /etc/inetd.conf | egrep $SERVICE" >> $RESULT_TXT 2>&1
				echo " " >> $RESULT_TXT 2>&1
				cat /etc/inetd.conf | egrep "mountd|nfs" >> $RESULT_TXT 2>&1
			fi
	
			#Linux
			if [ -f $dir/nfs ]
			then
				echo "#cat $dir/nfs" >> $RESULT_TXT 2>&1
				echo " " >> $RESULT_TXT 2>&1
				cat "$dir/nfs" >> $RESULT_TXT 2>&1
			fi
			
			unset SERVICE
			unset dir
			unset CHK_VALUE
		;;
		
		SunOS)
		#SunOS:
			if [ $SOL_VER_PART = "1" ]
				then
					if [ -f /etc/inetd.conf ]
						then
						CHK_TEXT=`cat /etc/inetd.conf | grep -v "^ *#" | egrep $SERVICE`
						CHK_REF=$CHK_TEXT
						CHK_REF1=`cat /etc/inetd.conf | egrep $SERVICE`
						CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
					else
						$CHK_VALUE=-1
					fi
				else
					CHK_REF=`inetadm | egrep $SERVICE`
					CHK_REF1=`inetadm | egrep $SERVICE`
					CHK_TEXT=`echo "$CHK_REF" | egrep "enabled"`
					CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
			fi
			
			if [ $CHK_VALUE -eq -1 ]
				then
					Result="수동점검"
					Exp="inetd.conf 파일이 존재하지 않음"
					Evi=""
				elif [ $CHK_VALUE -eq 0 ]
				then
					Result="양호"
					Exp="NFS 서비스가 비실행중이므로 양호함"
					Evi="$CHK_REF1"
				else
					Result="수동점검"
					Exp="NFS 서비스가 실행중이므로 필요한 서비스인지 확인 필요"
					Evi="$CHK_TEXT"

					NFS_SVR="true"
				
			fi
			
			echo "#ps -ef | egrep $SERVICE | grep -v grep" >> $RESULT_TXT 2>&1
			ps -ef | egrep "mountd|nfs" | grep -v "grep" >> $RESULT_TXT 2>&1
			
			unset SERVICE
			unset CHK_REF
			unset CHK_TEXT
			unset CHK_VALUE
		;;
		
		*)
		#
		;;
		
	esac
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# NFS 접근 통제
U_40_nfs_dfstab() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="NFS 접근 통제"
	Item_head "U-40" "$iTitle" "$iCODE"
	
	if [ $NFS_SVR != "true" ]
		then
			Result="양호"
			Exp="NFS 서비스가 비실행중이므로 양호함"
			Evi="#ps -ef | egrep mountd|nfs 결과 확인"
		else
			Result="수동점검"
			Exp="결과 참고하여 수동진단"
			Evi=`ps -ef | egrep "mountd|nfs" | grep -v "grep"`
	fi
		
	if [ -f /etc/dfs/dfstab ]
		then
			echo "#cat /etc/dfs/dfstab" >> $RESULT_TXT 2>&1
			cat /etc/dfs/dfstab >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
	fi
	
	if [ -f /etc/exports ]
		then
			echo "#cat /etc/exports" >> $RESULT_TXT 2>&1
			cat /etc/exports >> $RESULT_TXT 2>&1
	fi
	
	#HP-UX
	if [ -f /etc/dfs/sharetab ]
		then
			echo "#cat /etc/dfs/sharetab" >> $RESULT_TXT 2>&1
			cat /etc/dfs/sharetab >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
	fi
	
	if [ -f /etc/vfstab ]
		then
			echo "#cat /etc/vfstab" >> $RESULT_TXT 2>&1
			cat /etc/vfstab >> $RESULT_TXT 2>&1
	fi
	
	case $OS_STR in
		Linux)
		#Linux:
			FILE="/etc/dfs/dfstab /etc/export"
		;;
		
		SunOS)
		#SunOS:
			FILE="/etc/dfs/dfstab /etc/vfstab"
		;;
		
		AIX)
		#AIX:
			FILE="/etc/exports"
		;;
		
		HP-UX)
		#HP-UX:
			FILE="/etc/dfs/dfstab /etc/dfs/sharetab"
		;;
		*)
		;;
	esac
	
	TMP=0
	for check_file in $FILE
		do
		if [ -f $check_file ]
		then
			perm_check $check_file

			FILE_LIST="$FILE_LIST$check_file "
			
			if [ $uPn -gt 6 -o $gPn -gt 0 -o $oPn -gt 0 ]
				then
					PERM_RESULT="$PERM_RESULT$check_file "
			fi
			
			TMP=`expr $TMP + 1`			
		fi
	done
	if [ $NFS_SVR = "true" ]
		then
			if [ $TMP -eq 0 ]
				then
					Result="양호"
					Exp="NFS 서비스가 실행중이나 NFS 명령어 관련 설정파일이 존재하지 않으므로 양호함"
					Evi="ls -alL $FILE 결과 확인"
				else
					if [ "$PERM_RESULT" != "" ]
						then
							Result="취약"
							Exp="NFS 명령어 관련 설정파일의 권한이 과도하게 설정되어 있으므로 취약함"
							Evi=`ls -alL $PERM_RESULT`
						else
							Result="양호"
							Exp="NFS 명령어 관련 설정파일의 권한이 적절하게 설정되어 있으므로 양호함"
							Evi=`ls -alL $PERM_RESULT`
					fi
			fi
		else
			Result="양호"
			Exp="NFS 서비스가 비실행중이므로 양호함"
			Evi="#ps -ef | egrep mountd|nfs 결과 확인"
	fi
			
	if [ -f /etc/dfs/dfstab ]
		then
			echo "#ls -al /etc/dfs/dfstab" >> $RESULT_TXT 2>&1
			ls -al /etc/dfs/dfstab >> $RESULT_TXT 2>&1
	fi
	
	if [ -f /etc/exports ]
		then
			echo "#ls -al /etc/exports" >> $RESULT_TXT 2>&1
			ls -al /etc/exports >> $RESULT_TXT 2>&1
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
	
	unset FILE
    unset OWNER_PERM
    unset GROUP_PERM
    unset OTHER_PERM
    unset PERM_RESULT
    unset FILE_LIST
}

# 불필요한 automountd 제거
U_41_automountd() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="불필요한 automountd 제거"
	Item_head "U-41" "$iTitle" "$iCODE"
	
	if [ `ps -ef | grep automountd | egrep -v "grep|rpc|statdaemon|emi" | wc -l` -eq 0 ]
	  then
		Result="양호"
		Exp="automount 데몬이 없으므로 양호함"
		Evi=""
	  else
	  	Result="취약"
		Exp="automount 데몬이 실행중이므로 취약함"
		Evi=`ps -ef | grep automountd | egrep -v "grep|rpc|statdaemon|emi"`
	fi
	
	#SunOS
	if [ $OS_STR = "SunOS" ]
	then
		if [ $SOL_VER_PART = "1" ]
			then
				echo "svcs -a | egrep  autofs" >> $RESULT_TXT 2>&1
				svcs -a | egrep "autofs" >> $RESULT_TXT 2>&1
		fi
	fi
	echo " " >> $RESULT_TXT 2>&1	
	Item_foot "$Result" "$Exp" "$Evi"
}

# 불필요한 RPC 서비스 비활성화
U_42_rpc() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="불필요한 RPC 서비스 비활성화"
	Item_head "U-42" "$iTitle" "$iCODE"
	
	case $OS_STR in
		Linux | AIX | HP-UX)
		#Linux AIX HP-UX:
			SERVICE="rpc.cmsd|rpc.ttdbserverd|rpc.rusersd|sadmind|rusersd|walld|sprayd|rstatd|rpc.nisd|rpc.pcnfsd|rpc.statd|rpc.ypupdated|rpc.rquotad|kcms_server|cachefsd|rexd|rpc.rwalld"
			if [ $OS_STR = "Linux" ]
				then
					SERVICE="rpc.cmsd|rpc.ttdbserverd|sadmind|rusersd|walld|sprayd|rstatd|rpc.nisd|rpc.pcnfsd|rpc.statd|rpc.ypupdated|rpc.rquotad|kcms_server|cachefsd|rexd"
			fi
	
			if [ `ps -ef | egrep $SERVICE | egrep -v "grep" | egrep -v "firewalld" | wc -l` -eq 0 ]
				then
					#프로세스 동작 안함
					CHK_VALUE=0
				else
					#프로세스 동작 중
					echo "ps -ef | egrep $SERVICE | egrep -v grep | egrep -v firewalld" >> $RESULT_TXT 2>&1
					ps -ef | egrep $SERVICE | egrep -v "grep" | egrep -v "firewalld" >> $RESULT_TXT 2>&1
					CHK_VALUE=1
			fi
			
			if [ $CHK_VALUE -eq 1 ]
				then
					Result="수동점검"
					Exp="현재 RPC 서비스가 실행중이므로 사용여부 확인필요"
					Evi=""
					
				else
					Result="양호"
					Exp="현재 RPC 서비스가 비실행중이므로 양호함"
					Evi="$SERVICE 서비스 확인"
			fi
			
			if [ -f /etc/inetd.conf ]
				then
					Evi_tmp1=`ps -ef | egrep $SERVICE | egrep -v 'grep'`
					Evi_tmp2=`cat /etc/inetd.conf | egrep $SERVICE`
					Evi="$Evi_tmp1 
							
$Evi_tmp2"
			fi
					
			if [ -d /etc/xinetd.d ]
				then
					Evi_tmp1=`ps -ef | egrep $SERVICE | egrep -v 'grep'`
					Evi_tmp2=`find /etc/xinetd.d -name "*" -type f -exec grep -H "disable" {} \;`
					Evi="$Evi_tmp1

$Evi_tmp2"
			fi
			unset SERVICE
			unset CHK_VALUE
			unset Evi_tmp1
			unset Evi_tmp2
		;;
		
		SunOS)
		#SunOS:
			if [ $SOL_VER_PART = "1" ]
				then
					SERVICE="rpc.cms|rpc.ttdbserver|sadmin|rusers|wall|spray|rstat|rpc.nis|rpc.pcnfs|rpc.stat|rpc.ypupdate|rpc.rquota|kcms_server|cachefs|rex"
					
					if [ -f /etc/inetd.conf ]
						then
							CHK_TEXT=`cat /etc/inetd.conf | grep -v "^ *#" | egrep $SERVICE`
							CHK_REF=$CHK_TEXT
							CHK_REF1=`cat /etc/inetd.conf | egrep $SERVICE`
							CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
						else
							$CHK_VALUE=-1
					fi
					
				else
					SERVICE="ttdbserver|rex|rstat|rusers|spray|wall|rquota"
					
					CHK_REF=`inetadm | egrep $SERVICE`
					CHK_REF1=`inetadm | egrep $SERVICE`
					CHK_TEXT=`echo "$CHK_REF" | egrep "enabled"`
					CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`

			fi
			if [ $CHK_VALUE -eq -1 ]
				then
					Result="수동점검"
					Exp="inetd.conf 파일이 존재하지 않음"
					Evi=""
				elif [ $CHK_VALUE -eq 0 ]
				then
					Result="양호"
					Exp="불필요한 RPC 서비스가 존재하지 않으므로 양호함"
					Evi="$CHK_REF1"
				else
					Result="취약"
					Exp="불필요한 RPC 서비스가 존재하므로 취약함"
					Evi="$CHK_REF1"

					NFS_SVR="true"
			fi
			
			echo "" >> $RESULT_TXT 2>&1
			echo "$SERVICE 서비스 확인" >> $RESULT_TXT 2>&1
			echo "" >> $RESULT_TXT 2>&1
			
			if [ -f /etc/inetd.conf ]
				then
					echo "#cat /etc/inetd.conf" >> $REF_FILE 2>&1
					cat /etc/inetd.conf | egrep $SERVICE >> $REF_FILE 2>&1
			fi
			
			if [ -d /etc/xinetd.d ]
				then
					echo "#la -al /etc/xinetd.d" >> $REF_FILE 2>&1
					ls -al /etc/xinetd.d >> $REF_FILE 2>&1
			fi
			
			unset SERVICE
			unset CHK_REF
			unset CHK_REF1
			unset CHK_TEXT
			unset CHK_VALUE
		;;
		
		*)
		#
		;;
		
	esac
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# NIS, NIS+ 점검
U_43_nis() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="NIS, NIS+ 점검"
	Item_head "U-43" "$iTitle" "$iCODE"
	
	dir="/etc/xinetd.d"
	SERVICE="ypserv|ypbind|ypxfrd|rpc.yppasswdd|rpc.ypupdated"
	
	if [ $OS_STR = "HP-UX" ]
		then
			SERVICE="nis|rpc.nisd|ypserv|ypbind|ypxfrd|rpc.yppasswdd|rpc.ypupdated"
		fi
	
	case $OS_STR in
		Linux | AIX | HP-UX)
		#Linux AIX HP-UX:
			if [ `ps -ef | egrep $SERVICE | egrep -v "grep" | wc -l` -eq 0 ]
				then
					#프로세스 동작 안함
					CHK_VALUE=0
				else
					#프로세스 동작 중
					CHK_VALUE=1
			fi
			
			if [ $CHK_VALUE -eq 1 ]
				then
					Result="취약"
					Exp="현재 NIS , NIS+ 서비스가 실행중이므로 취약함"
					Evi=""
					
					#AIX, HP-UX
					if [ $OS_STR = "AIX" | $OS_STR = "HP-UX" ]
						then
							Evi=`cat /etc/inetd.conf | egrep $SERVICE`
					fi
				else
					Result="양호"
					Exp="현재 NIS , NIS+ 서비스가 비실행중이므로 양호함"
					Evi=""
			fi
			
			echo "#ps -ef | egrep $SERVICE" >> $RESULT_TXT 2>&1
			ps -ef | egrep $SERVICE | grep -v "grep" >> $RESULT_TXT 2>&1
			
			if [ -f /etc/inetd.conf ]
				then
					echo "#cat /etc/inetd.conf" >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
					cat /etc/inetd.conf | grep -v "^##" >> $REF_FILE 2>&1
			fi	
			
			if [ -d $dir ]
				then
					echo "#ls -al /etc/xinetd.d" >> $REF_FILE 2>&1
					ls -al /etc/xinetd.d>> $REF_FILE 2>&1
					
					#Linux
					if [ -f $dir/ypserv ]
						then
							echo "#cat $dir/ypserv" >> $REF_FILE 2>&1
							echo " " >> $REF_FILE 2>&1
							cat "$dir/ypserv" >> $REF_FILE 2>&1
					fi
					
					if [ -f $dir/ypbind ]
						then
							echo "#cat $dir/ypbind" >> $REF_FILE 2>&1
							echo " " >> $REF_FILE 2>&1
							cat "$dir/ypbind" >> $REF_FILE 2>&1
					fi
					
					if [ -f $dir/ypxfrd ]
						then
							echo "#cat $dir/ypxfrd" >> $REF_FILE 2>&1
							echo " " >> $REF_FILE 2>&1
							cat "$dir/ypxfrd" >> $REF_FILE 2>&1
					fi
					
					if [ -f $dir/rpc.yppasswdd ]
						then
							echo "#cat $dir/rpc.yppasswdd" >> $REF_FILE 2>&1
							echo " " >> $REF_FILE 2>&1
							cat "$dir/rpc.yppasswdd" >> $REF_FILE 2>&1
					fi
					
					if [ -f $dir/rpc.ypupdated ]
						then
							echo "#cat $dir/rpc.ypupdated" >> $REF_FILE 2>&1
							echo " " >> $REF_FILE 2>&1
							cat "$dir/rpc.ypupdated" >> $REF_FILE 2>&1
					fi
					
					if [ -f $dir/rpc.nisd ]
						then
							echo "#cat $dir/rpc.nisd" >> $REF_FILE 2>&1
							echo " " >> $REF_FILE 2>&1
							cat "$dir/rpc.nisd" >> $REF_FILE 2>&1
					fi
			fi			
		;;
		
		SunOS)
		#SunOS:
			if [ $SOL_VER_PART = "1" ]
				then				
					CHK_TEXT=`ps -ef | grep -v "grep" | egrep $SERVICE`
					CHK_REF=$CHK_TEXT
					CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
				else
					SERVICE="nis"
					
					CHK_REF=`svcs -a | egrep $SERVICE`
					CHK_TEXT=`echo "$CHK_REF" | egrep "online"`
					CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
			fi
			
			if [ $CHK_VALUE -eq -1 ]
				then
					Result="수동점검"
					Exp="inetd.conf 파일이 존재하지 않아 수동점검"
					Evi=""
				elif [ $CHK_VALUE -eq 0 ]
				then
					Result="양호"
					Exp="NIS, NIS+ 서비스가 비실행중이므로 양호함"
					Evi="$CHK_REF"
				else
					Result="취약"
					Exp="NIS, NIS+ 서비스가 실행중이므로 취약함"
					Evi="$CHK_REF"
			fi
			
			echo "#ps -ef" >> $RESULT_TXT 2>&1
			ps -ef | egrep $SERVICE | grep -v "grep" >> $RESULT_TXT 2>&1
		;;
		
		*)
		#
		;;
		
	esac
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
	unset SERVICE
	unset dir
	unset CHK_VALUE
}

# tftp, talk, ntalk 서비스 비활성화
U_44_tftp_talk() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="tftp, talk, ntalk 서비스 비활성화"
	Item_head "U-44" "$iTitle" "$iCODE"
	SERVICE="tftp|talk|ntalk"
	dir="/etc/xinetd.d"
	case $OS_STR in
		Linux)
		#Linux:
			if [ `chkconfig --list | egrep $SERVICE | egrep on | wc -l` -eq 0 ]
			then
				#프로세스 동작 안함
				CHK_VALUE=0
			else
				#프로세스 동작 중
				CHK_VALUE=1
			fi
			
			if [ `systemctl list-unit-files --type=service | egrep $SERVICE | egrep enabled | wc -l` -eq 0 ]
			then
				#프로세스 동작 안함
				CHK_VALUE=0
			else
				#프로세스 동작 중
				CHK_VALUE=1
			fi
			
			if [ $CHK_VALUE -eq 1 ]
				then
					Result="취약"
					Exp="현재 tftp, talk, ntalk 서비스가 실행중이므로 취약함"
					Evi=`systemctl list-unit-files --type=service | egrep tftp|talk|ntalk`


				else
					Result="양호"
					Exp="현재 tftp, talk, ntalk 서비스가 비실행중이므로 양호함"
					Evi=""
			fi
			
			#Linux
			if [ -f $dir/tftp ]
				then
					Evi=`cat "$dir/tftp" | grep disable`
			fi
					
			if [ -f $dir/talk ]
				then
					Evi=`cat "$dir/talk" | grep disable`
			fi
					
			if [ -f $dir/ntalk ]
				then
					Evi=`cat "$dir/ntalk" | grep disable`
			fi
					
			echo "#chkconfig --list | egrep tftp|talk|ntalk" >> $RESULT_TXT 2>&1
			chkconfig --list | egrep $SERVICE >> $RESULT_TXT 2>&1
			echo "#systemctl list-unit-files --type=service | egrep tftp|talk|ntalk" >> $RESULT_TXT 2>&1
			systemctl list-unit-files --type=service | egrep $SERVICE >> $RESULT_TXT 2>&1
			
			if [ -d /etc/xinetd.d ]
				then
					echo "#ls -al /etc/xinetd.d | egrep tftp|talk|ntalk" >> $REF_FILE 2>&1
					ls -al /etc/xinetd.d | egrep $SERVICE >> $REF_FILE 2>&1
			fi
			
			unset SERVICE
			unset dir
			unset CHK_VALUE
		;;
		
		AIX | HP-UX)
		#AIX HP-UX:
		
			if [ `cat /etc/inetd.conf | egrep $SERVICE | egrep -v "^#" | wc -l` -eq 0 ]
			then
				#프로세스 동작 안함
				CHK_VALUE=0
			else
				#프로세스 동작 중
				CHK_VALUE=1
			fi
			if [ $CHK_VALUE -eq 1 ]
				then
					Result="취약"
					Exp="현재 tftp, talk, ntalk 서비스가 실행중이므로 취약함"
					Evi=""
				else
					Result="양호"
					Exp="현재 tftp, talk, ntalk 서비스가 비실행중이므로 양호함"
					Evi=`cat /etc/inetd.conf | egrep $SERVICE`
			fi
			
			#AIX, HP-UX
			if [ -f /etc/inetd.conf ]
				then
					Evi=`cat /etc/inetd.conf | egrep $SERVICE`
			fi
					
			unset SERVICE
			unset dir
			unset CHK_VALUE
		;;
		
	
		SunOS)
		#SunOS:
			if [ $SOL_VER_PART = "1" ]
				then
					if [ -f /etc/inetd.conf ]
						then
							CHK_TEXT=`cat /etc/inetd.conf | grep -v "^ *#" | egrep $SERVICE`
							CHK_REF=$CHK_TEXT
							CHK_REF1=`cat /etc/inetd.conf | egrep $SERVICE`
							CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
						else
							$CHK_VALUE=-1
					fi
				else
					CHK_REF=`inetadm | egrep $SERVICE`
					CHK_REF1=`inetadm | egrep $SERVICE`
					CHK_TEXT=`echo "$CHK_REF" | egrep "enabled"`
					CHK_VALUE=`echo $CHK_TEXT | egrep -vc "^$"`
			fi
			
			if [ $CHK_VALUE -eq -1 ]
				then
					Result="수동점검"
					Exp="inetd.conf 파일이 존재하지 않음"
					Evi=""
				elif [ $CHK_VALUE -eq 0 ]
				then
					Result="양호"
					Exp="tftp, talk, ntalk 등의 서비스가 비실행중이므로 양호함"
					Evi="$CHK_REF1"
				else
					Result="취약"
					Exp="tftp, talk, ntalk 등의 서비스가 실행중이므로 취약함"
					Evi="$CHK_REF1"
			fi
			
			
			unset SERVICE
			unset CHK_REF
			unset CHK_REF1
			unset CHK_TEXT
			unset CHK_VALUE
		;;
		
		*)
		#
		;;
		
	esac
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 메일 서비스 버전 점검
U_45_mail_service_ver() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="메일 서비스 버전 점검"
	Item_head "U-45" "$iTitle" "$iCODE"
	
	if [ `ps -ef | grep "sendmail|postfix|exim" | grep -v "grep" | wc -l` -eq 0 ]
		then
			Result="양호"
			Exp="메일 서비스가 비실행중이므로 양호함"
			Evi=""

			touch sendmail_tmp
		else
			Result="수동점검"
			Exp="메일 사용여부 확인 필요"
			Evi=`ps -ef | grep "sendmail|postfix|exim" | grep -v "grep"`
	fi
	
	if [ -f sendmail_tmp ]
		then
			echo " "	>> $RESULT_TXT 2>&1
		else
			if [ -f /etc/mail/sendmail.cf ]
				then
					grep -v '^ *#' /etc/mail/sendmail.cf | grep DZ >> send.txt
					echo "sendmail의 버젼" >> $RESULT_TXT 2>&1
					cat send.txt >> $RESULT_TXT 2>&1
					echo "" >> $RESULT_TXT 2>&1
					echo "$REF_FILE 파일 참조" >> $RESULT_TXT 2>&1
				else
					echo "/etc/mail/sendmail.cf 파일 없음" >> send.txt
			fi
	fi
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
	if [ -f send.txt ]
		then
			rm -rf send.txt
	fi
}

# 일반 사용자의 메일 서비스 실행 방지
U_46_mail_restrictqrun() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="일반 사용자의 메일 서비스 실행 방지"
	Item_head "U-46" "$iTitle" "$iCODE"
	
	if [ -f sendmail_tmp ]
		then
			Result="양호"
			Exp="메일 서비스가 비실행중이므로 양호함"
			Evi=""
		else
			case $OS_STR in
				Linux | HP-UX | SunOS)
				#Linux HP-UX SunOS
					if [ -f /etc/mail/sendmail.cf ]
						then
							if [ `cat /etc/mail/sendmail.cf | grep -v "^ *#" | egrep -i "restrictqrun" | grep -v "grep" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="일반사용자의 Sendmail 실행 방지 설정(restrictqrun)이 되어 있으므로 양호함"
									Evi=`cat /etc/mail/sendmail.cf | egrep -i "restrictqrun"`
								else
									Result="취약"
									Exp="일반사용자의 Sendmail 실행 방지 설정(restrictqrun)이 되어 있지 않으므로 취약함"
									Evi=`cat /etc/mail/sendmail.cf | egrep -i "PrivacyOptions"`
							fi
						else
							Result="수동점검"
							Exp="/etc/mail/sendmail.cf 파일 없음"
							Evi=""
					fi
					if [ -f /usr/sbin/postsuper ]
						then
							Result="수동점검"
							Exp="/usr/sbin/postsuper 파일의 일반 사용자 실행 권한 확인"
							Evi=`ls -alL /usr/sbin/postsuper`
						else
							Result="양호"
							Exp="/usr/sbin/postsuper 파일 없음"
							Evi=""
					fi
					if [ -f /usr/sbin/exiqgrep ]
						then
							Result="수동점검"
							Exp="/usr/sbin/exiqgrep 파일의 일반 사용자 실행 권한 확인"
							Evi=`ls -alL /usr/sbin/exiqgrep`
						else
							Result="양호"
							Exp="/usr/sbin/exiqgrep 파일 없음"
							Evi=""
					fi
				;;
		
				AIX)
				#AIX
					if [ -f /etc/mail/sendmail.cf ]
						then
							if [ `cat /etc/mail/sendmail.cf | grep -v "^ *#" | egrep -i "restrictqrun" | grep -v "grep" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="일반사용자의 Sendmail 실행 방지 설정(restrictqrun)이 되어 있으므로 양호함"
									Evi=`cat /etc/mail/sendmail.cf | egrep -i "restrictqrun" | grep -v "grep"`
								else
									Result="취약"
									Exp="일반사용자의 Sendmail 실행 방지 설정(restrictqrun)이 되어 있지 않으므로 취약함"
									Evi=`cat /etc/mail/sendmail.cf | egrep -i "PrivacyOptions"`
							fi
						elif [ -f /etc/sendmail.cf ]
							then
								if [ `cat /etc/sendmail.cf | grep -v "^ *#" | egrep -i "restrictqrun" | grep -v "grep" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="일반사용자의 Sendmail 실행 방지 설정(restrictqrun)이 되어 있으므로 양호함"
									Evi=`cat /etc/sendmail.cf | egrep -i "restrictqrun" | grep -v "grep"`
								else
									Result="취약"
									Exp="일반사용자의 Sendmail 실행 방지 설정(restrictqrun)이 되어 있지 않으므로 취약함"
									Evi=`cat /etc/sendmail.cf | egrep -i "PrivacyOptions"`
								fi
					
						else
							Result="수동점검"
							Exp="/etc/mail/sendmail.cf 파일 없음"
							Evi=""
					fi
					if [ -f /usr/sbin/postsuper ]
						then
							Result="수동점검"
							Exp="/usr/sbin/postsuper 파일의 일반 사용자 실행 권한 확인"
							Evi=`ls -alL /usr/sbin/postsuper`
						else
							Result="양호"
							Exp="/usr/sbin/postsuper 파일 없음"
							Evi=""
					fi
					if [ -f /usr/sbin/exiqgrep ]
						then
							Result="수동점검"
							Exp="/usr/sbin/exiqgrep 파일의 일반 사용자 실행 권한 확인"
							Evi=`ls -alL /usr/sbin/exiqgrep`
						else
							Result="양호"
							Exp="/usr/sbin/exiqgrep 파일 없음"
							Evi=""
					fi
				;;
		
			esac	
			
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 스팸 메일 릴레이 제한
U_47_spam_mail_relay_reject() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="스팸 메일 릴레이 제한"
	Item_head "U-47" "$iTitle" "$iCODE"
	if [ -f sendmail_tmp ]
		then
			Result="양호"
			Exp="메일 서비스가 비실행중이므로 양호함"
			Evi=""
		else
			case $OS_STR in
				Linux | HP-UX | SunOS)
				#Linux HP-UX SunOS
					if [ -f /etc/mail/sendmail.cf ]
						then
							if [ `cat /etc/mail/sendmail.cf | grep -v "^#" | grep "^R\$\*" | grep -i "Relaying denied" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="스펨 메일 릴레이 제한(Relaying denied)이 설정되어 있으므로 양호함"
									Evi=`cat /etc/mail/sendmail.cf | grep "^R\$\*" | grep -i "Relaying denied"`
								else
									Result="취약"
									Exp="스펨 메일 릴레이 제한(Relaying denied)이 설정되어 있지 않으므로 취약함"
									Evi=`cat /etc/mail/sendmail.cf | grep "^R\$\*" | grep -i "Relaying denied"`
							fi
						else
							Result="수동점검"
							Exp="/etc/mail/sendmail.cf 파일 없음"
							Evi=""
					fi
					
					if [ -f /etc/postfix/main.cf ]
						then
							if [ `cat /etc/postfix/main.cf | grep -E "smtpd_recipient_restrictions" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="스펨 메일 릴레이 제한(Relaying denied)이 설정되어 있으므로 양호함"
									Evi=`cat /etc/postfix/main.cf | grep -E "smtpd_recipient_restrictions"`
								else
									Result="취약"
									Exp="스펨 메일 릴레이 제한(Relaying denied)이 설정되어 있지 않으므로 취약함"
									Evi=`cat /etc/postfix/main.cf | grep -E "smtpd_recipient_restrictions"`
							fi
						else
							Result="수동점검"
							Exp="/etc/postfix/main.cf 파일 없음"
							Evi=""
					fi
					
					if [ -f /etc/exim/exim.conf ]
						then
							if [ `cat /etc/exim/exim.conf | grep -E "relay_from_hosts" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="스펨 메일 릴레이 제한(Relaying denied)이 설정되어 있으므로 양호함"
									Evi=`cat /etc/exim/exim.conf | grep -E "relay_from_hosts"`
								else
									Result="취약"
									Exp="스펨 메일 릴레이 제한(Relaying denied)이 설정되어 있지 않으므로 취약함"
									Evi=`cat /etc/exim/exim.conf | grep -E "relay_from_hosts"`
							fi
						else
							Result="수동점검"
							Exp="/etc/exim/exim.conf 파일 없음"
							Evi=""
					fi
					
					if [ -f /etc/exim4/exim4.conf ]
						then
							if [ `cat /etc/exim4/exim4.conf | grep -E "relay_from_hosts" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="스펨 메일 릴레이 제한(Relaying denied)이 설정되어 있으므로 양호함"
									Evi=`cat /etc/exim4/exim4.conf | grep -E "relay_from_hosts"`
								else
									Result="취약"
									Exp="스펨 메일 릴레이 제한(Relaying denied)이 설정되어 있지 않으므로 취약함"
									Evi=`cat /etc/exim4/exim4.conf | grep -E "relay_from_hosts"`
							fi
						else
							Result="수동점검"
							Exp="/etc/exim4/exim4.conf 파일 없음"
							Evi=""
					fi
				;;
		
				AIX)
				#AIX
					if [ -f /etc/mail/sendmail.cf ]
						then
							if [ `cat /etc/mail/sendmail.cf | grep -v "^#" | grep "^R\$\*" | grep -i "Relaying denied" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="스펨 메일 릴레이 제한(Relaying denied)이 설정되어 있으므로 양호함"
									Evi=`cat /etc/mail/sendmail.cf | grep "^R\$\*" | grep -i "Relaying denied"`
								else
									Result="취약"
									Exp="스펨 메일 릴레이 제한(Relaying denied)이 설정되어 있지 않으므로 취약함"
									Evi=`cat /etc/mail/sendmail.cf | grep "^R\$\*" | grep -i "Relaying denied"`
							fi
						elif [ -f /etc/sendmail.cf ]
							then
								if [ `cat /etc/sendmail.cf | grep -v "^#" | grep "^R\$\*" | grep -i "Relaying denied" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="스펨 메일 릴레이 제한(Relaying denied)이 설정되어 있으므로 양호함"
									Evi=`cat /etc/sendmail.cf | grep "^R\$\*" | grep -i "Relaying denied"`
								else
									Result="취약"
									Exp="스펨 메일 릴레이 제한(Relaying denied)이 설정되어 있지 않으므로 취약함"
									Evi=`cat /etc/sendmail.cf | grep "^R\$\*" | grep -i "Relaying denied"`
								fi
					
						else
							Result="수동점검"
							Exp="/etc/mail/sendmail.cf 파일 없음"
							Evi=""
					fi							
				;;
		
			esac	
			
	fi
	

	if [ -f /etc/mail/sendmail.cf ]
		then
			echo "#cat /etc/mail/sendmail.cf" >> $REF_FILE 2>&1
			cat /etc/mail/sendmail.cf >> $REF_FILE 2>&1
		else
			echo "#cat /etc/sendmail.cf" >> $REF_FILE 2>&1
			cat /etc/sendmail.cf >> $REF_FILE 2>&1
			echo "#cat /etc/postfix/main.cf" >> $REF_FILE 2>&1
			cat /etc/postfix/main.cf >> $REF_FILE 2>&1
	fi
	
	if [ -f /etc/exim/exim.conf ]
		then
			echo "#cat /etc/exim/exim.conf" >> $REF_FILE 2>&1
			cat /etc/exim/exim.conf >> $REF_FILE 2>&1
		else
			echo "#cat /etc/exim4/exim4.conf" >> $REF_FILE 2>&1
			cat /etc/exim4/exim4.conf >> $REF_FILE 2>&1
	fi
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# expn, vrfy 명령어 제한
U_48_mail_expn_vrfy() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="expn, vrfy 명령어 제한"
	Item_head "U-48" "$iTitle" "$iCODE"
	if [ -f sendmail_tmp ]
		then
			Result="양호"
			Exp="메일 서비스가 비실행중이므로 양호함"
			Evi=""
		else
			case $OS_STR in
				Linux | HP-UX | SunOS)
				#Linux HP-UX SunOS
					if [ -f /etc/mail/sendmail.cf ]
						then
							if [ `cat /etc/mail/sendmail.cf | grep -v "^ *#" | egrep -i "novrfy|noexpn" | grep -v "grep" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="expn, vrfy 명령어 제한 설정(novrfy,noexpn)이 되어 있으므로 양호함"
									Evi=`cat /etc/mail/sendmail.cf | egrep -i "novrfy|noexpn" | grep -v "grep"`
								else
									Result="취약"
									Exp="expn, vrfy 명령어 제한 설정(novrfy,noexpn)이 되어 있지 않으므로 취약함"
									Evi=`cat /etc/mail/sendmail.cf | egrep -i "PrivacyOptions" | grep -v "grep"`
							fi
						else
							Result="수동점검"
							Exp="/etc/mail/sendmail.cf 파일 없음"
							Evi=""
					fi
					
					if [ -f /etc/postfix/main.cf ]
						then
							if [ `cat /etc/postfix/main.cf | grep "disable_vrfy_command = yes" | grep -v "grep" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="vrfy 명령어 제한 설정이 되어 있으므로 양호함"
									Evi=`cat /etc/postfix/main.cf | grep "disable_vrfy_command" | grep -v "grep"`
								else
									Result="취약"
									Exp="vrfy 명령어 제한 설정이 되어 있지 않으므로 취약함"
									Evi=`cat /etc/postfix/main.cf | grep "disable_vrfy_command" | grep -v "grep"`
							fi
						else
							Result="수동점검"
							Exp="/etc/postfix/main.cf 파일 없음"
							Evi=""
					fi
					
					if [ -f /etc/exim/exim.conf ]
						then
							if [ `cat /etc/exim/exim.conf | egrep -i "acl_smtp_vrty|acl_smtp_expn" | grep -v "grep" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="expn, vrfy 명령어 제한 설정(novrfy,noexpn)이 되어 있으므로 양호함"
									Evi=`cat /etc/exim/exim.conf | egrep -i "acl_smtp_vrty|acl_smtp_expn" | grep -v "grep"`
								else
									Result="취약"
									Exp="expn, vrfy 명령어 제한 설정(novrfy,noexpn)이 되어 있지 않으므로 취약함"
									Evi=`cat /etc/exim/exim.conf | egrep -i "acl_smtp_vrty|acl_smtp_expn" | grep -v "grep"`
							fi
						else
							Result="수동점검"
							Exp="/etc/exim/exim.conf 파일 없음"
							Evi=""
					fi
				;;
		
				AIX)
				#AIX
					if [ -f /etc/mail/sendmail.cf ]
						then
							if [ `cat /etc/mail/sendmail.cf | grep -v "^ *#" | egrep -i "novrfy|noexpn" | grep -v "grep" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="expn, vrfy 명령어 제한 설정(novrfy,noexpn)이 되어 있으므로 양호함"
									Evi=`cat /etc/mail/sendmail.cf | egrep -i "novrfy|noexpn" | grep -v "grep"`
								else
									Result="취약"
									Exp="expn, vrfy 명령어 제한 설정(novrfy,noexpn)이 되어 있지 않으므로 취약함"
									Evi=`cat /etc/mail/sendmail.cf | egrep -i "PrivacyOptions" | grep -v "grep"`
							fi
						elif [ -f /etc/sendmail.cf ]
							then
								if [ `cat /etc/sendmail.cf | grep -v "^ *#" | egrep -i "novrfy|noexpn" | grep -v "grep" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="expn, vrfy 명령어 제한 설정(novrfy,noexpn)이 되어 있으므로 양호함"
									Evi=`cat /etc/sendmail.cf | egrep -i "novrfy|noexpn" | grep -v "grep"`
								else
									Result="취약"
									Exp="expn, vrfy 명령어 제한 설정(novrfy,noexpn)이 되어 있지 않으므로 취약함"
									Evi=`cat /etc/sendmail.cf | egrep -i "PrivacyOptions" | grep -v "grep"`
								fi
					
						else
							Result="수동점검"
							Exp="/etc/mail/sendmail.cf 파일 없음"
							Evi=""
					fi

					if [ -f /etc/postfix/main.cf ]
						then
							if [ `cat /etc/postfix/main.cf | grep "disable_vrfy_command = yes" | grep -v "grep" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="vrfy 명령어 제한 설정이 되어 있으므로 양호함"
									Evi=`cat /etc/postfix/main.cf | grep "disable_vrfy_command" | grep -v "grep"`
								else
									Result="취약"
									Exp="vrfy 명령어 제한 설정이 되어 있지 않으므로 취약함"
									Evi=`cat /etc/postfix/main.cf | grep "disable_vrfy_command" | grep -v "grep"`
							fi
						else
							Result="수동점검"
							Exp="/etc/postfix/main.cf 파일 없음"
							Evi=""
					fi
					
					if [ -f /etc/exim/exim.conf ]
						then
							if [ `cat /etc/exim/exim.conf | egrep -i "acl_smtp_vrty|acl_smtp_expn" | grep -v "grep" | wc -l` -eq 1 ]
								then
									Result="양호"
									Exp="expn, vrfy 명령어 제한 설정(novrfy,noexpn)이 되어 있으므로 양호함"
									Evi=`cat /etc/exim/exim.conf | egrep -i "acl_smtp_vrty|acl_smtp_expn" | grep -v "grep"`
								else
									Result="취약"
									Exp="expn, vrfy 명령어 제한 설정(novrfy,noexpn)이 되어 있지 않으므로 취약함"
									Evi=`cat /etc/exim/exim.conf | egrep -i "acl_smtp_vrty|acl_smtp_expn" | grep -v "grep"`
							fi
						else
							Result="수동점검"
							Exp="/etc/exim/exim.conf 파일 없음"
							Evi=""
					fi					
				;;
		
			esac
	fi
	
	if [ -f sendmail_tmp ]
		then
			rm -rf sendmail_tmp
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# DNS 보안 버전 패치 
U_49_dns_patch() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="DNS 보안 버전 패치"
	Item_head "U-49" "$iTitle" "$iCODE"

	if [ `ps -ef | grep named | grep -v "grep" | wc -l` -eq 0 ]
		then
			Result="양호"
			Exp="Name server를 사용하지 않으므로 양호함"
			Evi=""
		else
			Result="수동점검"
			Exp="결과 값 참고"
			Evi=`ps -ef | grep named | grep -v "grep"`
					
			echo "#strings /usr/sbin/named | grep -i named version 결과 확인"  >> $RESULT_TXT 2>&1
			strings /usr/sbin/named | grep -i "named version"  >> $RESULT_TXT 2>&1
	fi

	
	if [ `ps -ef | grep named | grep -v "grep" | wc -l` -eq 0 ]
		then
			if [ -f /usr/sbin/named ] 
				then 
					echo "#ls -al /usr/sbin/named"  >> $REF_FILE 2>&1
					ls -al /usr/sbin/named >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
					echo "#strings /usr/sbin/named | grep -i version"  >> $REF_FILE 2>&1
					strings /usr/sbin/named | grep -i version  >> $REF_FILE 2>&1
					echo ""  >> $REF_FILE 2>&1
					echo ""  >> $REF_FILE 2>&1
					echo "#strings /usr/sbin/named"  >> $REF_FILE 2>&1
					strings /usr/sbin/named >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
				else
					echo "/usr/sbin/named 파일이 존재하지 않음" >> $REF_FILE 2>&1
			fi
	
			if [ -f /usr/sbin/named8 ] 
				then 
					echo "#/usr/sbin/named8 -v"  >> $REF_FILE 2>&1
					/usr/sbin/named8 -v >> $REF_FILE 2>&1
					echo " " >> $REF_FILE 2>&1
				else
					echo "/usr/sbin/named8 -v 파일이 존재하지 않음" >> $REF_FILE 2>&1
			fi
	fi
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# DNS Zone Transfer 설정
U_50_dns_zone_transfer() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="DNS Zone Transfer 설정"
	Item_head "U-50" "$iTitle" "$iCODE"
	if [ `ps -ef | grep named | grep -v "grep" | wc -l` -eq 0 ]
	then
		Result="양호함"
		Exp="Name server를 사용하지 않으므로 양호함"
		Evi=""
	else
		if [ -f /etc/named.conf ]
		then
			if [ `cat /etc/named.conf | grep "\allow-transfer.*[0-256].[0-256].[0-256].[0-256].*" | grep -v "^ *#" | wc -l` -eq 0 ]
			then
				Result="취약"
				Exp="DNS Zone Transfer 설정이 없으므로 취약함"
				Evi=`cat /etc/named.conf | grep "\allow-transfer.*[0-256].[0-256].[0-256].[0-256].*"`
		    else
		       	Result="양호"
				Exp="DNS Zone Transfer 설정이 되어 있으므로 양호함"
				Evi=`cat /etc/named.conf | grep "\allow-transfer.*[0-256].[0-256].[0-256].[0-256].*"`
			  fi
		else
			if [ -f /etc/named.boot ]
			then
				if [ `cat /etc/named.boot | grep "\xfrnets.*[0-256].[0-256].[0-256].[0-256].*" | grep -v "^ *#" | wc -l` -eq 0 ]
				then
					Result="취약"
					Exp="DNS Zone Transfer 설정이 없으므로 취약함"
					Evi=`cat /etc/named.boot | grep "\xfrnets.*[0-256].[0-256].[0-256].[0-256].*"`
				else
					Result="양호"
					Exp="DNS Zone Transfer 설정이 되어 있으므로 양호함"
					Evi=`cat /etc/named.boot | grep "\xfrnets.*[0-256].[0-256].[0-256].[0-256].*"`
				fi
		   else
		       	Result="수동점검"
				Exp="/etc/named.conf, /etc/named.boot 파일이 존재하지 않음"
				Evi=""
			fi
		fi
	fi
	
	if [ -f /etc/named.conf ]
		then
			echo "#cat /etc/named.conf" >> $REF_FILE 2>&1
			cat /etc/named.conf >> $REF_FILE 2>&1
			echo " " >> $REF_FILE 2>&1
	fi
	
	if [ -f /etc/named.boot ]
		then
			echo "#cat /etc/named.boot" >> $REF_FILE 2>&1
			cat /etc/named.boot >> $REF_FILE 2>&1
	fi
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

U_51_dns_dynamic_update() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="DNS 서비스의 취약한 동적 업데이트 설정 금지"
	Item_head "U-51" "$iTitle" "$iCODE"
	if [ `ps -ef | grep named | grep -v "grep" | wc -l` -eq 0 ]
	then
		Result="양호함"
		Exp="Name server를 사용하지 않으므로 양호함"
		Evi=""
	else
		if [ -f /etc/named.conf ]
		then
			if [ `cat /etc/named.conf | grep "\allow-update.*[0-256].[0-256].[0-256].[0-256].*" | grep -v "^ *#" | wc -l` -eq 0 ]
			then
				Result="양호"
				Exp="DNS 동적 업데이트 기능이 비활성화되어 있으므로 양호함"
				Evi=`cat /etc/named.conf | grep "\allow-update.*[0-256].[0-256].[0-256].[0-256].*"`
		    else
		       	Result="취약"
				Exp="DNS 동적 업데이트 기능이 활성화되어 있으므로 취약함"
				Evi=`cat /etc/named.conf | grep "\allow-update.*[0-256].[0-256].[0-256].[0-256].*"`
			fi
			else
		       	Result="수동점검"
				Exp="/etc/named.conf 파일이 존재하지 않음"
				Evi=""
		fi
	fi
	

	if [ -f /etc/named.conf ]
		then
			echo "#cat /etc/named.conf" >> $REF_FILE 2>&1
			cat /etc/named.conf >> $REF_FILE 2>&1
			echo " " >> $REF_FILE 2>&1
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# Telnet 서비스 비활성화
U_52_telnet_disabled() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="Telnet 서비스 비활성화"
	Item_head "U-52" "$iTitle" "$iCODE"
	
	SERVICE="ssh"
	
	if [ `ps -ef | egrep $SERVICE | egrep -v "grep" | wc -l` -eq 0 ]
	then
		#프로세스 동작 안함
		CHK_VALUE=0
	else
		#프로세스 동작 중
		CHK_VALUE=1
	fi
	
	if [ $TELNET_SVR = "false" ]
		then
			if [ $CHK_VALUE -eq 1 ]
				then
					Result="양호"
					Exp="telnet을 사용하지 않고, ssh를 사용하고 있으므로 양호함"
					Evi=""
				else
					Result="수동점검"
					Exp="telnet, ssh를 사용하지 않으므로 수동점검"
					Evi=""
			fi
		else
			Result="취약"
			Exp="ssh를 사용하고 있으나, telnet이 활성화되어 있으므로 취약함"
			Evi=""
		
	fi
	
	Evi=`ps -ef | egrep $SERVICE | egrep -v "grep"`
	
	if [ $TELNET_SVR = "true" ]
		then
			echo "#telnet 서비스 설정" >> $RESULT_TXT 2>&1
			if [ $OS_STR = "SunOS" ]
				then
					if [ $SOL_VER_PART = "1" ]
						then
							if [ -f /etc/inetd.conf ]
								then
									cat /etc/inetd.conf | grep "telnetd" >> $RESULT_TXT 2>&1
							fi
						else
							inetadm | grep telnet >> $RESULT_TXT 2>&1
					fi
				elif [ $OS_STR = "AIX" -o $OS_STR = "HP-UX" ]
					then
						cat /etc/inetd.conf | grep telnet >> $RESULT_TXT 2>&1
				else
						cat /etc/xinetd.d/telnet | grep disable >> $RESULT_TXT 2>&1
			fi
	fi
			
	echo "" >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
	
	unset SERVICE
	unset CHK_VALUE
}

# SSH 버전 취약점 관리
ssh_ver() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="SSH 버전 취약점 관리"
	Item_head "ETC" "$iTitle" "$iCODE"
	
	SSH_CHECK=`ps -ef | grep "sshd" | egrep -v "grep" | wc -l`
	if [ $OS_STR = "SunOS" ]
		then
			SSH_CHECK=`svcs network/ssh | grep "online" | wc -l`
	fi
	
	if [ $SSH_CHECK -gt 0 ]
		then
			Result="수동점검"
			Exp="SSH 버전 확인필요"
			Evi=`ssh -V`
		else
			Result="양호"
			Exp="SSH 서비스가 비실행중이므로 양호함"
			Evi=""
	fi
	
	echo "#ssh -V" >> $RESULT_TXT 2>&1
	ssh -V	>> $RESULT_TXT 2>&1
	
	ps -ef | grep "sshd" >> $RESULT_TXT 2>&1
	
	echo "" >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# FTP 서비스 정보 노출 제한
U_53_ftp_banner() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="FTP 서비스 정보 노출 제한"
	Item_head "U-53" "$iTitle" "$iCODE"
	
	case $OS_STR in
		Linux | SunOS)
		#Linux, SunOS:
			if [ -f /etc/vsftpd.conf ]
				then
					Result="수동점검"
					Exp="FTP 설정 파일을 참고하여 수동진단(REF 파일 참조)"
					Evi=""
					echo "#cat /etc/vsftpd.conf | grep ftpd_banner" >> $REF_FILE 2>&1
					cat /etc/vsftpd.conf | grep 'ftpd_banner' >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
				else
					Result="수동점검"
					Exp="U-54 항목에서 FTP가 실행되지 않은 경우 양호"
					Evi=""
					echo "/etc/vsftpd.conf 파일이 없음" >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/vsftpd/vsftpd.conf ]
				then
					Result="수동점검"
					Exp="FTP 설정 파일을 참고하여 수동진단(REF 파일 참조)"
					Evi=""
					echo "#cat /etc/vsftpd/vsftpd.conf | grep ftpd_banner" >> $REF_FILE 2>&1
					cat /etc/vsftpd/vsftpd.conf | grep 'ftpd_banner' >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
					
				else
					Result="수동점검"
					Exp="U-54 항목에서 FTP가 실행되지 않은 경우 양호"
					Evi=""
					echo "/etc/vsftpd/vsftpd.conf 파일이 없음" >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/proftpd.conf ]
				then
					Result="수동점검"
					Exp="FTP 설정 파일을 참고하여 수동진단(REF 파일 참조)"
					Evi=""
					echo "#cat /etc/proftpd.conf | grep ServerIdent" >> $REF_FILE 2>&1
					cat /etc/proftpd.conf | grep 'ServerIdent' >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
				else
					Result="수동점검"
					Exp="U-54 항목에서 FTP가 실행되지 않은 경우 양호"
					Evi=""
					echo "/etc/proftpd.conf 파일이 없음" >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/proftpd/proftpd.conf ]
				then
					Result="수동점검"
					Exp="FTP 설정 파일을 참고하여 수동진단(REF 파일 참조)"
					Evi=""
					echo "#cat /etc/proftpd/proftpd.conf | grep ServerIdent" >> $REF_FILE 2>&1
					cat /etc/proftpd/proftpd.conf | grep 'ServerIdent' >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
				else
					Result="수동점검"
					Exp="U-54 항목에서 FTP가 실행되지 않은 경우 양호"
					Evi=""
					echo "/etc/proftpd/proftpd.conf 파일이 없음" >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
			fi
		;;
		
		AIX)
		#AIX:
			if [ -f /tmp/ftpd.msg ]
				then
					Result="수동점검"
					Exp="FTP 설정 파일을 참고하여 수동진단(REF 파일 참조)"
					Evi=""
					echo "#cat /tmp/ftpd.msg" >> $REF_FILE 2>&1
					cat /tmp/ftpd.msg >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
				else
					Result="수동점검"
					Exp="U-54 항목에서 FTP가 실행되지 않은 경우 양호"
					Evi=""
					echo "/tmp/ftpd.msg 파일이 없음" >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/vsftpd.conf ]
				then
					Result="수동점검"
					Exp="FTP 설정 파일을 참고하여 수동진단(REF 파일 참조)"
					Evi=""
					echo "#cat /etc/vsftpd.conf | grep ftpd_banner" >> $REF_FILE 2>&1
					cat /etc/vsftpd.conf | grep 'ftpd_banner' >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
				else
					Result="수동점검"
					Exp="U-54 항목에서 FTP가 실행되지 않은 경우 양호"
					Evi=""
					echo "/etc/vsftpd.conf 파일이 없음" >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/proftpd.conf ]
				then
					Result="수동점검"
					Exp="FTP 설정 파일을 참고하여 수동진단(REF 파일 참조)"
					Evi=""
					echo "#cat /etc/proftpd.conf | grep ServerIdent" >> $REF_FILE 2>&1
					cat /etc/proftpd.conf | grep 'ServerIdent' >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
				else
					Result="수동점검"
					Exp="U-54 항목에서 FTP가 실행되지 않은 경우 양호"
					Evi=""
					echo "/etc/proftpd.conf 파일이 없음" >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
			fi
		;;
		
		HP-UX)
		#HP-UX:
			
			if [ -f /etc/vsftpd.conf ]
				then
					Result="수동점검"
					Exp="FTP 설정 파일을 참고하여 수동진단(REF 파일 참조)"
					Evi=""
					echo "#cat /etc/vsftpd.conf | grep ftpd_banner" >> $REF_FILE 2>&1
					cat /etc/vsftpd.conf | grep 'ftpd_banner' >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
				else
					Result="수동점검"
					Exp="U-54 항목에서 FTP가 실행되지 않은 경우 양호"
					Evi=""
					echo "/etc/vsftpd.conf 파일이 없음" >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
			fi
			
			if [ -f /etc/proftpd.conf ]
				then
					Result="수동점검"
					Exp="FTP 설정 파일을 참고하여 수동진단(REF 파일 참조)"
					Evi=""
					echo "#cat /etc/proftpd.conf | grep ServerIdent" >> $REF_FILE 2>&1
					cat /etc/proftpd.conf | grep 'ServerIdent' >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
				else
					Result="수동점검"
					Exp="U-54 항목에서 FTP가 실행되지 않은 경우 양호"
					Evi=""
					echo "/etc/proftpd.conf 파일이 없음" >> $REF_FILE 2>&1
					echo "---------------------------------------------------" >> $REF_FILE 2>&1
			fi
		;;
		
		*)
		#
		;;
		
	esac
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"    
}

# 암호화되지 않는 FTP 서비스 비활성화
U_54_ftp() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="암호화되지 않는 FTP 서비스 비활성화"
	Item_head "U-54" "$iTitle" "$iCODE"
	SERVICE=ftp
	case $OS_STR in
		Linux)
		#Linux:
			
			if [ $FTP_SVR = "false" ]
				then
					Result="양호"
					Exp="현재 ftp 서비스가 비실행중이므로 양호함"
					Evi=`echo "#ps 확인(결과가 없으면 비실행중)"; ps -ef | grep ftp | egrep -v "grep|ssh"; echo " "; echo "#서비스 등록확인(결과가 없으면 서비스 미등록)"; chkconfig --list | grep "ftp";echo " "; systemctl list-unit-files --type=service | grep "ftp";echo " "; echo "# xinetd.d 하위 설정파일 확인"; cat /etc/xinetd.d/*ftp* 2>/dev/null | grep disable`
				else
					Result="취약"
					Exp="현재 ftp 서비스가 실행중이므로 취약함"
					Evi=`echo "#ps 확인(결과가 없으면 비실행중)"; ps -ef | grep ftp | egrep -v "grep|ssh"; echo " "; echo "#서비스 등록확인(결과가 없으면 서비스 미등록)"; chkconfig --list | grep "ftp";echo " "; systemctl list-unit-files --type=service | grep "ftp";echo " "; echo "# xinetd.d 하위 설정파일 확인"; cat /etc/xinetd.d/*ftp* 2>/dev/null | grep disable`
			fi
			
			
			unset SERVICE
			unset dir
			unset CHK_VALUE
		;;
		
		AIX | HP-UX)
		#AIX HP-UX:
			
			if [ $FTP_SVR = "false" ]
				then
					Result="양호"
					Exp="현재 ftp 서비스가 비실행중이므로 양호함"
					Evi=`echo "#ps 확인(결과가 없으면 비실행중)"; ps -ef | grep ftp | egrep -v "grep|sftp"; echo " "; echo "#inetd.conf 설정 파일 확인(FTP 주석처리 시 양호)"; cat /etc/inetd.conf | egrep $SERVICE | egrep -v "before|that|have"`
				else
					Result="취약"
					Exp="현재 ftp 서비스가 실행중이므로 취약함"
					Evi=`echo "#ps 확인(결과가 없으면 비실행중)"; ps -ef | grep ftp | egrep -v "grep|sftp"; echo " "; echo "#inetd.conf 설정 파일 확인(FTP 주석처리 시 양호)"; cat /etc/inetd.conf | egrep $SERVICE | egrep -v "before|that|have"`
			fi
			
			unset SERVICE
			unset dir
			unset CHK_VALUE
		;;
		
		SunOS)
		#SunOS:
			if [ $FTP_SVR = "false" ]
				then
					Result="양호"
					Exp="FTP 서비스가 비실행중이므로 양호함"
					Evi="$FTP_CHK"
				else
					Result="취약"
					Exp="현재 ftp 서비스가 실행중이므로 취약함"
					Evi="$FTP_CHK"
			fi
			
			echo "1) FTP 서비스 확인" >> $RESULT_TXT 2>&1
			echo "$FTP_RESULT" >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
			echo "2) FTP 프로세스 확인" >> $RESULT_TXT 2>&1
			echo "$FTP_PS_RESULT" >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
			
			unset FTP_RESULT
			unset CHK_VALUE_1
			unset FTP_PS_RESULT
			unset CHK_VALUE_2
		;;
		
		*)
		#
		;;
		
	esac
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"    
}

# FTP 계정 Shell 제한
U_55_ftp_noshell() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="FTP 계정 Shell 제한"
	Item_head "U-55" "$iTitle" "$iCODE"
	
	case $OS_STR in
		Linux | AIX | HP-UX)
		#Linux AIX HP-UX:
			if [ $FTP_SVR = "false" ]
				then
					Result="양호"
					Exp="FTP 서비스가 없으므로 양호함"
					Evi=""
				else
					if [ `cat /etc/passwd | egrep "ftp" | awk -F: '{print $7}'| egrep -v 'false|nologin|null|halt|sync|shutdown' | wc -l` -eq 0 ]
						then
							if [ `cat /etc/passwd | egrep "ftp" | wc -l` -eq 0 ]
								then 
								Result="양호"
								Exp="ftp 계정이 존재하지 않으므로 양호함"
								Evi=""
							fi
							Result="양호"
							Exp="/bin/false or /sbin/nologin or noshell로 설정되어 있으므로 양호함"
							Evi=`cat /etc/passwd | egrep "ftp"`
						else
							Result="취약"
							Exp="/bin/false or /sbin/nologin or noshell로 설정되어 있지 않으므로 취약함"
							Evi=`cat /etc/passwd | egrep "ftp"`
					fi
			fi
			
		;;
		
		SunOS)
		#SunOS:
			if [ $FTP_SVR = "false" ]
				then
					Result="양호"
					Exp="FTP 서비스가 없으므로 양호함"
					Evi=""
				else
					if [ -f /etc/shells ]
						then
							if [ `cat /etc/shells | egrep "ftp" |  awk -F: '{print $7}'| egrep -v 'false|nologin|null|halt|sync|shutdown|^ *$' |wc -l` -eq 0 ]
								then
									Result="양호"
									Exp="/bin/false or /sbin/nologin or noshell로 설정되어 있으므로 양호함"
									Evi=`cat /etc/shells | egrep "ftp"`

								else
									Result="취약"
									Exp="/bin/false or /sbin/nologin or noshell로 설정되어 있지 않으므로 취약함"
									Evi=`cat /etc/shells | egrep "ftp"`
							fi
							
							cat /etc/shells >> $REF_FILE 2>&1
					else
							if [ `cat /etc/passwd | egrep "ftp" |  awk -F: '{print $7}'| egrep -v 'false|nologin|null|halt|sync|shutdown|^ *$' |wc -l` -eq 0 ]
								then
									if [ `cat /etc/passwd | egrep "ftp" | wc -l` -eq 1 ]
										then
											Result="양호"
											Exp="/bin/false or /sbin/nologin or noshell로 설정되어 있으므로 양호함"
											Evi=`cat /etc/passwd | egrep "ftp"`
										else
											Result="양호"
											Exp="ftp 계정이 존재하지 않으므로 양호함"
											Evi="#cat /etc/passwd | egrep ftp 결과 확인"
									fi
								else
									Result="취약"
									Exp="/bin/false or /sbin/nologin or noshell로 설정되어 있지 않으므로 취약함"
									Evi=`cat /etc/passwd | egrep "ftp"`
							fi
					fi
			fi
			
		;;
		
		*)
		#
		;;
		
	esac
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# FTP 서비스 접근 제어 설정
U_56_ftp_acl() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="FTP 서비스 접근 제어 설정"
	Item_head "U-56" "$iTitle" "$iCODE"
	
    TARGET_FILE="/etc/ftpusers /etc/ftpd/ftpusers /etc/vsftpd/ftpusers /etc/vsftpd/user_list /etc/vsftpd.ftpusers /etc/vsftpd.user_list"
    TMP=0
	
	for check_file in $TARGET_FILE
	do
		if [ -f $check_file ]
			then
				perm_check $check_file

				FILE_LIST="$FILE_LIST$check_file "
				
				if [ "$OWNER" != "root"  -o $uPn -gt 6 -o $gPn -gt 4 -o $oPn -gt 0 ]
					then
						REGUL_SET="$REGUL_SET$check_file "
				fi
				TMP=`expr $TMP + 1`
		fi
	done
	
	if [ $FTP_SVR = "false" ]
		then
			Result="양호"
			Exp="FTP 서비스가 없으므로 양호함"
			Evi=""
		else
			if [ $TMP -eq 0 ]
				then
					Result="양호"
					Exp="$TARGET_FILE 파일이 존재하지 않아 양호함"
					Evi=`ls -alL $TARGET_FILE`
				else
					if [ "$REGUL_SET" != "" ]
						then
							Result="취약"
							Exp="ftpusers 파일의 소유자가 root 가 아니거나 접근 권한이 640보다 크게 설정되어 있으므로 취약함"
							Evi=`ls -alL $REGUL_SET`
						else
							Result="양호"
							Exp="ftpusers 파일의 소유자가 root 이며 접근 권한이 640 이하로 설정되어 있으므로 양호함"
							Evi=`ls -alL $FILE_LIST`
					fi
			fi
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
	
	unset FILE_LIST
	unset REGUL_SET
}

# Ftpusers 파일 설정
U_57_ftp_root_deny() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="Ftpusers 파일 설정"
	Item_head "U-57" "$iTitle" "$iCODE"

    TARGET_FILE="/etc/ftpusers /etc/ftpd/ftpusers /etc/vsftpd/ftpusers /etc/vsftpd/user_list /etc/vsftpd.ftpusers /etc/vsftpd.user_list"
    countY=0
	countN=0
	
	if [ $FTP_SVR = "false" ]
		then
			Result="양호"
			Exp="FTP 서비스가 없으므로 양호함"
			Evi=""
		else
			if [ $TMP -eq 0 ]
				then
					Result="양호"
					Exp="$TARGET_FILE 파일이 존재하지 않아 양호함"
					Evi=""
				else
					for check_file in $TARGET_FILE
					do
						if [ -f $check_file ]
							then
								if [ `cat $check_file | grep -i "root" | grep -v "^#" | wc -l` -eq 1 ] 
									then
										Result="양호"
										Exp="root 계정 ftp 접속 제한 설정이 되어 있으므로 양호함"
										Evi=`cat $check_file | grep -i "root" | grep -v "^#"`
										
										countY=`expr $countY + 1`
									else
										Result="취약"
										Exp="root 계정 ftp 접속 제한 설정이 되어 있지 않으므로 취약함"
										Evi=`cat $check_file | grep -i "root"`
										
										countN=`expr $countN + 1`
								fi
						fi
					done
			fi
	fi
	
	for denyfile in $TARGET_FILE
		do
			echo $denyfile >> $REF_FILE 2>&1
			cat $denyfile >> $REF_FILE 2>&1
	done
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
	
	unset TARGET_FILE
	unset countY
	unset countN
	unset TMP
}

# 불필요한 SNMP 서비스 구동 점검
U_58_snmp() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="불필요한 SNMP 서비스 구동 점검"
	Item_head "U-58" "$iTitle" "$iCODE"
	
	if [ `ps -ef | grep snmp | grep -v "dmi" | grep -v "grep" | wc -l` -eq 0 ]
		then
			Result="양호"
			Exp="SNMP가 비실행중이므로 양호함"
			Evi=""
			touch snmp_tmp
		else
			Result="수동점검"
			Exp="SNMP가 실행중 입니다"
			Evi=`ps -ef | grep snmp | grep -v "dmi" | grep -v "grep"`
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 안전한 SNMP 버전 사용
U_59_snmp_version() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="안전한 SNMP 버전 사용"
	Item_head "U-59" "$iTitle" "$iCODE"
	
	if [ -f snmp_tmp ]
		then
			Result="양호"
			Exp="SNMP가 비실행중이므로 양호함"
			Evi=""
			echo " "	>> $REF_FILE 2>&1
		else
			Result="수동점검"
			Exp="각 OS의 SNMP 설정 파일을 보고 수동진단(REF 파일 참조)"
			Evi=""
			#SunOS 9 이하
			if [ -f /etc/snmp/conf/snmpd.conf ]
				then
					echo "#cat /etc/snmp/conf/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/snmp/conf/snmpd.conf >> $REF_FILE 2>&1
			#HP-UX
			elif [ -f /etc/SnmpAgent.d/snmpd.conf ]
				then
					echo "#cat /etc/SnmpAgent.d/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/SnmpAgent.d/snmpd.conf >> $REF_FILE 2>&1
			elif [ -f /etc/snmpd.conf ]
				then
					echo "#cat /etc/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/snmpd.conf >> $REF_FILE 2>&1
			#Linux
			elif [ -f /etc/snmp/snmpd.conf ]
				then
					echo "#cat /etc/snmp/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/snmp/snmpd.conf >> $REF_FILE 2>&1
			#SunOS 10 이상
			elif [ -f /etc/sma/snmp/snmpd.conf ]
				then
					echo "#cat /etc/sma/snmp/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/sma/snmp/snmpd.conf >> $REF_FILE 2>&1
			#AIX
			elif [ -f /etc/snmpdv3.conf ]
				then
					echo "#cat /etc/snmpdv3.conf 확인" >> $REF_FILE 2>&1
					cat /etc/snmpdv3.conf | grep -v "#" >> $REF_FILE 2>&1						
			fi					
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# SNMP Community String 복잡성 설정
U_60_snmp_community() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="SNMP Community String 복잡성 설정"
	Item_head "U-60" "$iTitle" "$iCODE"
	
	if [ -f snmp_tmp ]
		then
			Result="양호"
			Exp="SNMP가 비실행중이므로 양호함"
			Evi=""
		else
			#SunOS 9 이하
			if [ -f /etc/snmp/conf/snmpd.conf ]
				then
					if [ `cat /etc/snmp/conf/snmpd.conf | egrep -i "public|private" | grep -v "^ *#" | wc -l ` -eq 0 ]
						then
							Result="양호"
							Exp="default snmp community string을 변경하여 운용하므로 양호함"
							Evi=`cat /etc/snmp/conf/snmpd.conf | egrep -i 'read-community|write-community'`
						else
							Result="취약(주석처리 항목과 신규생성 항목 전부 확인 필요)"
							Exp="snmp 서비스 커뮤니티스트링이 public 또는 private로 되어 있으므로 취약함"
							Evi=`cat /etc/snmp/conf/snmpd.conf | egrep -i 'read-community|write-community'`
					fi
				#HP-UX
				elif [ -f /etc/SnmpAgent.d/snmpd.conf ]
				then
					if [ `cat /etc/SnmpAgent.d/snmpd.conf | egrep -i "public|private" | grep -v "^ *#" | wc -l ` -eq 0 ]
						then
							Result="양호"
							Exp="default snmp community string을 변경하여 운용하고 있으므로 양호함"
							Evi=`cat /etc/SnmpAgent.d/snmpd.conf | egrep -i 'get-community-name|set-community-name'`
						else
							Result="취약(주석처리 항목과 신규생성 항목 전부 확인 필요)"
							Exp="snmp 서비스 커뮤니티스트링이 public 또는 private로 되어 있으므로 취약함"
							Evi=`cat /etc/SnmpAgent.d/snmpd.conf | egrep -i 'get-community-name|set-community-name'`
					fi
				elif [ -f /etc/snmpd.conf ]
				then
					if [ `cat /etc/snmpd.conf | egrep -i "public|private" | grep -v "^ *#" | wc -l ` -eq 0 ]
						then
							Result="양호"
							Exp="default snmp community string을 변경하여 운용하고 있으므로 양호함"
							Evi=`cat /etc/snmpd.conf | egrep -i 'get-community-name|set-community-name'`
						else
							Result="취약(주석처리 항목과 신규생성 항목 전부 확인 필요)"
							Exp="snmp 서비스 커뮤니티스트링이 public 또는 private로 되어 있으므로 취약함"
							Evi=`cat /etc/snmpd.conf | egrep -i 'get-community-name|set-community-name'`
					fi
				
				#Linux
				elif [ -f /etc/snmp/snmpd.conf ]
				then
					if [ `cat /etc/snmp/snmpd.conf | egrep -i "public|private" | grep -v "^ *#" | wc -l ` -eq 0 ]
						then
							Result="양호"
							Exp="default snmp community string을 변경하여 운용하고 있으므로 양호함"
							Evi=`cat /etc/snmp/snmpd.conf | egrep -i 'com2sec'`
						else
							Result="취약(주석처리 항목과 신규생성 항목 전부 확인 필요)"
							Exp="snmp 서비스 커뮤니티스트링이 public 또는 private로 되어 있으므로 취약함"
							Evi=`cat /etc/snmp/snmpd.conf | egrep -i 'com2sec'`
					fi
				#SunOS 10 이상
				elif [ -f /etc/sma/snmp/snmpd.conf ]
				then
					if [ `cat /etc/sma/snmp/snmpd.conf | egrep -i "public|private" | grep -v "^ *#" | wc -l ` -eq 0 ]
						then
							Result="양호"
							Exp="default snmp community string을 변경하여 운용하고 있으므로 양호함"
							Evi=`cat /etc/sma/snmp/snmpd.conf | egrep -i 'rocommunity|rwcommunity'`
						else
							Result="취약(주석처리 항목과 신규생성 항목 전부 확인 필요)"
							Exp="snmp 서비스 커뮤니티스트링이 public 또는 private로 되어 있으므로 취약함"
							Evi=`cat /etc/sma/snmp/snmpd.conf | egrep -i 'rocommunity|rwcommunity'`
					fi
				#AIX
				elif [ -f /etc/snmpdv3.conf ]
				then
					if [ `cat /etc/snmpdv3.conf | egrep -i "public|private" | grep -v "^ *#" | wc -l ` -eq 0 ]
						then
							Result="양호"
							Exp="default snmp community string을 변경하여 운용하고 있으므로 양호함"
							Evi=`cat /etc/snmpdv3.conf | egrep -i 'community'`
						else
							Result="취약(주석처리 항목과 신규생성 항목 전부 확인 필요)"
							Exp="snmp 서비스 커뮤니티스트링이 public 또는 private로 되어 있으므로 취약함"
							Evi=`cat /etc/snmpdv3.conf | egrep -i 'community'`
					fi
				else
					Result="수동점검"
					Exp="snmpd.conf 파일이 존재하지 않음"
					Evi=""
			fi
			
			echo "#community string 상세 내역은 REF 파일 참조" >> $RESULT_TXT 2>&1
	fi
	
	if [ -f snmp_tmp ]
		then
			echo " "	>> $REF_FILE 2>&1
		else
			#SunOS 9 이하
			if [ -f /etc/snmp/conf/snmpd.conf ]
				then
					echo "#cat /etc/snmp/conf/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/snmp/conf/snmpd.conf >> $REF_FILE 2>&1
			#HP-UX
			elif [ -f /etc/SnmpAgent.d/snmpd.conf ]
				then
					echo "#cat /etc/SnmpAgent.d/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/SnmpAgent.d/snmpd.conf >> $REF_FILE 2>&1
			elif [ -f /etc/snmpd.conf ]
				then
					echo "#cat /etc/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/snmpd.conf >> $REF_FILE 2>&1
			#Linux
			elif [ -f /etc/snmp/snmpd.conf ]
				then
					echo "#cat /etc/snmp/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/snmp/snmpd.conf >> $REF_FILE 2>&1
			#SunOS 10 이상
			elif [ -f /etc/sma/snmp/snmpd.conf ]
				then
					echo "#cat /etc/sma/snmp/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/sma/snmp/snmpd.conf >> $REF_FILE 2>&1
			#AIX
			elif [ -f /etc/snmpdv3.conf ]
				then

					echo "#cat /etc/snmpdv3.conf 확인" >> $REF_FILE 2>&1
					cat /etc/snmpdv3.conf | grep -v "#" >> $REF_FILE 2>&1						
			fi					
	fi
	
	echo "" >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# SNMP Access Control 설정
U_61_snmp_acl() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="SNMP Access Control 설정"
	Item_head "U-61" "$iTitle" "$iCODE"
	
	if [ -f snmp_tmp ]
		then
			Result="양호"
			Exp="SNMP가 비실행중이므로 양호함"
			Evi=""
		else
			Result="수동점검"
			Exp="각 OS의 SNMP 설정 파일을 보고 수동진단"
			Evi=""
			#SunOS 9 이하
			if [ -f /etc/snmp/conf/snmpd.conf ]
				then
					echo "#cat /etc/snmp/conf/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/snmp/conf/snmpd.conf >> $REF_FILE 2>&1
			#HP-UX
			elif [ -f /etc/SnmpAgent.d/snmpd.conf ]
				then
					echo "#cat /etc/SnmpAgent.d/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/SnmpAgent.d/snmpd.conf >> $REF_FILE 2>&1
			elif [ -f /etc/snmpd.conf ]
				then
					echo "#cat /etc/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/snmpd.conf >> $REF_FILE 2>&1
			#Linux
			elif [ -f /etc/snmp/snmpd.conf ]
				then
					echo "#cat /etc/snmp/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/snmp/snmpd.conf >> $REF_FILE 2>&1
			#SunOS 10 이상
			elif [ -f /etc/sma/snmp/snmpd.conf ]
				then
					echo "#cat /etc/sma/snmp/snmpd.conf 확인" >> $REF_FILE 2>&1
					cat /etc/sma/snmp/snmpd.conf >> $REF_FILE 2>&1
			#AIX
			elif [ -f /etc/snmpdv3.conf ]
				then

					echo "#cat /etc/snmpdv3.conf 확인" >> $REF_FILE 2>&1
					cat /etc/snmpdv3.conf | grep -v "#" >> $REF_FILE 2>&1						
		fi		
	fi
	echo "" >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 로그인 시 경고 메시지 설정
U_62_login_banner() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="로그인 시 경고 메시지 설정"
	Item_head "U-62" "$iTitle" "$iCODE"
	
	Result="수동점검"
	Exp="$REF_FILE 참고하여 수동진단"
	Evi=""

	if [ -f /etc/default/telnetd ]
		then
			echo "#cat /etc/default/telnetd" >> $REF_FILE 2>&1
			cat /etc/default/telnetd >> $REF_FILE 2>&1
			echo "---------------------------------------------------" >> $REF_FILE 2>&1
		else
			echo "/etc/default/telnetd 파일이 없음" >> $REF_FILE 2>&1
			echo "---------------------------------------------------" >> $REF_FILE 2>&1
	fi
	
	if [ -f /etc/default/ftpd ]
		then
			echo "#cat /etc/default/ftpd" >> $REF_FILE 2>&1
			cat /etc/default/ftpd >> $REF_FILE 2>&1
			echo "---------------------------------------------------" >> $REF_FILE 2>&1
		else
			echo "/etc/default/ftpd 파일이 없음" >> $REF_FILE 2>&1
			echo "---------------------------------------------------" >> $REF_FILE 2>&1
	fi
	#AIX
	if [ -f /etc/security/login.cfg ]
		then
			echo "#cat /etc/security/login.cfg" >> $REF_FILE 2>&1
			cat /etc/security/login.cfg >> $REF_FILE 2>&1
			echo "---------------------------------------------------" >> $REF_FILE 2>&1
		else
			echo "/etc/security/login.cfg 파일이 없음" >> $REF_FILE 2>&1
			echo "---------------------------------------------------" >> $REF_FILE 2>&1
	fi
	
	if [ -f /usr/ftpd.cat ]
		then
			echo "#cat /usr/ftpd.cat" >> $REF_FILE 2>&1
			cat /usr/ftpd.cat >> $REF_FILE 2>&1
			echo "---------------------------------------------------" >> $REF_FILE 2>&1
		else
			echo "/usr/ftpd.cat 파일이 없음" >> $REF_FILE 2>&1
			echo "---------------------------------------------------" >> $REF_FILE 2>&1
	fi
	
	if [ -f /etc/mail/sendmail.cf ]
		then
			echo "#cat /etc/mail/sendmail.cf" >> $REF_FILE 2>&1
			cat /etc/mail/sendmail.cf >> $REF_FILE 2>&1
			echo "---------------------------------------------------" >> $REF_FILE 2>&1
		else
			echo "/etc/mail/sendmail.cf 파일이 없음" >> $REF_FILE 2>&1
			echo "---------------------------------------------------" >> $REF_FILE 2>&1
	fi
	
	if [ -f /etc/motd ]
		then
			echo "#cat /etc/motd" >> $RESULT_TXT 2>&1
			cat /etc/motd >> $RESULT_TXT 2>&1
			echo "---------------------------------------------------" >> $RESULT_TXT 2>&1
			echo "#cat /etc/motd" >> $REF_FILE 2>&1
			cat /etc/motd >> $REF_FILE 2>&1
			echo "---------------------------------------------------" >> $REF_FILE 2>&1
		else
			echo "/etc/motd 파일이 없음" >> $REF_FILE 2>&1
			echo "---------------------------------------------------" >> $REF_FILE 2>&1
			echo "/etc/motd 파일이 없음" >> $RESULT_TXT 2>&1
			echo "---------------------------------------------------" >> $RESULT_TXT 2>&1
	fi
	
	if [ -f /etc/issue.net ]
		then
			echo "#cat /etc/issue.net" >> $REF_FILE 2>&1
			cat /etc/issue.net >> $REF_FILE 2>&1
			echo "---------------------------------------------------" >> $REF_FILE 2>&1
			echo "#cat /etc/issue.net" >> $RESULT_TXT 2>&1
			cat /etc/issue.net >> $RESULT_TXT 2>&1
			echo "---------------------------------------------------" >> $RESULT_TXT 2>&1
		else
			echo "/etc/issue.net 파일이 없음" >> $REF_FILE 2>&1
			echo "---------------------------------------------------" >> $REF_FILE 2>&1
			echo "/etc/issue.net 파일이 없음" >> $RESULT_TXT 2>&1
			echo "---------------------------------------------------" >> $RESULT_TXT 2>&1
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# sudo 명령어 접근 관리
U_63_sudoers_permission() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="sudo 명령어 접근 관리"
	Item_head "U-63" "$iTitle" "$iCODE"
	
	if [ -f /etc/sudoers ] 
			then
				if [ `ls -alL /etc/sudoers | egrep -c "...-.-----.*(root|bin).*"` -eq 1 ]
					then
						Result="양호"
						Exp="/etc/sudoers 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
						Evi=`ls -alL /etc/sudoers`
					else
						Result="취약"
						Exp="/etc/sudoers 파일의 접근권한이 과도하게 설정되어 있으므로 취약함(운영환경에 따른 판단 필요)"
						Evi=`ls -alL /etc/sudoers`
				fi
			else
				Result="수동점검"
				Exp="/etc/sudoers 파일 사용여부 확인 후 양호, 취약 판단(AIX의 경우 sudo가 존재하지 않아 N/A"
				Evi=""
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 주기적 보안패치 및 벤더 권고사항 적용
U_64_latest_patch() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="주기적 보안패치 및 벤더 권고사항 적용"
	Item_head "U-64" "$iTitle" "$iCODE"
	
	Result="수동점검"
	Exp="주기적인 보안패치 여부 인터뷰 확인"
	Evi=`uname -a`

	echo "#패키지 설치 및 패치 상세는 ref 파일 참조 확인" >> $RESULT_TXT 2>&1
	echo "" >> $RESULT_TXT 2>&1
	#SunOS
	if [ $OS_STR = "SunOS" ]
	then
		echo "#uname -a 확인" >> $RESULT_TXT 2>&1
		uname -a >> $RESULT_TXT 2>&1
		
		echo "#패치버전확인">> $REF_FILE 2>&1
		showrev -p>> $REF_FILE 2>&1
		echo "" >> $REF_FILE 2>&1
		echo "#설치패키지확인 pkginfo ">> $REF_FILE 2>&1
		pkginfo >> $REF_FILE 2>&1
	fi
	
	#HP-UX
	if [ $OS_STR = "HP-UX" ]
	then
		echo "#uname -a 확인" >> $RESULT_TXT 2>&1
		uname -a >> $RESULT_TXT 2>&1
		echo "" >> $RESULT_TXT 2>&1
		echo "#패치버전확인" >> $RESULT_TXT 2>&1
		swlist -l bundle QPKBASE >> $RESULT_TXT 2>&1
		echo "" >> $RESULT_TXT 2>&1
		
		echo "#S/W확인" >> $REF_FILE 2>&1
		swlist >> $REF_FILE 2>&1
		echo "" >> $REF_FILE 2>&1
	fi
	
	#Linux
	if [ $OS_STR = "Linux" ]
	then
		echo "#uname -a 확인" >> $RESULT_TXT 2>&1
		uname -a >> $RESULT_TXT 2>&1
		echo "#OS버전확인 /etc/redhat-release ">> $RESULT_TXT 2>&1
		cat /etc/redhat-release >> $RESULT_TXT 2>&1
		
		echo "#설치패키지확인 rpm -qa ">> $REF_FILE 2>&1
		rpm -qa >> $REF_FILE 2>&1
	fi
	
	#AIX
	if [ $OS_STR = "AIX" ]
	then
		echo "#uname -a 확인" >> $RESULT_TXT 2>&1
		uname -amML >> $RESULT_TXT 2>&1
		echo "" >> $RESULT_TXT 2>&1
		echo "#패치버전확인" >> $RESULT_TXT 2>&1
		oslevel -s >> $RESULT_TXT 2>&1
		echo "" >> $RESULT_TXT 2>&1
		
		echo "#OS버전 확인" >> $REF_FILE 2>&1
		instfix -i | grep ML >> $REF_FILE 2>&1
		echo "" >> $REF_FILE 2>&1
		echo "#설치패키지확인" >> $REF_FILE 2>&1
		lslpp -l >> $REF_FILE 2>&1
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# NTP 및 시각 동기화 설정
U_65_ntp() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="NTP 및 시각 동기화 설정"
	Item_head "U-65" "$iTitle" "$iCODE"
	
	Result="수동점검"
	Exp="$REF_FILE 참고하여 수동진단"
	Evi=""
	
	echo "#NTP 설정 및 현재 동기화된 서버는 ref 파일 참조 확인" >> $RESULT_TXT 2>&1
	echo "" >> $RESULT_TXT 2>&1
	
	case $OS_STR in
		AIX | SunOS | HP-UX)
		#AIX, SunOS, HP-UX: 
			echo "#동기화된 NTP 서버 확인" >> $REF_FILE 2>&1
			ntpq -pn >> $REF_FILE 2>&1
		;;
	
		Linux)
		#Linux:
			echo "#Redhat 계열 리눅스는 RHEL 8 버전부터 Chrony 서비스로 변경됨" >> $RESULT_TXT 2>&1
		
			echo "#동기화된 NTP 서버 확인(NTP)" >> $REF_FILE 2>&1
			ntpq -pn >> $REF_FILE 2>&1
			
			echo " " >> $RESULT_TXT 2>&1
			echo "#동기화된 NTP 서버 확인(Chrony)" >> $REF_FILE 2>&1
			chronyc sources >> $REF_FILE 2>&1
		;;
	
		*)
		#
		;;
	esac
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 정책에 따른 시스템 로깅 설정
U_66_syslog() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="정책에 따른 시스템 로깅 설정"
	Item_head "U-66" "$iTitle" "$iCODE"
	
	Result="수동점검"
	Exp="로깅 정책 확인, syslog 전체 설정은 REF파일 참조"
	Evi=""

	#HP-UX
	if [ -f /etc/syslog.conf ]
		then
			echo "#cat /etc/syslog.conf | egrep 'info|notice|warn|err'" >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
			cat /etc/syslog.conf | egrep "info|notice|warn|err" >> $RESULT_TXT 2>&1
			
			echo "#cat /etc/syslog.conf" >> $REF_FILE 2>&1
			echo " " >> $REF_FILE 2>&1
			cat /etc/syslog.conf >> $REF_FILE 2>&1
	fi
	
	if [ -f /etc/rsyslog.conf ]
		then
			echo "#cat /etc/rsyslog.conf | egrep 'info|notice|warn|err'" >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
			cat /etc/rsyslog.conf | egrep "info|notice|warn|err" >> $RESULT_TXT 2>&1
			
			echo "#cat /etc/rsyslog.conf" >> $REF_FILE 2>&1
			echo " " >> $REF_FILE 2>&1
			cat /etc/rsyslog.conf >> $REF_FILE 2>&1
	fi
	
	echo " " >> $RESULT_TXT 2>&1
	Item_foot "$Result" "$Exp" "$Evi"
}

# 로그 디렉터리 소유자 및 권한 설정
U_67_log_permission() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="로그 디렉터리 소유자 및 권한 설정"
	Item_head "U-67" "$iTitle" "$iCODE"
	
	case $OS_STR in
		Linux)
		#Linux:
			TARGET_FILE="/var/log/boot.log /var/log/cron /var/log/messages /var/log/secure"
		;;
		
		SunOS)
		#SunOS:
			TARGET_FILE="/var/adm/messages /var/adm/utmpx /var/adm/wtmpx /var/adm/messages /var/adm/loginlog /var/adm/lastlog /var/adm/sulog /var/log/authlog /var/log/syslog"
		;;
		
		AIX)
		#AIX:
			TARGET_FILE="/var/adm/messages /usr/adm/wtmp /etc/security/failedlog /etc/security/lastlog /var/adm/cron/log"
		;;
		
		HP-UX)
		#HP-UX:
		;;
		*)
		;;
	esac
	
	if [ $OS_STR = "HP-UX" ]
	then
		Result="수동점검"
		Exp="레퍼런스 참고 할 것"
		Evi=""
	else
		for check_file in $TARGET_FILE
		do
			FILE_LIST="$FILE_LIST$check_file "
			if [ -f $check_file ]
				then
					perm_check $check_file

					if [ $uPn -gt 6 -o $gPn -gt 4 -o $oPn -gt 0 ]
						then
						REGUL_SET="$REGUL_SET$check_file "
					fi
			fi
		done
		if [ "$REGUL_SET" != "" ]
			then
				Result="취약"
				Exp="로그 파일의 접근권한이 과도하게 설정되어 있으므로 취약함"
				Evi=`ls -alL $REGUL_SET`
			else
				Result="양호"
				Exp="로그 파일의 접근권한이 적절하게 설정되어 있으므로 양호함"
				Evi=`ls -alL $FILE_LIST`
		fi
	fi
		
	#LINUX
	if [ -d /var/log ]
		then
			echo "#ls -alL /var/log" >> $RESULT_TXT 2>&1
			ls -alL /var/log >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
	fi
	
	#SunOS
	if [ -f /var/adm ]
		then
			echo "#ls -alL /var/adm" >> $RESULT_TXT 2>&1
			ls -alL /var/adm >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
	fi
	
	if [ -f /usr/adm ]
		then
			echo "#ls alL /usr/adm" >> $RESULT_TXT 2>&1
			ls ?alL /usr/adm >> $RESULT_TXT 2>&1
	fi
	
	echo "1) 로그 파일의 접근권한" >> $RESULT_TXT 2>&1
	ls -alL $FILE_LIST >> $RESULT_TXT 2>&1
	
	#AIX, HP-UX
	if [ -d /var/adm ]
		then
			echo "#ls -alL /var/adm" >> $RESULT_TXT 2>&1
			ls -alL /var/adm >> $RESULT_TXT 2>&1
			echo " " >> $RESULT_TXT 2>&1
	fi
	
	if [ -d /usr/adm ]
		then
			echo "#ls -alL /usr/adm" >> $RESULT_TXT 2>&1
			ls -alL /usr/adm >> $RESULT_TXT 2>&1
	fi
	
	Item_foot "$Result" "$Exp" "$Evi"
	
    unset TARGET_FILE
    unset OWNER_PERM
    unset GROUP_PERM
    unset OTHER_PERM
    unset REGUL_SET
    unset FILE_LIST
}

# C 컴파일러 존재 및 권한 설정 오류
c_compiler() {
	iCODE=`printf "%s-%02d" "$Systype"  $Item_No`
	iTitle="C 컴파일러 존재 및 권한 설정 오류"
	Item_head "ETC" "$iTitle" "$iCODE"
	
	Result="수동점검"
	Exp="확인"
	Evi=""
	
	case $OS_STR in
		Linux)
		#Linux:
			TARGET_FILE="/usr/local/bin/gcc /usr/bin/gcc"
		;;
		
		SunOS)
		#SunOS:
			TARGET_FILE="/usr/ucb/cc /usr/local/bin/gcc /usr/bin/gcc"
		;; 
		
		AIX)
		#AIX:
			TARGET_FILE="/usr/vac/bin/xlc /usr/local/bin/gcc /usr/bin/gcc"
		;;
		
		HP-UX)
		#HP-UX:
			TARGET_FILE="/opt/aCC/bin/aCC /usr/local/bin/gcc /usr/bin/gcc"
		;;
		*)
		;;
	esac
	
	for check_file in $TARGET_FILE
		do
			FILE_LIST="$FILE_LIST$check_file "
			if [ -f $check_file ]
				then
					perm_check $check_file
					
					#if [ $oPn -eq 1 -o  $oPn -eq 3 -o  $oPn -eq 5 ]
					if [ `echo $oPerm | cut -c3-3` = "x" ]
						then
							REGUL_SET="$REGUL_SET$check_file "
					fi
			fi
	done
	
	if [ "$REGUL_SET" != "" ]
		then
			Result="취약"
			Exp="C 컴파일러의 접근권한이 과도하게 설정되어 있으므로 취약함"
			Evi=`ls -alL $FILE_LIST`
		else
			Result="양호"
			Exp="C 컴파일러의 접근권한이 적절하게 설정되어 있으므로 양호함"
			Evi=`ls -alL $FILE_LIST`
	fi
		
	Item_foot "$Result" "$Exp" "$Evi"
	
    unset TARGET_FILE
    unset OWNER_PERM
    unset GROUP_PERM
    unset OTHER_PERM
    unset REGUL_SET
    unset FILE_LIST
}

#================================================================================
# 진단 스크립트 완료
#================================================================================

#================================================================================
# 진단 시작
#================================================================================
# Solaris 버전 체크
sol_ver_check

# 알림 출력
show_notice

# 결과 파일 존재 여부 체크
file_check

# xml 시작
xml_start

# 서비스 점검
FTP_check
TELNET_check
#APACHE_check

Systype="U"

# 진단 스크립트 수행 및 결과 기록
# Category 1
Item_Group="1"
Item_No=1


	U_01_remote_root
	U_02_password_complex
	U_03_account_lock
	U_04_shadow
	U_05_root_uid
	U_06_su_restrict
	U_07_disused_account
	U_08_root_group
	U_09_gid_not_account
	U_10_same_uid
	U_11_user_shell
	U_12_session_timeout
	U_13_password_encrypt
	
	U_14_root_path
	U_15_nouser_nogroup
	U_16_passwd_permission
	U_17_start_script_permission
	U_18_shadow_permission
	U_19_hosts_permission
	U_20_xindetd_permission
	U_21_syslog_permission
	U_22_services_permission
	U_23_suid_sgid_sticky
	U_24_profile_permission
	U_25_world_writable
	U_26_device_not_exists
	U_27_rhosts
	U_28_hosts_allow
	U_29_host_lpd
	U_30_user_umask
	#root_umask
	U_31_user_home_dir
	U_32_user_home_not_exists
	U_33_hidden_files
	
	U_34_finger
	U_35_anonymous_disabled
	U_36_r_services
	U_37_cron_permission
	U_38_dos
	U_39_nfs
	U_40_nfs_dfstab
	U_41_automountd
	U_42_rpc
	U_43_nis
	U_44_tftp_talk
	U_45_mail_service_ver
	U_46_mail_restrictqrun
	U_47_spam_mail_relay_reject
	U_48_mail_expn_vrfy
	U_49_dns_patch
	U_50_dns_zone_transfer
	U_51_dns_dynamic_update
	U_52_telnet_disabled
	U_53_ftp_banner
	U_54_ftp
	U_55_ftp_noshell
	U_56_ftp_acl
	U_57_ftp_root_deny
	U_58_snmp
	U_59_snmp_version
	U_60_snmp_community
	U_61_snmp_acl
	U_62_login_banner
	U_63_sudoers_permission
	U_64_latest_patch
	
	U_65_ntp
	U_66_syslog
	U_67_log_permission
	
	
#	nis
#	ssh_ver
	
# Category 2
Item_Group="2"
Item_No=1


#root_path_permission

#if [ $OS_STR = "SunOS" ]
#then
#Default_Skeleton
#kernel_param
#tcp_sequence
#fi

# Category 3
Item_Group="3"
Item_No=1

	

# Category 4
Item_Group="4"
Item_No=1


	#c_compiler

echo "	</ResultData>" >> $RESULT_FILE 2>&1

#================================================================================
# 진단 완료
#================================================================================

#================================================================================
# 추가 정보 기록
#================================================================================
# 시스템 정보 기록
echo "	<Info>" >> $RESULT_FILE 2>&1
echo "		<sVersion>" >> $RESULT_FILE 2>&1
echo "			<![CDATA[" >> $RESULT_FILE 2>&1
uname -a >> $RESULT_FILE 2>&1
echo "Host Name : $HOST_NAME" >> $RESULT_FILE 2>&1
echo "			]]>" >> $RESULT_FILE 2>&1
echo "		</sVersion>" >> $RESULT_FILE 2>&1

# 네트워크 정보 기록
echo "		<Nic>" >> $RESULT_FILE 2>&1
echo "			<![CDATA[" >> $RESULT_FILE 2>&1
ifconfig -a >> $RESULT_FILE 2>&1
echo "			]]>" >> $RESULT_FILE 2>&1
echo "		</Nic>" >> $RESULT_FILE 2>&1

# Process 정보 기록
echo "		<Processes>" >> $RESULT_FILE 2>&1
echo "			<![CDATA[" >> $RESULT_FILE 2>&1
ps -ef | sort >> $RESULT_FILE 2>&1
echo "			]]>" >> $RESULT_FILE 2>&1
echo "		</Processes>" >> $RESULT_FILE 2>&1

# 종료시간 기록
run_time
echo "	</Info>" >> $RESULT_FILE 2>&1
echo "</CVCResult>" >> $RESULT_FILE 2>&1

#================================================================================
# 결과 파일 정리
#================================================================================
unset Systype
unset Item_Group
unset Item_No

tar -cf $TAR_FILE $RESULT_FILE $RESULT_TXT $REF_FILE

rm -rf path_httpd
rm -rf snmp_tmp
rm -rf tmp_httpd.txt

rm -rf $RESULT_FILE
rm -rf $RESULT_TXT
rm -rf $REF_FILE

echo ""
echo "############################################ [ F I N I S H ]"
echo ""
echo ""
