#! /bin/sh  
#
# Author: Joseph Mocker, Sun Microsystems
# http://blogs.sun.com/mock/entry/and_now_chicken_of_the
#
# To use this script:
#     setenv SSH_ASKPASS "macos-askpass"
#     setenv DISPLAY ":0"
#  

TITLE=${MACOS_ASKPASS_TITLE:-"SSH"}  

DIALOG="display dialog \"$@\" default answer \"\" with title \"$TITLE\""
DIALOG="$DIALOG with icon caution with hidden answer"  

result=`osascript -e 'tell application "Finder"' -e "activate"  -e "$DIALOG" -e 'end tell'`

if [ "$result" = "" ]; then
    exit 1
else
    echo "$result" | sed -e 's/^text returned://' -e 's/, button returned:.*$//'
    exit 0
fi
