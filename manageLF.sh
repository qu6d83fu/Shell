#!bin/bash
SERVICE=$1
PARAMETER=$2

case "$SERVICE" in

  "mongo")
    case $PARAMETER in
      "start")ansible -s -a "service mongod start" lifeline;;
      "stop")ansible -s -a "service mongod stop" lifeline;;
      *)echo "Usage ManageLF mongo start|stop";;
    esac
  ;;
  "forever")
    case $PARAMETER in
      "start")ansible -a "ls" lifeline;;
      "stop")ansible -a "df -h" lifeline;;
      *)echo "Usage ManageLF start|stop";;
    esac
  ;;
  "unzip")
  read -p "Enter the zip name " ZIPNAME
  ansible -a "unzip -o $ZIPNAME -x lifeline/public/img/logo.png lifeline/config.  js" lifeline
  ;;
  *)
  echo "Usage ManageLF.sh mongo|forever|unzip"
  ;;

esac

