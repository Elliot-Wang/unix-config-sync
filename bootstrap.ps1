[CmdletBinding()]
param(
    [string]$Repository = $(if ($env:UNIX_SYNC_REPOSITORY) { $env:UNIX_SYNC_REPOSITORY } elseif ($env:CONFIG_SYNC_REPOSITORY) { $env:CONFIG_SYNC_REPOSITORY } else { "https://github.com/Elliot-Wang/unix-config-sync.git" }),
    [string]$Ref = $(if ($env:UNIX_SYNC_REF) { $env:UNIX_SYNC_REF } elseif ($env:CONFIG_SYNC_REF) { $env:CONFIG_SYNC_REF } else { "main" }),
    [string]$Source = $(if ($env:UNIX_SYNC_SOURCE) { $env:UNIX_SYNC_SOURCE } elseif ($env:CONFIG_SYNC_SOURCE) { $env:CONFIG_SYNC_SOURCE } else { Join-Path $HOME ".local/share/unix-sync/source" }),
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$UnixSyncArguments
)

$ErrorActionPreference = "Stop"
$binDirectory = if ($env:UNIX_SYNC_BIN_DIR) { $env:UNIX_SYNC_BIN_DIR } elseif ($env:CONFIG_SYNC_BIN_DIR) { $env:CONFIG_SYNC_BIN_DIR } else { Join-Path $HOME ".local/bin" }
New-Item -ItemType Directory -Force -Path $binDirectory | Out-Null
$env:PATH = "$binDirectory;$env:PATH"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "unix-sync: winget is required. Install or update Microsoft App Installer first."
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    winget install --id Git.Git --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
    $env:PATH = "$env:ProgramFiles\Git\cmd;$env:PATH"
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "unix-sync: Git was installed but is not visible yet; open a new terminal and rerun bootstrap.ps1"
}

if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
    winget install --id twpayne.chezmoi --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
}
if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
    throw "unix-sync: chezmoi was installed but is not visible yet; open a new terminal and rerun bootstrap.ps1"
}

if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "go.mod")) -and (Test-Path (Join-Path $PSScriptRoot ".unix-sync.json"))) {
    $Source = $PSScriptRoot
} elseif (-not (Test-Path (Join-Path $Source ".git"))) {
    if (Test-Path $Source) {
        throw "unix-sync: source path exists but is not a Git checkout: $Source"
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Source) | Out-Null
    git clone --branch $Ref --depth 1 $Repository $Source
}

$binary = Join-Path $binDirectory "unix-sync.exe"
if (Get-Command go -ErrorAction SilentlyContinue) {
    Push-Location $Source
    try {
        go build -o $binary ./cmd/unix-sync
    } finally {
        Pop-Location
    }
} else {
    $architecture = switch ($env:PROCESSOR_ARCHITECTURE) {
        "AMD64" { "amd64" }
        "ARM64" { "arm64" }
        default { throw "unix-sync: unsupported architecture $env:PROCESSOR_ARCHITECTURE" }
    }
    $temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("unix-sync-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
    try {
        $archive = Join-Path $temporaryDirectory "unix-sync.zip"
        $releaseUrl = "https://github.com/Elliot-Wang/unix-config-sync/releases/latest/download/unix-sync_windows_${architecture}.zip"
        Invoke-WebRequest -Uri $releaseUrl -OutFile $archive
        Expand-Archive -Path $archive -DestinationPath $temporaryDirectory
        Copy-Item -Force (Join-Path $temporaryDirectory "unix-sync.exe") $binary
    } finally {
        Remove-Item -Recurse -Force $temporaryDirectory -ErrorAction SilentlyContinue
    }
}

& $binary settings --source $Source @UnixSyncArguments
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $binary --source $Source
exit $LASTEXITCODE
