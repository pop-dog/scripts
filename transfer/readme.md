# Transfer Utilities

## Configuration
- Edit `config.yaml` with `remote-server`, `source-path`, and `destination-path`. All scripts load those values at runtime, so updates take effect immediately.

## Running Transfers Manually
- From PowerShell on Windows, call `.\file-transfer.ps1` to push all files currently in the `source-path` to the configured remote destination.
- `transfer-watcher.ps1` monitors the `source-path` and uploads each new file automatically after it appears.

## Install transfer-watcher as a Windows Service
1. Open an elevated PowerShell prompt.
2. Set the script path and install the service:
   ```powershell
   $serviceName = "TransferWatcher"
   $scriptPath  = "C:\path\to\transfer\transfer-watcher.ps1"
   $binPath     = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File `"$scriptPath`""
   New-Service -Name $serviceName `
               -BinaryPathName $binPath `
               -DisplayName "Transfer Watcher" `
               -Description "Transfers new files per config.yaml" `
               -StartupType Automatic `
               -Credential (Get-Credential)
   ```
3. Start the service with `Start-Service TransferWatcher`, then confirm it is running via `Get-Service TransferWatcher`.
4. Ensure the service account has access to the `source-path`, `scp`, and the remote host; adjust credentials with `sc.exe config TransferWatcher obj= "DOMAIN\User" password= "Secret"` if needed.
5. Review `log.txt` and Event Viewer (Service Control Manager) after reboots to verify the watcher starts automatically.
