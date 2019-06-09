#!/bin/bash
# $1 interface
# $2 event
# $3 mac

USERID="***Removed***"
KEY="***Removed***"
TIMEOUT="10"
URL="https://api.telegram.org/bot$KEY/sendMessage"
DATE_EXEC="$(date "+%d %b %Y %H:%M")"
if [ "$2" == 'AP-STA-CONNECTED' ]; then
	TEXT="El dispositiu $3 s'acaba de connectar a la xarxa"
	curl -s --max-time $TIMEOUT -d "chat_id=$USERID&disable_web_page_preview=1&text=$TEXT" $URL > /dev/null
fi
if [ "$2" == 'AP-STA-DISCONNECTED' ]; then
	TEXT="El dispositiu $3 ha deixat la xarxa"
	curl -s --max-time $TIMEOUT -d "chat_id=$USERID&disable_web_page_preview=1&text=$TEXT" $URL > /dev/null
fi
