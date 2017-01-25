#!/bin/bash
#soundyes_backup
CURRENT_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${CURRENT_DIR}/sy_common.sh

#global variables
#PROC_NAME=$(basename $0 .sh)
#CONF_FILE=${CONF_DIR}/${PROC_NAME}.sh
TAR_FILE="`date +%Y%m%d`.tar.gz"
LOCAL_DIR="${BAK_DIR}"
NFS_DIR="/data/backup/$(hostname)"
RETENTION=1             
LOG_RETENTION=15              
#MAIL_SUBJECT=$(hostname)${PROC_NAME}

#backup local
function backup_local(){
local conf_name=(mongod tomcat apache sys sms rsapp)
local conf_file=(${CONF_DIR}/bak_${conf_name[0]}.conf ${CONF_DIR}/bak_${conf_name[1]}.conf ${CONF_DIR}/bak_${conf_name[2]}.conf ${CONF_DIR}/bak_${conf_name[3]}.conf ${CONF_DIR}/bak_${conf_name[4]}.conf ${CONF_DIR}/bak_${conf_name[5]}.conf)
local tar_file=$1
local local_dir=$2
local log_file=$3
    for ((i=0; i<${#conf_file[@]}; i++)); do
        [ -f ${conf_file[i]} ] || touch ${conf_file[i]}
        j=$i
        local strings=${conf_name[$j]}
            if [ -s ${conf_file[i]} ];then
                tar -zcvf ${local_dir}/$(hostname)_${strings}_${tar_file} -T ${conf_file[$i]} >/dev/null 2>&1 
                if [ $? -eq 0 ]; then
                    echo "backup_local $strings succeced" | tee -a $log_file
                else
                    echo "backup_local failed" | tee -a $log_file
                    exit
                fi
            else
                echo "${conf_file[i]} is empty,please entriy  paths in the conf_file."
            fi
    done
}

#backup nfs
function backup_nfs(){
local local_dir=$1
local tar_file=$2
local nfs_dir=$3
local log_file=$4
[ -d $nfs_dir ] || mkdir -p $nfs_dir
cp ${local_dir}/*${tar_file} ${nfs_dir}
    if [ $? -eq 0 ];then
        echo "backup_nfs succeced" | tee -a $log_file
    else 
        echo "backup_nfs failed" | tee -a $log_file
        exit
    fi
}

#remove backup
function remove_backup(){
local local_dir=$1
local tar_file=$2
local nfs_dir=$3
local retention=$4
local log_file=$5
sleep 120
    if [ $(find ${local_dir}/ -mtime ${retention}|wc -l) -gt 0 ];then
        find ${local_dir}/ -mtime +${retention} -exec rm -rf '{}' \;
        echo "removed ${retention}days ago local_tar_file" | tee -a $log_filea
        date|tee -a $log_file
    else
        echo "no ${retention}days ago local_tar_file" | tee -a $log_file
        date|tee -a $log_file
    fi
    if [ $(find ${nfs_dir}/ -mtime ${retention}|wc -l) -gt 0 ];then
        find ${nfs_dir}/ -mtime +${retention} -exec rm -rf '{}' \;
        echo "removed ${retention}days ago nfs_tar_file" | tee -a $log_file
        date|tee -a $log_file
    else
        echo "no ${retention}days ago nfs_tar_file" | tee -a $log_file
        date|tee -a $log_file
        exit
    fi
}
#log_clean
function log_clean(){
local log_dir=$1
local log_retention=$2
    if [ $(find ${log_dir}/ -mtime ${log_retention} |wc -1) -gt 0 ]; then
        find ${log_dir}/ -mtime ${log_retention} -exec rm -rf '{}' \;
        echo "removed ${log_retention} days ago log file" | tee -a $log_file
    else
        echo "no ${log_retention} days ago log file" | tee -a $log_file
    fi
}
#backup section
backup_local $TAR_FILE $LOCAL_DIR $LOG_FILE
backup_local_check=$?
backup_nfs $LOCAL_DIR $TAR_FILE $NFS_DIR $LOG_FILE
backup_nfs_check=$?
    if [ $backup_local_check = $backup_nfs_check ]; then
        remove_backup $LOCAL_DIR $TAR_FILE $NFS_DIR $RETENTION $LOG_FILE
        if [ $? = 0 ]; then
            echo "remove backup_file succeced" | tee -a $LOG_FILE
        else
            echo "remove backup_file failed" | tee -a $LOG_FILE
            exit
        fi
        else
            echo "backup_check have failed" | tee -a $LOG_FILE
    fi
#DB record
DATE="`date +%Y%m%d"-"%H":"%M"
HOST="`hostname`"
LOCAL_B="$backup_local_check"
NFS_B="$backup_nfs_check"
MYSQL="mysql -usoundyes -psoundyes -h 192.168.0.112 soundyes -e"
CMD="insert into sy_backup set DATE='$DATE',HOST='$HOST',LOCAL_BACK='$LOCAL_B',NFS_BACK='$NFS_B';" 
$MYSQL "$CMD"
