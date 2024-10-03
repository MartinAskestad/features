#!/bin/bash

# Test a plain install of VIM, version 8.2

set -e

source dev-container-features-test-lib

check "vim version" vim --version

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
