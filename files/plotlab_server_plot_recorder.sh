#!/usr/bin/env bash

PLOTLAB_SERVER_LOG=/var/log/plotlab/plotlabserver.log

FFMPEG_FRAMERATE=10
FFMPEG_PROCESS_NAME="ffmpeg"
FFMPEG_VIDEO_CODEC="libx264"
FFMPEG_VIDEO_EXTENSION="mkv"
FFMPEG_VIDEO_CONTAINER_FORMAT="matroska"
FFMPEG_LOG_FILE="/var/log/plotlab/ffmpeg.log"
DISPLAY="${VIRTUAL_DISPLAY_ID}"
DISPLAY_RESOLUTION="${VIRTUAL_DISPLAY_RESOLUTION}"

VIDEO_FILE="/var/log/plotlab/plotlab.${FFMPEG_VIDEO_EXTENSION}"

function shut_down_process(){
    local process_name="${1}"
    local force="${2}"

    if [[ -z "${process_name}" ]]; then
        echoerr "ERROR: must provide a process name."
        exit 1
    fi
    

   #echo "Process name: ${process_name}"

    process_id="$(pgrep "${process_name}")" || true
    #echo "PID: ${process_id}"
    if [[ -n "${process_id}" ]]; then
         if [[ $force ]]; then
             echo -n " Shutting down ${process_name}:$process_id..."
             kill -TERM $process_id
             sleep .5s
             pid=
             pid="$(pgrep "${process_name}")" || true
             if [[ -n "${pid}" ]]; then
                 kill -KILL $process_id
             fi
             echo "DONE"
         else
             echoerr "ERROR: ${process_name} already running. Manually kill it with: \"kill -SIGTERM ${process_id}\" or provide the -f flag to continue."
             exit 1
         fi
    fi

    sleep .5s
    pid=
    pid="$(pgrep "${process_name}")" || true
    if [[ -n "${pid}" ]]; then
        echoerr "ERROR: failed to shut down process: ${process_name} with pid: ${pid}"
        exit 1
    fi

}



plotting_active_last_state="1"

if [ "${DISPLAY_MODE}" == "native" ]; then
    echo -n "DISPLAY_MODE is \"${DISPLAY_MODE}\", plot video recording is only"
    echo    " available in 'window_manager' and 'headless' modes."
    exit 0
fi


while true; do
    plotting_active=$(tail -n 1 "${PLOTLAB_SERVER_LOG}" 2> /dev/null | cut -d: -f2|| true)
    if [ "${plotting_active}" != "${plotting_active_last_state}" ]; then
        plotting_active_last_state="${plotting_active}"
        if [ "${plotting_active}" == "1" ]; then
            echo -n " Starting ffmpeg recording on display: ${DISPLAY}..."
            touch "${FFMPEG_LOG_FILE}"
            {
            sleep 1s
            set -x
            ffmpeg -video_size "${DISPLAY_RESOLUTION}" \
                   -framerate "${FFMPEG_FRAMERATE}" \
                   -f x11grab \
                   -i "${DISPLAY}" \
                   -draw_mouse 0 \
                   -preset ultrafast \
                   -f "${FFMPEG_VIDEO_CONTAINER_FORMAT}" \
                   -vcodec "${FFMPEG_VIDEO_CODEC}" \
                   "${VIDEO_FILE}"
            set +x
            } > "${FFMPEG_LOG_FILE}" 2>&1 &
            echo "DONE"
        else
            shut_down_process "${FFMPEG_PROCESS_NAME}" "True" 
        fi
  fi
  sleep 0.1
done
