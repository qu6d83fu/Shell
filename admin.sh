#!/bin/bash
PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr:/usr/local/bin:/usr/local/sbin
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )"&& pwd)"
source $CURRENT_DIR/sy_common.sh

#global variables
PROC_NAME=$(basename $0 .sh)
TIME=$(date +%Y%m%d)
HOST=$(hostname)
REPORT_SUBJECT="Backup Host ${HOST}"
MAIL_SUBJECT="${REPORT_SUBJECT} (${START_TIMESTAMP} - ${END_TIMESTAMP})"
MAIL_BIN=""
MAIL_SERVER=""
LOCAL_PATH="${HOME}/backup"
TAR_FILE_NAME="${HOST}_${TIME}_bak.tar.gz"
BACKUP_CONF="${CONF_DIR}/backup.conf"
BACKUP_EX="${CONF_DIR}/backup.ex"
BACKUP_RETENTION_DAYS=9

USAGE(){
echo " Usage [Option] [arguments]"
echo " -l local backup"
echo " --path-nfs path  Enter the path of your nfs path"
echo " --path-s3  path  Enter the path of your AWS s3 path"
exit 1
}

LOCAL(){
local local_path=$1
local tar_file_name=$2
local backup_conf=$3
local backup_ex=$4
local backup_retention_days=$5

sudo tar zcvf ${local_path}/${tar_file_name} -T ${backup_conf} --exclude-from=${backup_ex} > /dev/null 2>&1
if [ $? -eq 2 ] ; then
	logger -st OAM "Local backup succeed." 2>> $LOG_FILE
else
	logger -st OAM "Local backup failed." 2>> $LOG_FILE
	exit
fi

#purge tar_file
purge_count=$(find ${local_path} -maxdepth 1 -mtime +${backup_retention_days} | wc -l)
if [ $purge_count -gt 0 ] ; then
        logger -st OAM "Purge backup file from local path,$backup_retention_days days ago." 2>> $LOG_FILE
        find ${local_path} -maxdepth 1 -mtime +${backup_retention_days} -exec rm -rf '{}' \;
        if [ $? -eq 0 ] ; then
	        logger -st OAM "succeed to purge old backup file from local path." 2>> $LOG_FILE
        else
	        logger -st OAM "failed purge old backup file from local path." 2>> $LOG_FILE
        fi
fi
}

NFS(){
local nfs_path=$1
local local_path=$2
local tar_file_name=$3
local backup_retention_days=$4
ls ${nfs_path} > /dev/null 2>&1
if [ "$?" -eq "0" ] ; then 
	logger -st OAM "Test the NFS path exist." 2>> $LOG_FILE
	cp ${local_path}/${tar_file_name} ${nfs_path}
	if [ "$?" -eq "0" ] ; then
		logger -st OAM "Copy local tar_file to NFS susseced." 2>> $LOG_FILE
	else
		logger -st OAM "Copy tar_file to NFS failed." 2>> $LOG_FILE
		exit 1
	fi
else
	logger -st OAM "NFS path not exist,checking the path you gived." 2>> $LOG_FILE
	exit 1
fi

#purge tar_file 
purge_count=$(find ${nfs_path} -maxdepth 1 -mtime +${backup_retention_days} | wc -l)
if [ $purge_count -gt 0 ] ; then
	logger -st OAM "Purge backup file from NFS path,$backup_retention_days days ago." 2>> $LOG_FILE
	find ${nfs_path} -maxdepth 1 -mtime +${backup_retention_days} -exec rm -rf '{}' \;
	if [ $? -eq 0 ] ; then
		logger -st OAM "succeed to purge old backup file from NFS path." 2>> $LOG_FILE
	else
		logger -st OAM "failed purge old backup file from NFS path." 2>> $LOG_FILE
	fi
fi
}

SCP(){
local scp_path=$1
local local_path=$2
local tar_file_name=$3
scp -P 1235 $local_path/$tar_file_name $scp_path
}

#Check the arguments,if not existing exit the script.
if [ "$#" -eq "0" ] ; then
	logger -st OAM "No arguments gives,please enter the backup type." 2>> $LOG_FILE
	USAGE
fi

#Check the config and exlude file, if not exiting exit the script.
[ -f $BACKUP_CONF ] || (touch $BACKUP_CONF && logger -st OAM "$BACKUP_CONF not exiting create the new config file" 2>>$LOG_FILE)
[ -f $BACKUP_EX ]  || (touch $BACKUP_EX && logger -st OAM "$BACKUP_EX not exiting create the new exclude file" 2>>$LOG_FILE)
[ ! -s $BACKUP_CONF ] && echo "$BACKUP_CONF is empty" && logger -st OAM "$BACKUP_CONF is empty." 2>>$LOG_FILE&& exit 1

#Backup the local file and arguments path.
while [ "$#" -gt "0" ] ; do
case $1 in
"-l")
#       [ -n $2 ] && USAGE && break
        LOCAL $LOCAL_PATH $TAR_FILE_NAME $BACKUP_CONF $BACKUP_EX $BACKUP_RETENTION_DAYS
        shift
        ;;
"--scp")
	[ -z $2 ] && USAGE && break
	SCP_PATH=$2
	SCP $SCP_PATH $LOCAL_PATH $TAR_FILE_NAME 
	shift
	shift
	;;
"--path-nfs")
        [ -z $2 ] && USAGE && break
        NFS_PATH=$2
        LOCAL $LOCAL_PATH $TAR_FILE_NAME $BACKUP_CONF $BACKUP_EX $BACKUP_RETENTION_DAYS
        NFS $NFS_PATH $LOCAL_PATH $TAR_FILE_NAME $BACKUP_RETENTION_DAYS
        shift
        shift
        ;;
"--path-s3")
        S3_PATH=$2
        LOCAL $LOCAL_PATH $TAR_FILE_NAME $BACKUP_CONF $BACKUP_EX $BACKUP_RETENTION_DAYS
        S3
        shift
        shift
        ;;
"--path-other")
        OTHER_PATH=$2
        LOCAL $LOCAL_PATH $TAR_FILE_NAME $BACKUP_CONF $BACKUP_EX $BACKUP_RETENTION_DAYS
        OTHER
        shift
        shift
        ;;
--help|-H)
        USAGE
        break
        ;;
*)
        USAGE
        break
        ;;
esac
done
