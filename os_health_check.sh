#!/bin/bash
#####################################
# operation system health check
# 1: cpu utilization
# 2: unused memmory
# 3: disk usage - you can add mounted path into ~/.audit/conf/mounted_path_list.txt for check
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
		# cpu check
		cpu_threshold="70"
		consecutive_times="3"
		# buffer times is used to slow down the sending period when current consecutive times is greater than buffer times
		buffer_times="5"
		consecutive_counter_file="${CONF_DIR}/cpu_consecutive_counter.txt"
		consecutive_counter=$(cat $consecutive_counter_file)
		test -z $consecutive_counter && consecutive_counter="0"
		cpu_utilization_total="0"

		# count average of 30 times of geting data
		for ((i=0; i<30; i++))
		do
			cpu_utilization=$(mpstat -P ALL | awk 'NR==4{print $4+$6}')
			cpu_utilization_total=$(echo "scale=2; $cpu_utilization_total + $cpu_utilization" | bc)
			sleep 1.8 
		done
		cpu_utilization_average=$(echo "scale=2; $cpu_utilization_total / 30" | bc)

		# if cpu utilization average is greater than or equal to threshold, consecutive counter + 1
		if [ "$(echo "$cpu_utilization_average >= $cpu_threshold" | bc)" == "1" ]; then
			consecutive_counter=$(($consecutive_counter+1))	
			echo "$consecutive_counter" > $consecutive_counter_file
			echo -e $(LogHeader) "CPU Utilization (${cpu_utilization_average}%) is greater than or equal to ${cpu_threshold}%"
		else
			if [ "$(echo "$consecutive_counter >= $consecutive_times" | bc)" == "1" ]; then
				alarm_cleared_message="Alarm Cleared ! CPU Utilization (${cpu_utilization_average}%) is lower than ${cpu_threshold}% !!"
				echo $alarm_cleared_message | mail -s "$ALARM_SUBJECT" -r $MAIL_FROM $MAIL_LIST
				# log normal status but alarm cleared
				echo $(LogHeader) "$alarm_cleared_message" | tee -a $LOG_FILE
			else
				# log normal status
				echo -e $(LogHeader) "CPU Utilization (${cpu_utilization_average}%) is lower than ${cpu_threshold}%" | tee -a $LOG_FILE
			fi
			# set consecutive counter to zero
			consecutive_counter="0"	
			echo "$consecutive_counter" > $consecutive_counter_file
		fi

		echo -e $(LogHeader) "current consecutive times status is $consecutive_counter, consecutive times = $consecutive_times" | tee -a $LOG_FILE

		# if consecutive counter is greater than or equal to threshold, send alarm email
		if [ "$(echo "$consecutive_counter >= $consecutive_times" | bc)" == "1" ]; then
			# sending alarm when current consecutive times lower than or equal to buffer times
			if [ "$(echo "$consecutive_counter <= $buffer_times" | bc)" == "1" ]; then
				alarm_message="Alarm Fired ! CPU Utilization (${cpu_utilization_average}%) is greater than or equal to ${cpu_threshold}% !!"
				alarm_message="$alarm_message, consecutive times is $consecutive_times"
				alarm_message="$alarm_message, current consecutive times status is $consecutive_counter"
				echo -e $(LogHeader) "$alarm_message" | tee -a $LOG_FILE
				echo -e $alarm_message | mail -s "$ALARM_SUBJECT" -r $MAIL_FROM $MAIL_LIST
			# sending alarm only when current consecutive times mod buffer times = 0, it means it will send alarm every "buffer times" consecutive times
			elif [ "$(echo "$consecutive_counter % $buffer_times == 0" | bc)" == "1" ]; then
				alarm_message="Alarm Fired ! CPU Utilization (${cpu_utilization_average}%) is greater than or equal to ${cpu_threshold}% !!"
				alarm_message="$alarm_message, consecutive times is $consecutive_times"
				alarm_message="$alarm_message, current consecutive times status is $consecutive_counter"
				echo -e $(LogHeader) "$alarm_message" | tee -a $LOG_FILE
				echo -e $alarm_message | mail -s "$ALARM_SUBJECT" -r $MAIL_FROM $MAIL_LIST
			# log alarm status, but won't fire alarm
			else
				alarm_message="Alarm Not Fired ! CPU Utilization (${cpu_utilization_average}%) is greater than or equal to ${cpu_threshold}% !!"
				alarm_message="$alarm_message, consecutive times is greater than $buffer_times"	
				alarm_message="$alarm_message, current consecutive times status is $consecutive_counter"
				echo -e $(LogHeader) "$alarm_message" | tee -a $LOG_FILE
			fi
		fi
		;;
	"2")
		# memory check
		unused_memory_threshold="20"
		consecutive_times="5"
		# buffer times is used to slow down the sending period when current consecutive times is greater than buffer times
		buffer_times="5"
		consecutive_counter_file="${CONF_DIR}/unused_memory_consecutive_counter.txt"
		consecutive_counter=$(cat $consecutive_counter_file)
		test -z $consecutive_counter && consecutive_counter="0"
		unused_memory_total="0"

		# count average of 30 times of geting data
		for ((i=0; i<30; i++))
		do
			total_memory=$(vmstat -s | awk 'NR==1{print $1}')
			inactive_memory=$(vmstat -s | awk 'NR==4{print $1}')
			free_memory=$(vmstat -s | awk 'NR==5{print $1}')
			buffer_memory=$(vmstat -s | awk 'NR==6{print $1}')
			unused_memory=$(($inactive_memory+$free_memory+$buffer_memory))
			unused_memory_percentage=$(echo "scale=5; $unused_memory / $total_memory * 100" | bc)
			unused_memory_total=$(echo "scale=2; $unused_memory_total + $unused_memory_percentage" | bc)
			sleep 1.8
		done
		unused_memory_average=$(echo "scale=2; $unused_memory_total / 30" | bc)

		# if unused memory average is lower than or equal to threshold, consecutive counter + 1
		if [ "$(echo "$unused_memory_average <= $unused_memory_threshold" | bc)" == "1" ]; then
			consecutive_counter=$(($consecutive_counter+1))	
			echo "$consecutive_counter" > $consecutive_counter_file
			echo -e $(LogHeader) "Unused Memory (${unused_memory_average}%) is lower than or equal to ${unused_memory_threshold}%"
		else
			if [ "$(echo "$consecutive_counter >= $consecutive_times" | bc)" == "1" ]; then
				alarm_cleared_message="Alarm Cleared ! Unused Memory (${unused_memory_average}%) is greater than ${unused_memory_threshold}% !!"
				echo $alarm_cleared_message | mail -s "$ALARM_SUBJECT" -r $MAIL_FROM $MAIL_LIST
				# log normal status but alarm cleared
				echo $(LogHeader) "$alarm_cleared_message" | tee -a $LOG_FILE
			else
				# log normal status
				echo -e $(LogHeader) "Unused Memory (${unused_memory_average}%) is greater than ${unused_memory_threshold}%" | tee -a $LOG_FILE
			fi
			# set consecutive counter to zero
			consecutive_counter="0"	
			echo "$consecutive_counter" > $consecutive_counter_file
		fi

		echo -e $(LogHeader) "current consecutive times status is $consecutive_counter, consecutive times = $consecutive_times" | tee -a $LOG_FILE


		# if consecutive counter is greater than or equal to threshold, send alarm email
		if [ "$(echo "$consecutive_counter >= $consecutive_times" | bc)" == "1" ]; then
			# sending alarm when current consecutive times lower than or equal to buffer times
			if [ "$(echo "$consecutive_counter <= $buffer_times" | bc)" == "1" ]; then
				alarm_message="Alarm Fired ! Unused Memory (${unused_memory_average}%) is lower than or equal to ${unused_memory_threshold}% !!"
				alarm_message="$alarm_message, consecutive times is $consecutive_times"
				alarm_message="$alarm_message, current consecutive times status is $consecutive_counter"
				echo -e $(LogHeader) "$alarm_message" | tee -a $LOG_FILE
				echo -e $alarm_message | mail -s "$ALARM_SUBJECT" -r $MAIL_FROM $MAIL_LIST
			# sending alarm only when current consecutive times mod buffer times = 0, it means it will send alarm every "buffer times" consecutive times
			elif [ "$(echo "$consecutive_counter % $buffer_times == 0" | bc)" == "1" ]; then
				alarm_message="Alarm Fired ! Unused Memory (${unused_memory_average}%) is lower than or equal to ${unused_memory_threshold}% !!"
				alarm_message="$alarm_message, consecutive times is $consecutive_times"
				alarm_message="$alarm_message, current consecutive times status is $consecutive_counter"
				echo -e $(LogHeader) "$alarm_message" | tee -a $LOG_FILE
				echo -e $alarm_message | mail -s "$ALARM_SUBJECT" -r $MAIL_FROM $MAIL_LIST
			# log alarm status, but won't fire alarm
			else
				alarm_message="Alarm Not Fired ! Unused Memory (${unused_memory_average}%) is lower than or equal to ${unused_memory_threshold}% !!"
				alarm_message="$alarm_message, consecutive times is greater than $buffer_times"	
				alarm_message="$alarm_message, current consecutive times status is $consecutive_counter"
				echo -e $(LogHeader) "$alarm_message" | tee -a $LOG_FILE
			fi
		fi
		;;
	"3")
		# disk check
		mounted_path_list_file="${CONF_DIR}/mounted_path_list.txt"
		mounted_path_list=$(cat $mounted_path_list_file)
		mounted_path_count=$(cat $mounted_path_list_file | wc -l)
		disk_threshold="70"
		consecutive_times="3"
		# buffer times is used to slow down the sending period when current consecutive times is greater than buffer times
		buffer_times="5"
	
		for (( i=1; i<=$mounted_path_count; i++ ))
		do
			mounted_path=$(cat $mounted_path_list_file | awk "NR==$i{print \$1}")
			echo joetest $mounted_path
			# for / directory, retieve the first row to avoid getting others data, becasue / always at first row. 
			mounted_path_state=$(df -h | grep $mounted_path | awk 'NR==1')
			echo joetest $mounted_path_state
			mounted_path_usage=$(echo $mounted_path_state | awk '{print $5}' | sed 's/%//g')
			consecutive_counter_file="${CONF_DIR}/disk_consecutive_counter_${i}.txt"
			consecutive_counter=$(cat $consecutive_counter_file)
			test -z $consecutive_counter && consecutive_counter="0"
			# if mounted path disk usage is greater than or equal to threshold, consecutive counter + 1
			if [ "$(echo "$mounted_path_usage >= $disk_threshold" | bc)" == "1" ]; then
				consecutive_counter=$(($consecutive_counter+1))	
				echo "$consecutive_counter" > $consecutive_counter_file
				echo -e $(LogHeader) "$mounted_path disk usage (${mounted_path_usage}%) is greater than or equal to ${disk_threshold}% !!"
			else
				if [ "$(echo "$consecutive_counter >= $consecutive_times" | bc)" == "1" ]; then
					alarm_cleared_message="Alarm Cleared ! $mounted_path disk usage (${mounted_path_usage}%) is lower then ${disk_threshold}% !!"
					echo $alarm_cleared_message | mail -s "$ALARM_SUBJECT" -r $MAIL_FROM $MAIL_LIST
					# log normal status but alarm cleared
					echo $(LogHeader) "$alarm_cleared_message" | tee -a $LOG_FILE
				else
					# log normal status
					echo -e $(LogHeader) "$mounted_path disk usage (${mounted_path_usage}%) is lower then ${disk_threshold}%" | tee -a $LOG_FILE
				fi
				# set consecutive counter to zero
				consecutive_counter="0"	
				echo "$consecutive_counter" > $consecutive_counter_file
			fi

			echo -e $(LogHeader) "current consecutive times status is $consecutive_counter, consecutive times = $consecutive_times" | tee -a $LOG_FILE

			# if consecutive counter is greater than or equal to threshold, send alarm email
			if [ "$(echo "$consecutive_counter >= $consecutive_times" | bc)" == "1" ]; then
				# sending alarm when current consecutive times lower than or equal to buffer times
				if [ "$(echo "$consecutive_counter <= $buffer_times" | bc)" == "1" ]; then
					alarm_message="Alarm Fired ! $mounted_path disk usage (${mounted_path_usage}%) is greater than or equal to ${disk_threshold}% !!"
					alarm_message="$alarm_message, consecutive times is $consecutive_times"
					alarm_message="$alarm_message, current consecutive times status is $consecutive_counter"
					echo -e $(LogHeader) "$alarm_message" | tee -a $LOG_FILE
					echo -e $alarm_message | mail -s "$ALARM_SUBJECT" -r $MAIL_FROM $MAIL_LIST
				# sending alarm only when current consecutive times mod buffer times = 0, it means it will send alarm every "buffer times" consecutive times
				elif [ "$(echo "$consecutive_counter % $buffer_times == 0" | bc)" == "1" ]; then
					alarm_message="Alarm Fired ! $mounted_path disk usage (${mounted_path_usage}%) is greater than or equal to ${disk_threshold}% !!" 
					alarm_message="$alarm_message, consecutive times is $consecutive_times"
					alarm_message="$alarm_message, current consecutive times status is $consecutive_counter"
					echo -e $(LogHeader) "$alarm_message" | tee -a $LOG_FILE
					echo -e $alarm_message | mail -s "$ALARM_SUBJECT" -r $MAIL_FROM $MAIL_LIST
				# log alarm status, but won't fire alarm
				else
					alarm_message="Alarm Not Fired ! $mounted_path disk usage (${mounted_path_usage}%) is greater than or equal to ${disk_threshold}% !!" 
					alarm_message="$alarm_message, consecutive times is greater than $buffer_times"	
					alarm_message="$alarm_message, current consecutive times status is $consecutive_counter"
					echo -e $(LogHeader) "$alarm_message" | tee -a $LOG_FILE
				fi
			fi
		done
		;;
	*)
		echo nothing to do
		;;
esac
