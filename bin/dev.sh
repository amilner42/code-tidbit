#!/usr/bin/env bash

# Watches the backend/frontend files for changes, compiling elm/scss -> js,css
# and ts -> js. Simply click refresh on the frontend to see changes, also uses
# nodemon so that the server is automatically restarted (eg. run this script
# and develop).

echo "========================================================"
echo "STARTING TASK: CD into top directory"
echo "========================================================"
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../;
echo "========================================================"
echo "COMPLETE TASK"
echo "========================================================"

. ./bin/watch.sh &
pid[0]=$!;

(sleep 15;
echo "========================================================"
echo "Running Application localhost:3000"
echo "========================================================"
node backend/lib/src/main.js;
) &
pid[1]=$!;


trap "printf '\n\n Cleaning Background Processes \n\n'; kill ${pid[0]} ${pid[1]}; exit 1" INT TERM;
wait;
