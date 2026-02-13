#!/bin/bash
# Test wrapper for cn native binary
# Dune adds the bin directory to PATH
NO_COLOR=1 exec cn "$@"
