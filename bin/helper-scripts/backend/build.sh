#!/usr/bin/env bash

echo "========================================================"
echo "STARTING TASK: Build backend into /lib"
echo "========================================================"
cd backend;
"$BACKEND_NODE_MODULES_BIN"/tsc;
"$BACKEND_NODE_MODULES_BIN"/babel . --out-dir lib --source-maps --ignore lib,node_modules;
cd -;
echo "========================================================"
echo "COMPLETE TASK"
echo "========================================================"
