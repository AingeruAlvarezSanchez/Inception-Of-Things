#!/usr/bin/env bash

set -euo pipefail
apk update
apk add --no-cache python3 py3-pip
