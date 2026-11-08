#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'HELP'
Run the Into the Dungeon server on loopback. Press Ctrl+C to stop it.

Usage: ./start-server.sh [--port 4040] [--save-file .dungeon/save.json] [--no-build]

Examples:
  ./start-server.sh
  ./start-server.sh --port 4050 --save-file ".dungeon/second game.json"
HELP
}

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

port=4040
save_file=.dungeon/save.json
build=true
while (($# > 0)); do
    case $1 in
        -h|--help) usage; exit 0 ;;
        --no-build) build=false; shift ;;
        --port|--save-file)
            (($# >= 2)) && [[ -n $2 && $2 != --* && $2 != -h ]] || fail "Missing value for $1. See ./start-server.sh --help."
            case $1 in
                --port) port=$2 ;;
                --save-file) save_file=$2 ;;
            esac
            shift 2
            ;;
        *) fail "Unknown argument $1. See ./start-server.sh --help." ;;
    esac
done

[[ $port =~ ^[0-9]{1,5}$ ]] && ((10#$port >= 1 && 10#$port <= 65535)) || fail 'Port must be from 1 to 65535.'

command -v dotnet >/dev/null || fail 'Install the .NET 10 SDK and put dotnet on PATH.'
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
dll=src/Dungeon.Server/bin/Debug/net10.0/Dungeon.Server.dll
if $build; then
    dotnet build src/Dungeon.Server/Dungeon.Server.fpasproj --configuration Debug
fi
[[ -f $dll ]] || fail 'The server build is missing. Run ./start-server.sh without --no-build.'

exec dotnet "$dll" "$port" "$save_file"
