#!/usr/bin/env bash

# Settings:

# Adjust as your app size changes to make the logs prettier (you don't
# need to have them start one after the other, you can do it in parralel but I
# prefer doing it in sync because then the logs are very clear if their is a
# build error).
FRONTEND_COMPILE_SECONDS=5;
BACKEND_TSC_COMPILE_SECONDS=5;

# Watches all the files while you develop, building both the frontend and
# backend into `frontend/dist` and `backend/lib` respectively.

echo "========================================================"
echo "STARTING TASK: CD into top directory"
echo "========================================================"
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../;
echo "========================================================"
echo "COMPLETE TASK"
echo "========================================================"

. ./bin/helper-scripts/set-node-module-paths.sh;

echo "========================================================"
echo "STARTING BACKGROUND TASK: Watch Frontend"
echo "========================================================"
cd frontend;
"$FRONTEND_NODE_MODULES_BIN"/webpack --watch &
pid[0]=$!;
cd -;

(sleep $FRONTEND_COMPILE_SECONDS;
echo "========================================================"
echo "STARTING BACKGROUND TASK: Watch Backend :: TS --> ES6"
echo "========================================================"
"$BACKEND_NODE_MODULES_BIN"/tsc --project backend/tsconfig.json --watch;
) &
pid[1]=$!;

(sleep $((FRONTEND_COMPILE_SECONDS + BACKEND_TSC_COMPILE_SECONDS));
echo "========================================================"
echo "STARTING BACKGROUND TASK: Watch Backend :: ES6 --> ES5"
echo "========================================================"
"$BACKEND_NODE_MODULES_BIN"/babel backend --watch --out-dir backend/lib --source-maps --ignore lib,node_modules
) &
pid[2]=$!;


trap "printf '\n\n Cleaning Background Processes \n\n'; kill ${pid[0]} ${pid[1]} ${pid[2]}; exit 1" INT TERM;
wait;
