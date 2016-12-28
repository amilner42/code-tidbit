#!/usr/bin/env bash

# Installs all app dependencies, should be used after a fresh `git clone`.

echo "========================================================"
echo "STARTING TASK: CD into top directory"
echo "========================================================"
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../;
echo "========================================================"
echo "COMPLETE TASK"
echo "========================================================"

. ./bin/helper-scripts/set-node-module-paths.sh;

. ./bin/helper-scripts/frontend/install.sh;
. ./bin/helper-scripts/backend/install.sh;
