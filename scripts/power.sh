#!/bin/bash

SECONDS=5

sys_poweroff(){
        if [[ $? -eq 0 || $? -eq 5 ]]; then
                systemctl poweroff
        elif [ $? -eq 1 ]; then
                echo "Poweroff aborted"
        else
                return 1
        fi
        return 0
}

sys_reboot(){
        if [[ $? -eq 0 || $? -eq 5 ]]; then
                systemctl reboot
        elif [ $? -eq 1 ]; then
                echo "Reboot aborted"
        else
                return 1
        fi
        return 0
}

sys_suspend(){
        if [[ $? -eq 0 || $? -eq 5 ]]; then
                systemctl suspend
        elif [ $? -eq 1 ]; then
                echo "Suspend aborted"
        else
                return 1
        fi
        return 0
}

case $1 in
        poweroff)
                zenity --question --title="Power off" --text="Turning off Fedora in $SECONDS seconds." --ok-label="Turn off" --cancel-label="Cancel" --timeout=$SECONDS
                sys_poweroff
                ;;
        reboot)
                zenity --question --title="Reboot" --text="Restarting Fedora in $SECONDS seconds." --ok-label="Restart" --cancel-label="Cancel" --timeout=$SECONDS
                sys_reboot
                ;;
        suspend)
                zenity --question --title="Suspend" --text="Suspending Fedora in $SECONDS seconds." --ok-label="Suspend" --cancel-label="Cancel" --timeout=$SECONDS
                sys_suspend
                ;;
        *)
                echo "You must specify a command. 'poweroff', 'reboot' or 'suspend'"
esac
