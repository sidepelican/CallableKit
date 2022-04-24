#!/bin/bash -ex

DIR=$(cd $(dirname $0); pwd)

cd "$DIR/.."
swift run Codegen "$DIR/Sources/APIDefinition" \
    --client_out "$DIR/Sources/Client/Gen" \
    --vapor_out "$DIR/Sources/Server/Gen" \
    --ts_out "$DIR/TSClient/src/Gen"
