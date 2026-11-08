[CmdletBinding()]
param(
    [ValidateRange(1, 65535)]
    [int] $Port = 4040,
    [ValidateNotNullOrEmpty()]
    [string] $SaveFile = '.dungeon/save.json',
    [switch] $NoBuild,
    [switch] $Help
)

if ($Help) {
    @"
Run the Into the Dungeon server on loopback. Press Ctrl+C to stop it.

Usage: ./start-server.ps1 [-Port 4040] [-SaveFile .dungeon/save.json] [-NoBuild]

Examples:
  ./start-server.ps1
  ./start-server.ps1 -Port 4050 -SaveFile ".dungeon/second game.json"
"@
    exit 0
}

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$dotnet = Get-Command dotnet -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $dotnet) {
    throw 'Install the .NET 10 SDK and put dotnet on PATH.'
}

$project = 'src/Dungeon.Server/Dungeon.Server.fpasproj'
$dll = 'src/Dungeon.Server/bin/Debug/net10.0/Dungeon.Server.dll'
Push-Location -LiteralPath $PSScriptRoot
try {
    if (-not $NoBuild) {
        & $dotnet.Source build $project --configuration Debug
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
    if (-not (Test-Path -LiteralPath $dll -PathType Leaf)) {
        throw 'The server build is missing. Run ./start-server.ps1 without -NoBuild.'
    }

    & $dotnet.Source $dll $Port $SaveFile
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
