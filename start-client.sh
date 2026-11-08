#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'HELP'
Connect to an Into the Dungeon server on loopback.

Usage: ./start-client.sh [--port 4040] [--seed 25] [--no-build]

Examples:
  ./start-client.sh
  ./start-client.sh --port 4050 --seed -8 --no-build
HELP
}

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

port=4040
seed=25
build=true
while (($# > 0)); do
    case $1 in
        -h|--help) usage; exit 0 ;;
        --no-build) build=false; shift ;;
        --port|--seed)
            (($# >= 2)) && [[ -n $2 && $2 != --* && $2 != -h ]] || fail "Missing value for $1. See ./start-client.sh --help."
            case $1 in
                --port) port=$2 ;;
                --seed) seed=$2 ;;
            esac
            shift 2
            ;;
        *) fail "Unknown argument $1. See ./start-client.sh --help." ;;
    esac
done

[[ $port =~ ^[0-9]{1,5}$ ]] && ((10#$port >= 1 && 10#$port <= 65535)) || fail 'Port must be from 1 to 65535.'
[[ $seed =~ ^-?[0-9]{1,10}$ ]] || fail 'Seed must be a signed 32-bit integer.'
magnitude=$((10#${seed#-}))
if [[ $seed == -* ]]; then
    ((magnitude <= 2147483648)) || fail 'Seed must be a signed 32-bit integer.'
else
    ((magnitude <= 2147483647)) || fail 'Seed must be a signed 32-bit integer.'
fi

command -v dotnet >/dev/null || fail 'Install the .NET 10 SDK and put dotnet on PATH.'
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
dll=src/Dungeon.Client/bin/Debug/net10.0/Dungeon.Client.dll
if $build; then
    dotnet build src/Dungeon.Client/Dungeon.Client.fpasproj --configuration Debug
fi
[[ -f $dll ]] || fail 'The client build is missing. Run ./start-client.sh without --no-build.'

exec dotnet "$dll" "$port" "$seed"
