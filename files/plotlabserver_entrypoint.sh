#!/usr/bin/env bash

set -e

function echoerr { echo "$@" >&2; exit 1;}
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd "${SCRIPT_DIRECTORY}/.."
PLOTLABSERVER_BINARY_DIRECTORY="$(realpath plotlabserver/build)"

PLOTLABSERVER_LOG_DIRECTORY="/var/log/plotlabserver"

PLOTLABSERVER_LOG="${PLOTLABSERVER_LOG_DIRECTORY}/plotlabserver.log"
I3_LOG="${PLOTLABSERVER_LOG_DIRECTORY}/i3.log"
XVFB_LOG="${PLOTLABSERVER_LOG_DIRECTORY}/xvfb.log"
PLOTLABSERVER_PLOT_RECORDER_LOG="${PLOTLABSERVER_LOG_DIRECTORY}/plotlabserver_plot_recorder.log"
PLOTLABSERVER_ASSET_DIRECTORY="${PLOTLABSERVER_LOG_DIRECTORY}/assets"
USER=$(whoami)


#PLOTLABSERVER_WORKING_DIRECTORY="$(realpath "${SCRIPT_DIRECTORY}/..")"
PLOTLABSERVER_WORKING_DIRECTORY="${PLOTLABSERVER_ASSET_DIRECTORY}"

bash "${SCRIPT_DIRECTORY}/plotlabserver_plot_recorder.sh" >> "${PLOTLABSERVER_PLOT_RECORDER_LOG}" 2>&1 &

echo "Plotlab server DISPLAY_MODE: ${DISPLAY_MODE}"
echo "  Possible display modes: native, window_manager, headless"
echo "    To change the display mode modify the DISPLAY_MODE environmental variable in the docker-compose.yaml"
echo "    DISPLAY_MODE descriptions: "
echo "        native: plotlabserver windows will be displayed as native windows within the host system window manager (does not support video recording)" 
echo "        window_manager: plotlabserver windows will be displayed within a nested i3 window manager (supports video recording)" 
echo "        headless: plotlabserver windows will be displayed on a virtual xvfb display suitable for headless host systems (supports video recording)" 
echo ""

mkdir -p ${PLOTLABSERVER_LOG_DIRECTORY}
mkdir -p ${PLOTLABSERVER_ASSET_DIRECTORY}
touch "${I3_LOG}"
touch "${PLOTLABSERVER_LOG}"
touch "${XVFB_LOG}"
touch "${PLOTLABSERVER_PLOT_RECORDER_LOG}"

if [[ ! -w "${PLOTLABSERVER_WORKING_DIRECTORY}" ]]; then
    echoerr "ERROR: The user: ${USER} does not have write access to the PLOTLABSERVER_WORKING_DIRECTORY: ${PLOTLABSERVER_WORKING_DIRECTORY}"
fi

if [ "$DISPLAY_MODE" != "native" ] && [ "${DISPLAY_MODE}" != "window_manager" ] && [ "${DISPLAY_MODE}" != "headless" ]; then
  echoerr "ERROR: Unsupported display mode: ${DISPLAY_MODE}."
fi

echo "DISPLAY: ${DISPLAY}"

if [[ "${DISPLAY_MODE}" == "window_manager" ]]; then
  echo "  running in window_manager mode..."
  Xephyr -br -ac -noreset -softCursor -screen ${VIRTUAL_DISPLAY_RESOLUTION} ${VIRTUAL_DISPLAY_ID} &
  sleep .1s
  xdotool search --name "Xephyr" set_window --name "Plotlab Server (ctrl+shift to capture and release mouse and keyboard)"
  DISPLAY="${VIRTUAL_DISPLAY_ID}" i3 > "${I3_LOG}" 2>&1 &
  sleep 1s
  (
  cd "${PLOTLABSERVER_WORKING_DIRECTORY}"
  DISPLAY="${VIRTUAL_DISPLAY_ID}" ${PLOTLABSERVER_BINARY_DIRECTORY}/plotlabserver > "${PLOTLABSERVER_LOG}" 2>&1 &
  )
  tail -f "${PLOTLABSERVER_LOG}"
fi

if [[ "${DISPLAY_MODE}" == "headless" ]]; then
  echo "  running in headless mode..."
  Xvfb "${VIRTUAL_DISPLAY_ID}" -screen 0 "${VIRTUAL_DISPLAY_RESOLUTION}x16" \
                               -nolisten tcp >> "${XVFB_LOG}" 2>&1 &
  sleep 1s
  DISPLAY=${VIRTUAL_DISPLAY_ID} i3 > "${I3_LOG}" 2>&1 &
  sleep 1s
  DISPLAY=${VIRTUAL_DISPLAY_ID} unclutter -idle .1 &
  (
  cd "${PLOTLABSERVER_WORKING_DIRECTORY}"
  DISPLAY=${VIRTUAL_DISPLAY_ID} ${PLOTLABSERVER_BINARY_DIRECTORY}/plotlabserver > "${PLOTLABSERVER_LOG}" 2>&1 &
  )
  tail -f "${PLOTLABSERVER_LOG}"
fi

if [[ "${DISPLAY_MODE}" == "native" ]]; then
  echo "  running in native mode..."
  (
  cd "${PLOTLABSERVER_WORKING_DIRECTORY}"
  ${PLOTLABSERVER_BINARY_DIRECTORY}/plotlabserver 2>&1 | tee "${PLOTLABSERVER_LOG}"
  )
  tail -f "${PLOTLABSERVER_LOG}"
fi

