# Bin

All tooling scripts written in bash (I know...it's not ideal...) but it gets
the job done and provides very little bloat and complete transparency over the
tooling - no magic here.

### Scripts

| Name                 | What does it do       |
| -------------------- | --------------------- |
| build.sh             | Builds the backend into `backend/lib` and the frontend into `frontend/dist`. The frontend is minimized. |
| install.sh           | Installs all dependencies/typings for the project, to be used after a `git clone` |
| watch.sh             | Builds the project and watches for changes to all files on frontend and backend |
| dev.sh               | Builds the project and watches for changes as well as running the app on localhost:3000. |
| test.backend.sh      | Builds the backend and runs all the tests (`backend/tests`) with mocha |
| setup-remote.ubuntu1404.sh | Installs the local dependencies on an Ubuntu 14.04, tested and works with Amazon EC2 Ubuntu 14.04 instance |

### File Structure

All scripts meant to be run from the CLI are at the top level, any scripts
ending with `.backend.sh` and `.frontend.sh` do something for the backend and
frontend respectively, while scripts just ending with `.sh` effect both the
frontend and backend (eg. if it's `test.backend.sh` that means it tests the
backend, but if it's `test.sh` it tests both).

Helper scripts are put in `helper-scripts/` and furthermore into
`helper-scripts/frontend/` and `helper-scripts/backend` to help organize them
better. The scripts in `helper-scripts` are not intended to be called directly
from the CLI, but rather from other scripts (because these scripts rely on
environment variables being set).

### Background Task "Trapping"

To make sure background tasks close when the user hits ctrl-c, we need to `trap`
them (bash native for running a command when a signal like SIGINT gets sent).

To do this, simply after a bash command which ran with `&` then capture it's
processID and kill it in the trap.

##### Example

```
someBackgroundTask &;
pid[0]=$!

someOtherBackgroundTask &;
pid[1]=$!

trap "printf '\n\n Cleaning up processes \n\n';kill ${pid[0]} ${pid[1]}; exit 1" INT;
```
