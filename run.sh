#!/usr/bin/env bash

# Get parameter on which binaries to NOT run
for arg in "$@"
do
    case ${arg} in
        "p" | "permissioning")
            runPermissioning="false"
            ;;
        "s" | "server")
            runServer="false"
            ;;
        "g" | "gateway")
            runGateway="false"
            ;;
        "u" | "udb")
            runUDB="false"
            ;;
    esac
done

BIN_PATH="$(pwd)/binaries"
CONFIG_PATH="$(pwd)/configurations"

if [[ -z ${runPermissioning} ]]
then
    "$BIN_PATH"/permissioning.binary -c "$CONFIG_PATH/permissioning.yaml" \
    -k "$CONFIG_PATH/dsa.json" &
fi

if [[ -z ${runServer} ]]
then
    "$BIN_PATH"/server.binary --config "$CONFIG_PATH/server-1.yaml" -i 0 \
    --keyPairOverride "$CONFIG_PATH/dsa.json" &
    "$BIN_PATH"/server.binary --config "$CONFIG_PATH/server-2.yaml" -i 1 \
    --keyPairOverride "$CONFIG_PATH/dsa.json" &
    "$BIN_PATH"/server.binary --config "$CONFIG_PATH/server-3.yaml" -i 2 \
    --keyPairOverride "$CONFIG_PATH/dsa.json" &
fi

if [[ -z ${runGateway} ]]
then
    "$BIN_PATH"/gateway.binary --config "$CONFIG_PATH/gateway-1.yaml" -i 0 &
    "$BIN_PATH"/gateway.binary --config "$CONFIG_PATH/gateway-2.yaml" -i 1 &
    "$BIN_PATH"/gateway.binary --config "$CONFIG_PATH/gateway-3.yaml" -i 2 &
fi

if [[ -z ${runUDB} ]]
then
    "$BIN_PATH"/udb.binary --config "$CONFIG_PATH/udb.yaml" \
    -n "$CONFIG_PATH/ndf.json" &
fi

# Pipe child PIDs into file
jobs -p > pids.tmp

finish() {
    # Read in and kill all child PIDs
    for job in $(cat pids.tmp)
    do
        echo "KILLING $job"
        kill "$job" || true
    done
}

# Execute finish function on exit
trap finish EXIT

# Wait until user input to exit
read -p 'Press enter to exit...'
