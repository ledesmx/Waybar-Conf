#!/bin/bash

# Waybar print format
# {"text": "$text", "alt": "$alt", "tooltip": "$tooltip", "class": "$class", "percentage": $percentage }

ICON="⏲"
CLASS="pomo--work--off" #pomo--work pomo--work--off pomo--break pomo--break--off
STATUS_FILE="$HOME/.config/waybar/scripts/pomodoro_status"
WORKTIME=1500
BREAKTIME=300
TIME_REMAINING=$WORKTIME

#[[ SIGNALS ]]
trap 'toggle_pause' SIGUSR1
trap 'toggle_stage' SIGUSR2


#[[ FUNCTIONS ]]
create_status_file() {
    echo "status=paused" > "$STATUS_FILE"
    echo "stage=work" >> "$STATUS_FILE"
}

toggle_pause() {
    if [[ -f "$STATUS_FILE" ]]; then
        status=$(grep "^status=" "$STATUS_FILE" | cut -d '=' -f 2)

        # Toggle status between 'running' | 'paused'
        if [[ "$status" == "running" ]]; then
            sed -i 's/^status=.*$/status=paused/' "$STATUS_FILE"
        elif [[ "$status" == "paused" ]]; then
            sed -i 's/^status=.*$/status=running/' "$STATUS_FILE"
        fi   
    else
        create_status_file
    fi
}

toggle_stage() {
    if [[ -f "$STATUS_FILE" ]]; then
        stage=$(grep "^stage=" "$STATUS_FILE" | cut -d '=' -f 2)

        # Toggle stage between 'work' | 'break'
        if [[ "$stage" == "work" ]]; then
            sed -i 's/^stage=.*$/stage=break/' "$STATUS_FILE"
        elif [[ "$stage" == "break" ]]; then
            sed -i 's/^stage=.*$/stage=work/' "$STATUS_FILE"
        fi
        reset_time   
    else
        create_status_file
    fi
}

reset_time() {
    if [[ -f "$STATUS_FILE" ]]; then
        stage=$(grep "^stage=" "$STATUS_FILE" | cut -d '=' -f 2)

        if [[ "$stage" == "work" ]]; then
            TIME_REMAINING=$WORKTIME
        elif [[ "$stage" == "break" ]]; then
            TIME_REMAINING=$BREAKTIME
        fi
        sed -i 's/^status=.*$/status=paused/' "$STATUS_FILE"   
    else
        create_status_file
    fi
}

# Create a status file or reset if already exist
create_status_file

#[[ MAIN LOOP ]]
while true; do
    minutes=$((TIME_REMAINING / 60))
    seconds=$((TIME_REMAINING - minutes * 60 ))

    printf '{"text": "%s %02d:%02d", "class": "%s"}\n' "$ICON" "$minutes" "$seconds" "$CLASS"
    sleep 1

    # Check if the status file exist
    if [[ -f "$STATUS_FILE" ]]; then
        status=$(grep "^status=" "$STATUS_FILE" | cut -d '=' -f 2)
        stage=$(grep "^stage=" "$STATUS_FILE" | cut -d '=' -f 2)

        case $status in
            running)
                : $((TIME_REMAINING--))
                CLASS="pomo--$stage"
            ;;
            paused)
                CLASS="pomo--$stage--off"
            ;;
            reseted)
                reset_time
                CLASS="pomo--$stage--off"
            ;;
        esac

        # If the pomodoro has finished then change the between 'work' and 'break'
        if [[ $TIME_REMAINING -le 0 ]]; then
            toggle_stage
        fi
    else
        create_status_file
    fi
done
