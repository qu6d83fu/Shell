#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
NTPSERVER=(tw.pool.ntp.org watch.stdtime.gov.tw tick.stdtime.gov.tw time.stdtime.gov.tw tock.stdtime.gov.tw)
CHECK=1
CURRENT_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_DIR="${HOME}/logs"
LOG="ntpdate.log"
TIMESTAMP=`date +%Y%m%d'-'%H':'%M':'%S`



while [ $CHECK -eq 1 ]
do
	for ((i=0; i<${#NTPSERVER[@]}; i++)) ;
		do
			sudo ntpdate ${NTPSERVER[i]} 2>&1 >/dev/null && sudo hwclock -w
			CHECK=$?
			if [ $CHECK -eq 0 ] ; then
				echo "$TIMESTAMP Check ntpdate time from ${NTPSERVER[i]} sucessed" >> ${LOG_DIR}/${LOG}
				break
			else 
				echo "$TIMESTAMP ${NTPSERVER[i]} Synchronous error" >> ${LOG_DIR}/${LOG}
			fi
		done
done
