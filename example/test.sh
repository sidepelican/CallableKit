#!/bin/bash -ue
set -o pipefail

if [ "$(uname)" == 'Darwin' ]; then
  swift package --allow-writing-to-package-directory codegen
fi

swift build -c release
.build/release/Server &
SERVER=$!
function finally {
  kill $SERVER
}
trap finally EXIT
sleep 0.1
.build/release/Client
cd TSClient
npm run run

