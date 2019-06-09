#!/bin/bash
#
# $1 interface
# $2 event
# $3 mac

USERID="***Removed***"
KEY="***Removed***"
TIMEOUT="10"
URL="https://api.telegram.org/bot$KEY/sendMessage"

LOG="/home/pi/registre.txt"
DATE=`date +"%Y-%m-%d %H:%M:%S"`

if [ "$2" == 'AP-STA-CONNECTED' ]; then
	/bin/bash /home/pi/tweet.sh post Algu s ha connectat a la xarxa
	TEXT="El dispositiu $3 s'acaba de connectar a la xarxa"
	curl -s --max-time $TIMEOUT -d "chat_id=$USERID&disable_web_page_preview=1&text=$TEXT" $URL > /dev/null
	echo "$3 $DATE (entrada)" >> $LOG
fi
if [ "$2" == 'AP-STA-DISCONNECTED' ] ; then
	/bin/bash /home/pi/tweet.sh post Algu ha sortit de la xarxa
	TEXT="El dispositiu $3 ha deixat la xarxa"
	curl -s --max-time $TIMEOUT -d "chat_id=$USERID&disable_web_page_preview=1&text=$TEXT" $URL > /dev/null
	echo "$3 $DATE (sortida)" >> $LOG
fi
