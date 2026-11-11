# Opens a Remote Control session in a repo, detached from the session that runs this,
# with permissions bypassed. Prints the session URL, or the error and exit code 1.
#
#   pwsh -File open.ps1 -Repo life-os [-Account lgiraldoo|luisgir827] [-Name title]

param(
    [Parameter(Mandatory)][string]$Repo,
    [ValidateSet('lgiraldoo', 'luisgir827')][string]$Account,
    [string]$Name
)

# With no account named, stay on the caller's: the other one may be out of usage.
if (-not $Account) { $Account = if ($env:CLAUDE_CONFIG_DIR -match 'luisgir827') { 'luisgir827' } else { 'lgiraldoo' } }

# A folder takes one server per machine, so the second account reaches D:\Code by its junction.
# That lets both accounts hold a session in the same repo.
$root = if ($Account -eq 'lgiraldoo') { 'D:\Code' } else { Join-Path $HOME 'Code-luisgir827' }
$dir = Join-Path $root $Repo
if (-not (Test-Path $dir -PathType Container)) {
    Write-Error "No such repo: $dir" -ErrorAction Continue
    exit 1
}
if (-not $Name) { $Name = Split-Path $dir -Leaf }

$configFile = Join-Path $HOME '.claude.json'
$setProfile = ''
if ($Account -ne 'lgiraldoo') {
    $profileDir = Join-Path $HOME '.claude-luisgir827'
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

# A server reattaches to the session in this pointer, which fails once that session is gone.
# If the pointer's server is alive, the repo already has a session on this account: reuse it.
$claudeDir = if ($setProfile) { $profileDir } else { Join-Path $HOME '.claude' }
$pointer = Join-Path $claudeDir "projects\$($dir -replace '[^A-Za-z0-9]', '-')\bridge-pointer.json"
if (Test-Path $pointer) {
    $previous = Get-Content $pointer -Raw | ConvertFrom-Json
    if (Get-Process -Id $previous.pid -ErrorAction SilentlyContinue) {
        "Session: already open"
        "Folder:  $dir"
        "Account: $email"
        "PID:     $($previous.pid)"
        "URL:     https://claude.ai/code/$($previous.sessionId)"
        exit 0
    }
    Remove-Item $pointer
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
        # A session that can't start prints its URL first and fails a few seconds later.
        Start-Sleep -Seconds 12
        $failed = Select-String -Path $out -Pattern 'Session failed' -Quiet
        if ($failed -or -not (Get-Process -Id $wrapper -ErrorAction SilentlyContinue)) { break }
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
$reason = Select-String -Path $out -Pattern 'Session failed.*' -ErrorAction SilentlyContinue | Select-Object -First 1 | ForEach-Object { $_.Matches[0].Value }
Write-Error "No session for $dir ($email). $reason $(Get-Content $err -Raw)" -ErrorAction Continue
"Logs: $out"
exit 1
