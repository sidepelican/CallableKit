#!/bin/bash -ue
set -o pipefail

swift package --allow-writing-to-package-directory codegen

swift build -c release
.build/release/HBServer &
SERVER=$!
function finally {
  kill $SERVER
}
trap finally EXIT
sleep 0.1
.build/release/Client
cd TSClient
npm install && npm run run
