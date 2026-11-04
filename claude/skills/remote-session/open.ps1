# Opens a Remote Control session in a repo, detached from the session that runs this,
# with permissions bypassed. Prints the session URL, or the error and exit code 1.
#
#   pwsh -File open.ps1 -Repo vida [-Account lgiraldoo|lufigir|luisgir827] [-Name title]

param(
    [Parameter(Mandatory)][string]$Repo,
    [ValidateSet('lgiraldoo', 'lufigir', 'luisgir827')][string]$Account = 'lgiraldoo',
    [string]$Name
)

$dir = Join-Path 'D:\Code' $Repo
if (-not (Test-Path $dir -PathType Container)) {
    Write-Error "No such repo: $dir" -ErrorAction Continue
    exit 1
}
if (-not $Name) { $Name = Split-Path $dir -Leaf }

# lufigir and luisgir827 are the same profile: the folder has one name, the login another.
$configFile = Join-Path $HOME '.claude.json'
$setProfile = ''
if ($Account -ne 'lgiraldoo') {
    $profileDir = Join-Path $HOME '.claude-lufigir'
    $configFile = Join-Path $profileDir '.claude.json'
    $setProfile = "set CLAUDE_CONFIG_DIR=$profileDir&& "
}
$config = Get-Content $configFile -Raw | ConvertFrom-Json -AsHashtable -DateKind String
$email = $config.oauthAccount.emailAddress

# Every repo is trusted by decision of the owner, and a server with no terminal can't ask.
$projectKey = $dir -replace '\\', '/'
if (-not $config.projects[$projectKey]) { $config.projects[$projectKey] = [ordered]@{} }
if (-not $config.projects[$projectKey].hasTrustDialogAccepted) {
    $config.projects[$projectKey].hasTrustDialogAccepted = $true
    $tempConfig = "$configFile.remote-session.tmp"
    $config | ConvertTo-Json -Depth 100 | Set-Content -Path $tempConfig -Encoding utf8NoBOM
    Move-Item -Path $tempConfig -Destination $configFile -Force
}

$logs = Join-Path ([IO.Path]::GetTempPath()) 'claude-remote-session'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = Join-Path $logs "$Name-$stamp.out.log"
$err = Join-Path $logs "$Name-$stamp.err.log"

# Win32_Process.Create rather than Start-Process: the server inherits neither this
# session's CLAUDE* variables nor its output pipe, which would keep the caller waiting.
# --spawn session: the process exits when its one session ends.
$claude = Join-Path $HOME '.local\bin\claude.exe'
$command = "cmd.exe /c `"$setProfile`"$claude`" remote-control --name `"$Name`" --spawn session --permission-mode bypassPermissions > `"$out`" 2> `"$err`"`""
$startup = New-CimInstance -ClassName Win32_ProcessStartup -ClientOnly -Property @{ ShowWindow = [uint16]0 }
$created = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
    CommandLine = $command; CurrentDirectory = $dir; ProcessStartupInformation = $startup
}
if ($created.ReturnValue -ne 0) {
    Write-Error "Could not start the server (Win32_Process.Create returned $($created.ReturnValue))." -ErrorAction Continue
    exit 1
}
$wrapper = $created.ProcessId

$deadline = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline -and (Get-Process -Id $wrapper -ErrorAction SilentlyContinue)) {
    $url = if (Test-Path $out) {
        Select-String -Path $out -Pattern 'https://claude\.ai/code/session_\S+' | Select-Object -First 1 | ForEach-Object { $_.Matches[0].Value }
    }
    if ($url) {
        "Session: $Name"
        "Folder:  $dir"
        "Account: $email"
        "PID:     $wrapper"
        "URL:     $url"
        exit 0
    }
    Start-Sleep -Milliseconds 500
}

if (Get-Process -Id $wrapper -ErrorAction SilentlyContinue) { taskkill /PID $wrapper /T /F | Out-Null }
Write-Error "No session for $dir ($email). $(Get-Content $err -Raw)" -ErrorAction Continue
"Logs: $out"
exit 1
