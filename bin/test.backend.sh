#!/usr/bin/env bash

# Runs all backend tests with mocha (located in `backend/tests`).

echo "========================================================"
echo "STARTING TASK: CD into top directory"
echo "========================================================"
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../;
echo "========================================================"
echo "COMPLETE TASK"
echo "========================================================"

. ./bin/helper-scripts/set-node-module-paths.sh;

. ./bin/helper-scripts/backend/build.sh;

. ./bin/helper-scripts/backend/test.sh;
