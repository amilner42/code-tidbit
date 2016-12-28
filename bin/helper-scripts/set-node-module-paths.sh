#!/usr/bin/env bash

echo "========================================================"
echo "STARTING TASK: Set node_module paths"
echo "========================================================"
export BACKEND_NODE_MODULES_BIN=`pwd`/backend/node_modules/.bin;
export FRONTEND_NODE_MODULES_BIN=`pwd`/frontend/node_modules/.bin;
echo "========================================================"
echo "COMPLETE TASK"
echo "========================================================"
