#!/bin/bash -ue
set -o pipefail

swift package --allow-writing-to-package-directory codegen
swift build -c release

APP=${1:-}
case ${APP} in
  "vapor")
    .build/release/VaporServer &
    ;;
  "hummingbird")
    .build/release/HBServer &
    ;;
  *)
    echo "$0 <vapor|hummingbird>"
    exit 1
esac
SERVER=$!

function finally {
  kill $SERVER
}
trap finally EXIT

until curl -s -o /dev/null http://localhost:8080/; do
   sleep 0.1
done

.build/release/Client
cd TSClient
npm install && npm run run
