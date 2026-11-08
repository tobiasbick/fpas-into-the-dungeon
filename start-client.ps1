[CmdletBinding()]
param(
    [ValidateRange(1, 65535)]
    [int] $Port = 4040,
    [int] $Seed = 25,
    [switch] $NoBuild,
    [switch] $Help
)

if ($Help) {
    @"
Connect to an Into the Dungeon server on loopback.

Usage: ./start-client.ps1 [-Port 4040] [-Seed 25] [-NoBuild]

Examples:
  ./start-client.ps1
  ./start-client.ps1 -Port 4050 -Seed -8 -NoBuild
"@
    exit 0
}

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$dotnet = Get-Command dotnet -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $dotnet) {
    throw 'Install the .NET 10 SDK and put dotnet on PATH.'
}

$project = 'src/Dungeon.Client/Dungeon.Client.fpasproj'
$dll = 'src/Dungeon.Client/bin/Debug/net10.0/Dungeon.Client.dll'
Push-Location -LiteralPath $PSScriptRoot
try {
    if (-not $NoBuild) {
        & $dotnet.Source build $project --configuration Debug
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
    if (-not (Test-Path -LiteralPath $dll -PathType Leaf)) {
        throw 'The client build is missing. Run ./start-client.ps1 without -NoBuild.'
    }

    & $dotnet.Source $dll $Port $Seed
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
