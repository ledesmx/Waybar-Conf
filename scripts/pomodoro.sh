#!/bin/bash

# Waybar print format
# {"text": "$text", "alt": "$alt", "tooltip": "$tooltip", "class": "$class", "percentage": $percentage }

ICON="⏲"
CLASS="pomo--work--off" #pomo--work pomo--work--off pomo--break pomo--break--off
STATUS_FILE="$HOME/.config/waybar/scripts/pomodoro_status"
WORK_TONE="$HOME/.config/waybar/notification/work_tone_1.wav"
BREAK_TONE="$HOME/.config/waybar/notification/break_tone_1.wav"
WORKTIME=1500
BREAKTIME=300
TIME_REMAINING=$WORKTIME

#[[ SIGNALS ]]
trap 'toggle_pause' SIGUSR1
trap 'toggle_stage "idle"' SIGUSR2

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

            # Send 'BREAK' notification if so requested
            if [[ $1 == "notify" ]]; then
                notify-send --urgency=low "Take a break!" "Take a walk, rest your eyes, and be proud of your work."
                aplay "$BREAK_TONE"
            fi
        elif [[ "$stage" == "break" ]]; then
            sed -i 's/^stage=.*$/stage=work/' "$STATUS_FILE"
            
            # Send 'WORK' notification if so requested
            if [[ $1 == "notify" ]]; then
                notify-send --urgency=low "Time to focus!" "Focus on the task at hand."
                aplay "$WORK_TONE"
            fi
        fi
        
        # Reset time
        if [[ $1 == "idle" ]]; then
            reset_time "force-pause" # If 'idle' then force a 'pause'
        else
            reset_time # Else just reset and mantain current 'status'
        fi
    else
        create_status_file
    fi
}

reset_time() {
    if [[ -f "$STATUS_FILE" ]]; then
        status=$(grep "^status=" "$STATUS_FILE" | cut -d '=' -f 2)
        stage=$(grep "^stage=" "$STATUS_FILE" | cut -d '=' -f 2)

        if [[ "$stage" == "work" ]]; then
            TIME_REMAINING=$WORKTIME
        elif [[ "$stage" == "break" ]]; then
            TIME_REMAINING=$BREAKTIME
        fi
        # If status=="reseted" always change it to 'paused'. Or if pause is forced then pause it
        if [[ $status == "reseted" || $1 == "force-pause" ]]; then
            sed -i 's/^status=.*$/status=paused/' "$STATUS_FILE"   
        fi
    else
        create_status_file
    fi
}

update_class() {
    stage=$(grep "^stage=" "$STATUS_FILE" | cut -d '=' -f 2)
    if [[ $1 == "off" ]]; then
        CLASS="pomo--$stage--off"
    else
        CLASS="pomo--$stage"
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

        case $status in
            running)
                : $((TIME_REMAINING--))
                update_class
            ;;
            paused)
                update_class "off"
            ;;
            reseted)
                reset_time
                update_class "off"
            ;;
        esac

        # If the pomodoro has finished then change the between 'work' and 'break'
        if [[ $TIME_REMAINING -le 0 ]]; then
            toggle_stage "notify"
            update_class
        fi
    else
        create_status_file
    fi
done
