#!/bin/bash
#####################################
# housekeeping
# 1: interface log
# 2: dota package file
#####################################
# source
CURRENT_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${CURRENT_DIR}/common_util.sh

# global variables
OPTION=$1
PROJECT=$2
ALARM_SUBJECT="${PROJECT} $(hostname) $(CurrentTime): "

case $OPTION in
	"1")
		# interface log
		housekeeping_dir="/home/tasadm/tashome/share/appdata/ods/intflog/intf_web_01"
		retention=180
		deleted_file_list=$(find $housekeeping_dir -maxdepth 1 -type f -mtime +${retention} -exec ls -ltr {} \;)
		test -z "$deleted_file_list" && deleted_file_list="null"
		find $housekeeping_dir -maxdepth 1 -type f -mtime +${retention} -exec rm {} \;
		if [ $? -eq 0 ]; then
			echo -e $(LogHeader) "housekeeping for $housekeeping_dir successfully \nfile list:\n${deleted_file_list}" | tee -a $LOG_FILE
		else
			alarm_message="housekeeping for $housekeeping_dir failed \nfiles list:\n${deleted_file_list}"
			echo -e $(LogHeader) "$alarm_message" | tee -a $LOG_FILE
			echo -e $alarm_message | mail -s "$ALARM_SUBJECT" -r $MAIL_FROM $MAIL_LIST
		fi
		;;
	"2")
		# dota package files
		housekeeping_dir="/home/tasadm/tashome/share/appdata/ods/devicePkg/pkgFile/"
		retention=90
		deleted_file_list=$(find $housekeeping_dir -maxdepth 1 -type d -mtime +${retention} -exec ls -ltrd {} \;)
		test -z "$deleted_file_list" && deleted_file_list="null"
		#find $housekeeping_dir -maxdepth 1 -type d -mtime +${retention} -exec rm {} \;
		find $housekeeping_dir -maxdepth 1 -type d -mtime +${retention} -exec rm -r {} \;
		if [ $? -eq 0 ]; then
			echo -e $(LogHeader) "housekeeping for $housekeeping_dir successfully \nfile list:\n${deleted_file_list}" | tee -a $LOG_FILE
		else
			alarm_message="housekeeping for $housekeeping_dir failed \nfiles list:\n${deleted_file_list}"
			echo -e $(LogHeader) "$alarm_message" | tee -a $LOG_FILE
			echo -e $alarm_message | mail -s "$ALARM_SUBJECT" -r $MAIL_FROM $MAIL_LIST
		fi
		;;
	"*")
		echo nothing to do
		;;
esac
