#!/bin/bash
##############################
# backup 
# conf : ~/.audit/conf/backup.conf
# backup_strategy :
# NFS   : backup on NFS
# S3    : backup on S3
# MIXED : backup on NFS and S3
##############################
# source
CURRENT_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${CURRENT_DIR}/common_util.sh

# get arguments
PROJECT=$1
ENV=$2
SITE_ID=$3
BACKUP_STRATEGY=$4
if [ "$#" -lt "4" ]; then
	echo "arguments : project_id env site_id backup stragegy"
	echo "usage example: backup.sh bddo p aa NFS"
	logger "insufficient arugments" | tee -a $LOG
fi

# global variables
PROC_NAME=$(basename $0 .sh)
REPORT_SUBJECT="Buddydo Prod Audit.Backup - Host [$(hostname)]"
MAIL_SUBJECT="${REPORT_SUBJECT} (${START_TIMESTAMP} - ${END_TIMESTAMP})"
MAIL_BIN="${UTIL_DIR}/sendEmail"
MAIL_SERVER="10.100.201.201"
BACKUP_TAR_FILE_NAME="$(hostname)_bak_$(date +%Y%m%d%H%M).tar.gz"
BACKUP_CONF="${CONF_DIR}/${PROC_NAME}.conf"
LOCAL_BACKUP_PATH="${TMP_DIR}/${BACKUP_TAR_FILE_NAME}"
NFS_DIR="${HOME}/NFS"
NFS_BACKUP_RETENTION_DAYS=5
S3_BUCKET="${PROJECT}-${ENV}-${SITE_ID}-backup"
S3_PARTITION="$(date +%Y)/$(date +%m)/$(date +%d)"
S3_BACKUP_PATH="s3://${S3_BUCKET}/ec2/$(hostname)/${S3_PARTITION}"

function backup_to_local() {
	local backup_tar_file_name=$1
	local backup_conf=$2
	local tmp_dir=$3
	local log_file=$4

	# tar backup by read config file
	logger "tar backup file $backup_tar_file_name to local $tmp_dir" | tee -a $log_file
	tar -zcvf ${tmp_dir}/${backup_tar_file_name} -T $backup_conf
	if [ "$?" -eq "0" ]; then
		logger "succeed to tar backup file" | tee -a $log_file
	else
		logger "failed to tar backup file" | tee -a $log_file
		exit 11
	fi
}

function backup_to_nfs() {
	local local_backup_path=$1
	local nfs_dir=$2
	local backup_retention_days=$3
	test -z $backup_retention_days && backup_retention_days=180
	local log_file=$4
	local nfs_backup_dir="${nfs_dir}/$(hostname)"

	# if nfs cannot be accessed, then exit
	logger "check if nfs [${nfs_dir}] can be accessed" | tee -a $log_file
	ls $nfs_dir
	if [ "$?" -eq "0" ]; then
		logger "succeed to access nfs" | tee -a $LOG_FILE
	else
		logger "failed to access nfs" | tee -a $LOG_FILE
		exit 12
	fi

	# if nfs backup dir doesn't exist and cannot create it for backup, then exit
	logger "check if nfs backup dir can be created" | tee -a $log_file
	test -d $nfs_backup_dir || mkdir $nfs_backup_dir
	if [ "$?" -eq "0" ]; then
		logger "succeed to create nfs backup dir" | tee -a $LOG_FILE
	else
		logger "failed to creat nfs backup dir" | tee -a $LOG_FILE
		exit 13
	fi

	logger "cp $local_backup_path to nfs folder [${nfs_dir}]" | tee -a $log_file
	cp $local_backup_path $nfs_backup_dir
	if [ "$?" -eq "0" ]; then
		logger "succeed to cp backup file to nfs folder" | tee -a $LOG_FILE
	else
		logger "failed to cp backup file to nfs folder" | tee -a $LOG_FILE
		exit 14
	fi

	purge_count=$(find $nfs_backup_dir -maxdepth 1 -mtime +${backup_retention_days} | wc -l)
	if [ $purge_count -gt 0 ]; then
		logger "purge backup files from nfs $nfs_backup_dir $backup_retention_days days ago" | tee -a $LOG_FILE
		find $nfs_backup_dir -maxdepth 1 -type f -mtime +${backup_retention_days} -exec rm '{}' \;
		if [ "$?" -eq "0" ]; then
			logger "succeed to purge old backup files from nfs folder" | tee -a $LOG_FILE
		else
			logger "failed purge cp backup files from nfs folder" | tee -a $LOG_FILE
			exit 15
		fi
	fi
}

function backup_to_s3() {
	local local_backup_path=$1
	local s3_backup_path=$2
	local log_file=$3

	logger "cp $local_backup_path to s3 path [${s3_backup_path}]" | tee -a $log_file
	aws s3 cp $local_backup_path $s3_backup_path
	if [ "$?" -eq "0" ]; then
		logger "succeed to cp backup file to s3 backup path" | tee -a $LOG_FILE
	else
		logger "failed to cp backup file to s3 backup path" | tee -a $LOG_FILE
		exit 16
	fi
}

function remove_local_backup() {
	local local_backup_path=$1
	local log_file=$2

	# tar backup by read config file
	logger "remove local backup file $local_backup_path" | tee -a $log_file
	rm $local_backup_path 
	if [ "$?" -eq "0" ]; then
		logger "succeed to remove local backup file" | tee -a $log_file
	else
		logger "failed to remove local backup file" | tee -a $log_file
		exit 17
	fi
}
	
# main process
logger "input arguments [$*]" | tee -a $LOG_FILE

case $BACKUP_STRATEGY in
	"NFS")
			logger "backup strategy [${BACKUP_STRATEGY}]" | tee -a $LOG_FILE
			backup_to_local $BACKUP_TAR_FILE_NAME $BACKUP_CONF $TMP_DIR $LOG_FILE
			backup_to_nfs $LOCAL_BACKUP_PATH $NFS_DIR $NFS_BACKUP_RETENTION_DAYS $LOG_FILE
			remove_local_backup $LOCAL_BACKUP_PATH $LOG_FILE
			;;
	"S3")
			logger "backup strategy [${BACKUP_STRATEGY}]" | tee -a $LOG_FILE
			backup_to_local $BACKUP_TAR_FILE_NAME $BACKUP_CONF $TMP_DIR $LOG_FILE
			backup_to_s3 $LOCAL_BACKUP_PATH $S3_BACKUP_PATH $LOG_FILE
			remove_local_backup $LOCAL_BACKUP_PATH $LOG_FILE
			;;
	"MIXED")
			logger "backup strategy [${BACKUP_STRATEGY}]" | tee -a $LOG_FILE
			backup_to_local $BACKUP_TAR_FILE_NAME $BACKUP_CONF $TMP_DIR $LOG_FILE
			backup_to_nfs $LOCAL_BACKUP_PATH $NFS_DIR $NFS_BACKUP_RETENTION_DAYS $LOG_FILE
			backup_to_s3 $LOCAL_BACKUP_PATH $S3_BACKUP_PATH $LOG_FILE
			remove_local_backup $LOCAL_BACKUP_PATH $LOG_FILE
			;;
	*)
			logger "invalid value of argument of backup strategy" | tee -a $LOG_FILE
			exit 10
			;;
esac
