#!/bin/bash
PROC=`basename $0`
NETWORK="192.168.0."
HOST_END_NUMBER=255
HOST_START_NUMBER=1
KEYCOPY="ssh-copy-id"
USER=(soundyes voir rtiivp)
LOG="$PROC.log"
#Change the sshd_config PasswordAuthentication yes to no
ssh_nopwd_auth(){
local user=$1
local host=$2
ssh $usr@$host "test  -d /etc/ssh/sshd_config && \
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config; \
sudo sed -i 's/^wheel:x:10:root$/wheel:x:10:root,$user/' /etc/group; \
sudo /etc/init.d/sshd restart"
}

#SSH client config setting
#Change the flowing command to ssh-copy-id script
#{ eval "$GET_ID" ; } | ssh $1 "umask 077; test -d .ssh
#{ eval "$GET_ID" ; } |sshpass -p PASSWORD ssh $1 "umask 077; test -d .ssh
ssh_config(){
local config=${HOME}/.ssh/config
test -f $config || touch $config
echo  "ConnectTimeout=1" >> $config
echo  "StrictHostKeyChecking=no" >>$config
echo  "ServerAliveInterval=1" >>$config
}
#ssh_config

:>$LOG
#Sending the key to the host
while [ $HOST_START_NUMBER -lt $HOST_END_NUMBER ] 
do
	#Ping the host and checking it alive 
	ping -c 1 -w 1 ${NETWORK}${HOST_START_NUMBER} 2>&1 >/dev/null
	ERROR=$?
	if [ $ERROR -eq 0 ] ; then
		USER_NUM=0
		#Check the giving users
		while [ ${#USER[@]} -ge $USER_NUM ]
		do
			if [ ! ${#USER[@]} -eq $USER_NUM ] ; then
				${KEYCOPY} ${USER[${USER_NUM}]}@${NETWORK}${HOST_START_NUMBER} 2>&1 >/dev/null
				ERROR=$?
				if [ $ERROR -eq 0 ] ; then
					echo "Sucess sended the ssh key to ${USER[${USER_NUM}]}@${NETWORK}${HOST_START_NUMBER}" >> $LOG
#					ssh_nopwd_auth ${USER[${USER_NUM}]} ${NETWORK}${HOST_START_NUMBER}
					HOST_START_NUMBER=`expr $HOST_START_NUMBER + 1` 
					break
				elif [ `expr ${#USER[@]} - 1` -ge ${USER_NUM} ] ; then		
					echo "Failed to send the ssh key to ${USER[${USER_NUM}]}@${NETWORK}${HOST_START_NUMBER}" >> $LOG
					USER_NUM=`expr $USER_NUM + 1`
				fi		
			else
				echo "All of you give Users failed" >> $LOG
				HOST_START_NUMBER=`expr $HOST_START_NUMBER + 1`
				break					
			fi
		done
	else	
		#Host not exist,do next host
		echo "Host ${NETWORK}${HOST_START_NUMBER}  not exist" >> $LOG
		HOST_START_NUMBER=`expr $HOST_START_NUMBER + 1` 
	fi
done
