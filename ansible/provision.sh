#!/bin/bash

set -u # Variables must be explicit
set -e # If any command fails, fail the whole thing
set -o pipefail

# Make sure SSH knows to use the correct pem
ssh-add ansible.pem

# Load the AWS keys
. ./inventory/aws_keys

# Ensure the app's cache is up to date
inventory/ec2.py --refresh-cache

# Tag any existing  instances as being old
ansible-playbook tag-old-nodes.yaml --limit tag_Environment_code_tidbit || true

# Start a new instance
ansible-playbook immutable.yaml -vv

# Refresh cache to see the new tags
inventory/ec2.py --refresh-cache

# Now terminate any instances with tag "old"
ansible-playbook destroy-old-nodes.yaml --limit tag_oldCode-tidbit_True || true
