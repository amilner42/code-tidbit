#!/usr/bin/env bash

echo "========================================================"
echo "STARTING TASK: Install frontend npm dependencies"
echo "========================================================"
cd frontend;
npm install;
cd -;
echo "========================================================"
echo "COMPLETE TASK"
echo "========================================================"

echo "========================================================"
echo "STARTING TASK: Install frontend elm dependencies"
echo "========================================================"
cd frontend;
"$FRONTEND_NODE_MODULES_BIN"/elm-package install -y;
cd -;
echo "========================================================"
echo "COMPLETE TASK"
echo "========================================================"
