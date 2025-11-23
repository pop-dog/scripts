# PowerShell script to transfer files from a local directory to a remote server using config.yaml.
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

Get-ChildItem -Path $sourcePath -File | ForEach-Object {
    # Ignore this script file itself.
    if ($_.Name -eq "file-transfer.ps1") {
        return
    }

    Write-Host "Processing file: $($_.Name)"
    $remoteDestination = "{0}:{1}" -f $remoteServer, $destinationPath
    scp $_.FullName $remoteDestination
    Write-Host "Transferred file: $($_.Name) to $remoteDestination"
    Remove-Item $_.FullName
}
