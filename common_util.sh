#!/bin/bash
PROC_NAME="`basename $0`"
TMP_DIR="${HOME}/.audit/tmp"
		[ -d $TMP_DIR ] || mkdir -p $TMP_DIR
SQL_DIR="${HOME}/.audit/sql"
		[ -d $SQL_DIR ] || mkdir -p $SQL_DIR
CONF_DIR="${HOME}/.audit/conf"
		[ -d $CONF_DIR ] || mkdir -p $CONF_DIR
LOG_DIR="${HOME}/.audit/log"
		[ -d $LOG_DIR ] || mkdir -p $LOG_DIR
KEY_DIR="${HOME}/.audit/key"
		[ -d $KEY_DIR ] || mkdir -p $KEY_DIR
LOG_FILE=${LOG_DIR}/${PROC_NAME}.log.`date +%d`
if [ -f $LOG_FILE ]; then
		if [ ! `find $LOG_FILE -mtime -1 | wc -l` = 1 ]; then
		: > $LOG_FILE
	fi
fi

MAIL_FROM="dotaoam"
MAIL_LIST="joelin@truetel.com"

LogHeader() {
	HEADER="`date +'%Y/%m/%d %H:%M:%S'` `uname -n` ${PROC_NAME} PID($$):"
	echo $HEADER
}

CurrentTime() {
	date '+%Y/%m/%d %H:%M:%S (%Z)'
}
