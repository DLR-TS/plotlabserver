#!/usr/bin/env bash

set -e

function echoerr { echo "$@" >&2; exit 1;}
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd "${SCRIPT_DIRECTORY}/.."
PLOTLABSERVER_BINARY_DIRECTORY="$(realpath plotlabserver/build)"

bash "${SCRIPT_DIRECTORY}/plotlabserver_plot_recorder.sh" >> /var/log/plotlab/plotlabserver_plot_recorder.log 2>&1 &

echo "Plotlab server DISPLAY_MODE: ${DISPLAY_MODE}"
echo "  Possible display modes: native, window_manager, headless"
echo "    To change the display mode modify the DISPLAY_MODE environmental variable in the docker-compose.yaml"
echo "    DISPLAY_MODE descriptions: "
echo "        native: plotlabserver windows will be displayed as native windows within the host system window manager (does not support video recording)" 
echo "        window_manager: plotlabserver windows will be displayed within a nested i3 window manager (supports video recording)" 
echo "        headless: plotlabserver windows will be displayed on a virtual xvfb display suitable for headless host systems (supports video recording)" 
echo ""

cd "${PLOTLABSERVER_BINARY_DIRECTORY}"

mkdir -p /var/log/plotlab/
touch /var/log/plotlab/i3.log
touch /var/log/plotlab/plotlabserver.log
touch /var/log/plotlab/xvfb.log

if [ "$DISPLAY_MODE" != "native" ] && [ "${DISPLAY_MODE}" != "window_manager" ] && [ "${DISPLAY_MODE}" != "headless" ]; then
  echoerr "ERROR: Unsupported display mode: ${DISPLAY_MODE}."
fi

echo "DISPLAY: ${DISPLAY}"


# window manager
if [[ "${DISPLAY_MODE}" == "window_manager" ]]; then
  echo "  running in window_manager mode..."
  Xephyr -br -ac -noreset -softCursor -screen ${VIRTUAL_DISPLAY_RESOLUTION} ${VIRTUAL_DISPLAY_ID} &
  sleep .1s
  xdotool search --name "Xephyr" set_window --name "Plotlab Server (ctrl+shift to capture and release mouse and keyboard)"
  DISPLAY="${VIRTUAL_DISPLAY_ID}" i3 > /var/log/plotlab/i3.log 2>&1 &
  sleep 1s
  cd /var/log/plotlab
  ln -s /tmp/plotlabserver/plotlabserver/images||true
  mkdir -p cache && cd cache
  DISPLAY="${VIRTUAL_DISPLAY_ID}" ${PLOTLABSERVER_BINARY_DIRECTORY}/plotlabserver > /var/log/plotlab/plotlabserver.log 2>&1 &
  tail -f /var/log/plotlab/plotlabserver.log
fi

# headless
if [[ "${DISPLAY_MODE}" == "headless" ]]; then
  echo "  running in headless mode..."
  Xvfb "${VIRTUAL_DISPLAY_ID}" -screen 0 "${VIRTUAL_DISPLAY_RESOLUTION}x16" \
                               -nolisten tcp >> "/var/log/plotlab/xvfb.log" 2>&1 &
  sleep 1s
  DISPLAY=${VIRTUAL_DISPLAY_ID} i3 > /var/log/plotlab/i3.log 2>&1 &
  sleep 1s
  DISPLAY=${VIRTUAL_DISPLAY_ID} unclutter -idle .1 &
  cd /var/log/plotlab
  ln -s /tmp/plotlabserver/plotlabserver/images||true
  mkdir -p cache && cd cache
  DISPLAY=${VIRTUAL_DISPLAY_ID} ${PLOTLABSERVER_BINARY_DIRECTORY}/plotlabserver > /var/log/plotlab/plotlabserver.log 2>&1 &
  tail -f /var/log/plotlab/plotlabserver.log
fi

# native
if [[ "${DISPLAY_MODE}" == "native" ]]; then
  echo "  running in native mode..."
  cd /var/log/plotlab
  ln -s /tmp/plotlabserver/plotlabserver/images||true
  mkdir -p cache && cd cache
  ${PLOTLABSERVER_BINARY_DIRECTORY}/plotlabserver 2>&1 | tee /var/log/plotlab/plotlabserver.log
fi

