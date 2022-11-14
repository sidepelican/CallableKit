#!/bin/bash -uex
set -o pipefail

swift package --allow-writing-to-package-directory codegen

swift build -c release
.build/release/Server &
SERVER=$!
sleep 0.1
.build/release/Client
cd TSClient
npm run run
kill $SERVER

