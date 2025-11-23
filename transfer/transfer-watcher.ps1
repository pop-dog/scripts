# Watch a configured folder and transfer new files to the configured remote server.
function Get-TransferConfig {
    param (
        [string]$ConfigPath
    )

    if (-not (Test-Path -Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }

    $config = @{}
    Get-Content -Path $ConfigPath | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith("#")) {
            return
        }

        $separatorIndex = $line.IndexOf(":")
        if ($separatorIndex -lt 0) {
            return
        }

        $key = $line.Substring(0, $separatorIndex).Trim()
        $value = $line.Substring($separatorIndex + 1).Trim()
        if ($key) {
            $config[$key] = $value
        }
    }

    return $config
}

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path -Path $scriptDirectory -ChildPath "config.yaml"
$config = Get-TransferConfig -ConfigPath $configPath

$remoteServer = $config["remote-server"]
$sourcePath = $config["source-path"]
$destinationPath = $config["destination-path"]

if (-not $remoteServer -or -not $sourcePath -or -not $destinationPath) {
    throw "Missing configuration values. Ensure remote-server, source-path, and destination-path are set in config.yaml."
}

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $sourcePath
$watcher.Filter = "*.*"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$scpCommand = "scp"
if (-not (Get-Command -Name $scpCommand -ErrorAction SilentlyContinue)) {
    if (Get-Command -Name "scp.exe" -ErrorAction SilentlyContinue) {
        $scpCommand = "scp.exe"
    }
}

$logPath = Join-Path -Path $sourcePath -ChildPath "log.txt"
$remoteDestination = "{0}:{1}" -f $remoteServer, $destinationPath

$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $logline = "{0}, {1}, {2}" -f (Get-Date), $changeType, $path
    $logTarget = $Event.MessageData.LogPath
    Add-Content -Path $logTarget -Value $logline

    $remoteTarget = $Event.MessageData.RemoteDestination
    $scpCmd = $Event.MessageData.ScpCommand

    try {
        & $scpCmd $path $remoteTarget
        Remove-Item -Path $path
    } catch {
        Write-Error "File transfer failed for $path. $_"
    }
}

Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action -MessageData @{
    LogPath = $logPath
    RemoteDestination = $remoteDestination
    ScpCommand = $scpCommand
}

while ($true) {
    Start-Sleep -Seconds 5
}
