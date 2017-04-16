#!/usr/bin/env bash

# Builds the app for production, puts the frontend (minimized) in
# `frontend/dist` and puts the backend (not minimized) in `backend/lib`.

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../;

. ./bin/helper-scripts/set-node-module-paths.sh;

. ./bin/helper-scripts/frontend/build.sh;
. ./bin/helper-scripts/backend/build.sh;
