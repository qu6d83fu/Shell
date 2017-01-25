#!/bin/bash
#export SENDGRID_USER=
#export SENDGRID_PASSWORD=
export LOG=/var/log/nodejs
export PID=/var/log/nodejs/forever.pid
export APP_PATH=/home/soundyes/lifeline
export APP=$APP_PATH/app.js

PROCESS=`pgrep -fl app.js |wc -l`
DETECT=0
start_app()
{
cd $APP_PATH
forever --minUptime 1000 --spinSleepTime 1000 -p $APP_PATH -l $LOG/access.log -e $LOG/error.log -o $LOG/out.log -a --pidFile $PID start app.js
	PROCESS=`pgrep -fl app.js |wc -l`
}

kill_app()
{
        pgrep -fl app.js|awk '{ print $1 }'|xargs kill
	PROCESS=`pgrep -fl app.js |wc -l`
        WEB_FLAG=`curl -s --head --request GET http://localhost:3000 |grep '200 OK'| wc -l`
}
case $1 in
start)
if [ $PROCESS -eq 0 ] ; then
	while [ $PROCESS -eq 0 ]
	do	
		start_app
		if [ $PROCESS -gt 0  ] ; then
			echo "App.js has been started"
		else
			echo "App.js not start,try again"
			start_app
		fi
	done
else
	echo "App.js already started"
	exit 1
fi
;;
stop)
if [ $PROCESS -gt 0 ] ; then
	while [ $PROCESS -gt 0 ]
	do
        	kill_app

        	if [ $PROCESS -eq 0 ] && [ $WEB_FLAG -eq 0 ]; then
                	echo "App.js has been killed, PROCESS=$PROCESS WEB_FLAG=$WEB_FLAG"
                	break
        	else
                	echo "App.js still runing ,try again"
			kill_app
        	fi
	done
else 
	echo "App.js alresdy stop"
fi
;;
*)
	echo "Usage start|stop"
;;
esac
