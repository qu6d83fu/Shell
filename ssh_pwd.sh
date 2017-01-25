#!/bin/bash
#HOST=192.168.0.1
FIRST="1"
LAST="255"
HOST="192.168.0."
PWD="sshpass -p SoundYes8851"
USER=(soundyes rtiivp voir)
LOG=`basename $0`.log
:>$LOG
#read -p "Enter the IP or hostname " HOST
#Change the sshd_config PasswordAuthentication to the designated argument.
read -p "Change the AUTH to (yes/no) " CHG_AUTH
while [ $LAST -gt $FIRST ]
do
	ping -c 1 -w 1 ${HOST}${FIRST}
	RETVAL=$?
	if [ $RETVAL -eq 0 ] ; then 
		i=0
		#Check the give of  users.
		while [ ${#USER[@]} -gt $i ]
		do
		$PWD ssh ${USER[$i]}@${HOST}${FIRST} "echo connection sucessed" >>$LOG
			RETVAL=$?
			#If ssh sucessed then check the PasswordAuthentication argument.
			if [ $RETVAL -eq 0 ] ; then
					AUTH=`$PWD ssh -t ${USER[i]}@${HOST}${FIRST} "sudo cat /etc/ssh/sshd_config | grep '^PasswordAuthentication' | cut -d ' ' -f 2"`
					AUTH=`echo $AUTH | tr -d '\r'`
						#If argument already same as you designate,do the next host.
						if [ "$AUTH" == "$CHG_AUTH" ] ; then
							echo "The ${USER[$i]}@${HOST}${FIRST} PWD Authentication almost $CHG_AUTH">> $LOG
							FIRST=`expr $FIRST + 1`
							break
						#If argument not same,change to you designate
						else
							$PWD ssh -t ${USER[$i]}@${HOST}${FIRST} "sudo sed -i 's/^PasswordAuthentication $AUTH/PasswordAuthentication $CHG_AUTH/' /etc/ssh/sshd_config;
		    						         sudo service sshd restart" >>$LOG
							RETVAL=$?
								if [ $RETVAL -eq 0 ] ; then
									echo "Change ${USER[$i]}@${HOST}${FIRST} PWD Authorication to $CHG_AUTH"$LOG
									FIRST=`expr $FIRST + 1`
									break
								else
									echo "Service sshd restart failed"
									FIRST=`expr $FIRST + 1`
									break
								fi
						fi
			elif [ "`expr ${#USER[@]} - 1`" -eq "$i" ] ; then
				echo "${USER[$i]}@${HOST}${FIRST} not exist">>$LOG
				i=`expr $i + 1`
				FIRST=`expr $FIRST + 1`
			else
				echo "${USER[$i]}@${HOST}${FIRST} not exist">>$LOG
				i=`expr $i + 1`
			fi
		done
	else
		echo "${HOST}${FIRST} not exist" >>$LOG
		FIRST=`expr $FIRST + 1`
	fi
done
