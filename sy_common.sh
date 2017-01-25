#!/bin/bash
PROC_NAME="`basename $0`"
BAK_DIR="${HOME}/.audit/bak"
		[ -d $BAK_DIR ] || mkdir -p $BAK_DIR
CONF_DIR="${HOME}/.audit/conf"
		[ -d $CONF_DIR ] || mkdir -p $CONF_DIR
LOG_DIR="${HOME}/.audit/log"
		[ -d $LOG_DIR ] || mkdir -p $LOG_DIR
LOG_FILE=${LOG_DIR}/${PROC_NAME}.log.`date +%d`
if [ -f $LOG_FILE ]; then
		if [ ! `find $LOG_FILE -mtime -1 | wc -l` = 1 ]; then
		: > $LOG_FILE
	fi
fi

