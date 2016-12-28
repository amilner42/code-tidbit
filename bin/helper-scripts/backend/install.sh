#!/usr/bin/env bash

echo "========================================================"
echo "STARTING TASK: Install backend dependencies"
echo "========================================================"
cd backend;
npm install;
cd -;
echo "========================================================"
echo "COMPLETE TASK"
echo "========================================================"

echo "========================================================"
echo "STARTING TASK: Install backend typings"
echo "========================================================"
cd backend;
"$BACKEND_NODE_MODULES_BIN"/typings install;
cd -;
echo "========================================================"
echo "COMPLETE TASK"
echo "========================================================"
