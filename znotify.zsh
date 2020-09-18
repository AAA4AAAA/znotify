: ${ZSH_ZNOTIFY_REPORT_TIME:=10}

for cmd in dunstify notify-send; do
    : ${ZSH_ZNOTIFY_NOTIFY_CMD:=$(command -v "$cmd")}
done

unset cmd

if [[ ! -x "$ZSH_ZNOTIFY_NOTIFY_CMD" ]]; then
    return 2
fi

zmodload zsh/datetime

znotify_reset_env() {
    ZSH_ZNOTIFY_LASTTS:=0
    ZSH_ZNOTIFY_LASTCMD:=''
}

znotify_save_state() {
    ZSH_ZNOTIFY_LASTTS=$EPOCHSECONDS
    ZSH_ZNOTIFY_LASTCMD=$1
}

znotify_notify_time() {
    local err=$?

    if [[ -z $ZSH_ZNOTIFY_LASTCMD ]]; then
        return 0
    fi

    local duration=$(($EPOCHSECONDS - $ZSH_ZNOTIFY_LASTTS)) \
          lastcmd=$ZSH_ZNOTIFY_LASTCMD

    znotify_reset_env

    if [[ $duration -le $ZSH_ZNOTIFY_REPORT_TIME ]]; then
        return 0
    fi

    local urgent=normal expire=3000
    if [[ $err -ne 0 ]]; then
        urgent=critical expire=10000
    fi

    local summary="$lastcmd ($err)" \
          body="$(date -d@$duration -u +%Ts)"

    "$ZSH_ZNOTIFY_NOTIFY_CMD" -t $expire -u $urgent "$summary" "$body"
}

znotify_reset_env
preexec_functions+=(znotify_save_state)
precmd_functions+=(znotify_notify_time)
