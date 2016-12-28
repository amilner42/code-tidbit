#!/usr/bin/env bash

echo "========================================================"
echo " STARTING TASK: Running backend tests"
echo "========================================================"
"$BACKEND_NODE_MODULES_BIN"/mocha backend/lib/tests;
echo "========================================================"
echo "COMPLETE TASK"
echo "========================================================"
