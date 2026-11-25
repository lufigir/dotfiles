#!/usr/bin/env pwsh
# Links these dotfiles into place. Runs on Windows, macOS and Linux under PowerShell 7+.
#
#   ./install.ps1                          # interactive component picker
#   ./install.ps1 -All                     # everything, no prompts
#   ./install.ps1 -Components wezterm,zed  # just those
#   ./install.ps1 -Check                   # fail if CLAUDE.md/AGENTS.md is stale, the skill sets differ,
#                                          # or a guard (git commit-msg, PreToolUse) stops working
#
# On Windows it needs Developer Mode enabled (Settings > Privacy & security > For
# developers) so New-Item -ItemType SymbolicLink works without admin. On macOS and
# Linux symlinks need nothing.

param(
    [string[]]$Components,
    [switch]$All,
    [switch]$Check
)

# Must come before anything version-specific: Windows PowerShell 5.1 leaves $IsWindows
# undefined, so every OS check below would silently take the Unix branch.
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "This script requires PowerShell 7+. You are on $($PSVersionTable.PSVersion)."
    Write-Host "Install it (winget install Microsoft.PowerShell) and re-run with 'pwsh ./install.ps1'."
    exit 1
}

$repo = $PSScriptRoot
$backupDir = Join-Path $HOME '.dotfiles-backup'

# Claude Code plugins the baseline installs and the cleanup keeps.
$baselinePlugins = @(
    'insecure-defaults@trailofbits'
    'static-analysis@trailofbits'
    'supply-chain-risk-auditor@trailofbits'
    'context-meter@better-claude'
)
# Terminal mods that only WezTerm turns on: installed here, off in settings.json, and
# enabled by settings.wezterm.json, which the PowerShell profile passes to `claude`
# with --settings inside WezTerm. Orca copies settings.json into its own profiles and
# draws its chat outside the terminal, so there they stay off.
$weztermPlugins = @(
    'after@better-claude'
    'think-hard@better-claude'
    'token-meter@better-claude'
    'sub-meter@better-claude'
    'image-preview@better-claude'
    'quick-peek@better-claude'
)
# Orca plugins installed from Orca's official catalog, next to the folders in orca/. OLED
# is the editor theme (picked in Settings → Appearance); Astro colors the app and the terminal.
$orcaCatalogPlugins = @(
    'stablyai.orca-oled-theme'
)
# Skills from agents/skills/ that stay out of ~/.gemini/config/skills/:
# - felipego-projects: opt-in per project (agy has no skillOverrides to keep a global skill off)
# - grill-me: collides with agy's built-in /grill-me slash command (grilling stays linked)
# These two are the only allowed difference between the harnesses' skill sets; -Check
# fails on any other.
$agyExcludedSkills = @(
    'felipego-projects'
    'grill-me'
)
# Orca's own skills live in ~/.agents/skills (Orca maintains them). They are linked from
# there into both harnesses, never copied into this repo.
$orcaSkillsDir = Join-Path $HOME '.agents' 'skills'
$orcaSkills = @('orca-cli', 'orca-computer-use', 'orchestration')
$script:browseInstalled = $false
$script:gitSymlinksEnabled = $false

# --- Presentation ------------------------------------------------------------
# Colors collapse to empty strings when output is redirected, NO_COLOR is set, or
# $PSStyle is missing (7.0/7.1), so piping to a file stays clean.
$c = @{}
if ([Console]::IsOutputRedirected -or $env:NO_COLOR -or -not $PSStyle) {
    foreach ($k in 'Reset', 'Bold', 'Dim', 'Cyan', 'Green', 'Yellow', 'Red') { $c[$k] = '' }
} else {
    $c = @{
        Reset  = $PSStyle.Reset
        Bold   = $PSStyle.Bold
        Dim    = $PSStyle.Foreground.BrightBlack
        Cyan   = $PSStyle.Foreground.Cyan
        Green  = $PSStyle.Foreground.Green
        Yellow = $PSStyle.Foreground.Yellow
        Red    = $PSStyle.Foreground.Red
    }
}

$boxWidth = 58

function Write-Box($title, $subtitle) {
    $inner = $boxWidth - 2
    Write-Host ""
    Write-Host "$($c.Cyan)╭$('─' * $inner)╮$($c.Reset)"
    Write-Host "$($c.Cyan)│$($c.Reset) $($c.Bold)$($title.PadRight($inner - 2))$($c.Reset) $($c.Cyan)│$($c.Reset)"
    Write-Host "$($c.Cyan)│$($c.Reset) $($c.Dim)$($subtitle.PadRight($inner - 2))$($c.Reset) $($c.Cyan)│$($c.Reset)"
    Write-Host "$($c.Cyan)╰$('─' * $inner)╯$($c.Reset)"
}

function Write-Section($text) {
    Write-Host ""
    Write-Host "$($c.Bold)$text$($c.Reset)"
}

function Write-Ok($text)   { Write-Host "  $($c.Green)✓$($c.Reset) $text" }
function Write-Warn($text) { Write-Host "  $($c.Yellow)⚠$($c.Reset) $text" }
function Write-Fail($text) { Write-Host "  $($c.Red)✗$($c.Reset) $text" }
function Write-Note($text) { Write-Host "  $($c.Dim)$text$($c.Reset)" }

# ~/... instead of the full home path, so lines stay short and readable.
function Format-Path($path) {
    if ($path.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) {
        return '~' + $path.Substring($HOME.Length)
    }
    return $path
}

function Get-OsName {
    if ($IsWindows) { return 'Windows' }
    if ($IsMacOS) { return 'macOS' }
    return 'Linux'
}

# XDG on every platform, so the installer and the PowerShell profile agree on where
# the Oh My Posh theme lives. On Windows XDG_CONFIG_HOME is virtually never set, so
# this resolves to ~/.config there too.
function Get-ConfigHome {
    if ($env:XDG_CONFIG_HOME) { return $env:XDG_CONFIG_HOME }
    return (Join-Path $HOME '.config')
}

$os = Get-OsName
$configHome = Get-ConfigHome

# --- Agent instructions ------------------------------------------------------
# agents/AGENTS.md is the only hand-edited source of the global instructions. Two
# files are generated from it and committed, so the symlinks into ~/.claude and
# ~/.gemini keep working unchanged: claude/CLAUDE.md and agy/AGENTS.md.
#   <!-- claude --> ... <!-- /claude -->   kept for that harness, dropped for the other
#   {{executor}}, {{browse}}                the harness's name for the same MCP
# A marker alone on its line removes the whole line; inline markers keep the line.
$agentTokens = @{
    claude = @{ executor = '`mcp__executor__*`';         browse = '`mcp__browse__*`' }
    agy    = @{ executor = '`executor` MCP server';      browse = '`browse` MCP' }
}
$agentOutputs = @(
    @{ Harness = 'claude'; Path = (Join-Path $repo 'claude' 'CLAUDE.md') }
    @{ Harness = 'agy';    Path = (Join-Path $repo 'agy' 'AGENTS.md') }
)

function Render-AgentInstructions($harness) {
    $text = (Get-Content (Join-Path $repo 'agents' 'AGENTS.md') -Raw) -replace "`r`n", "`n"
    foreach ($h in $agentTokens.Keys) {
        $text = [regex]::Replace($text, "(?ms)^<!-- $h -->\n(.*?)^<!-- /$h -->\n", $(if ($h -eq $harness) { '$1' } else { '' }))
        $text = [regex]::Replace($text, "(?s)<!-- $h -->(.*?)<!-- /$h -->", $(if ($h -eq $harness) { '$1' } else { '' }))
    }
    foreach ($token in $agentTokens[$harness].Keys) {
        $text = $text.Replace("{{$token}}", $agentTokens[$harness][$token])
    }
    $left = [regex]::Match($text, '<!-- /?\w+ -->|\{\{\w+\}\}')
    if ($left.Success) { throw "agents/AGENTS.md: unresolved '$($left.Value)' for $harness" }
    $header = "<!-- GENERATED from agents/AGENTS.md by install.ps1 for $harness. Do not edit here: edit the source and run ./install.ps1 -->`n`n"
    return $header + $text
}

# Writes both outputs; with -Check writes nothing and returns $false if one is stale.
function Sync-AgentInstructions([bool]$checkOnly) {
    $ok = $true
    foreach ($o in $agentOutputs) {
        $want = Render-AgentInstructions $o.Harness
        $have = if (Test-Path $o.Path) { (Get-Content $o.Path -Raw) -replace "`r`n", "`n" } else { $null }
        $shown = Format-Path $o.Path
        if ($have -ceq $want) { Write-Ok "$shown $($c.Dim)up to date$($c.Reset)"; continue }
        if ($checkOnly) { Write-Fail "$shown $($c.Dim)is stale, run ./install.ps1$($c.Reset)"; $ok = $false; continue }
        [System.IO.File]::WriteAllText($o.Path, $want, [System.Text.UTF8Encoding]::new($false))
        Write-Ok "$shown $($c.Dim)generated$($c.Reset)"
    }
    return $ok
}

# Both harnesses must see the same skills: the repo's agents/skills plus Orca's set.
# Only $agyExcludedSkills may differ (kept off agy, on in Claude). Reads what is installed.
function Test-SkillParity {
    $sets = [ordered]@{
        claude = Join-Path $HOME '.claude' 'skills'
        agy    = Join-Path $HOME '.gemini' 'config' 'skills'
    }
    $found = @{}
    foreach ($h in $sets.Keys) {
        if (-not (Test-Path $sets[$h])) { Write-Fail "$(Format-Path $sets[$h]) $($c.Dim)missing, run ./install.ps1$($c.Reset)"; return $false }
        # A skill is a folder (or link to one) holding a SKILL.md.
        $found[$h] = @(Get-ChildItem $sets[$h] -Force | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } | ForEach-Object Name)
    }
    $repoNames = @(Get-ChildItem (Join-Path $repo 'agents' 'skills') -Directory | ForEach-Object Name)
    $want = @{
        claude = $repoNames + $orcaSkills
        agy    = @($repoNames | Where-Object { $_ -notin $agyExcludedSkills }) + $orcaSkills
    }
    $ok = $true
    foreach ($h in $sets.Keys) {
        $missing = @($want[$h] | Where-Object { $_ -notin $found[$h] })
        $extra   = @($found[$h] | Where-Object { $_ -notin $want[$h] })
        if ($missing) { Write-Fail "$h $($c.Dim)missing: $($missing -join ', ')$($c.Reset)"; $ok = $false }
        if ($extra)   { Write-Fail "$h $($c.Dim)not in the shared set: $($extra -join ', ')$($c.Reset)"; $ok = $false }
    }
    if ($ok) {
        Write-Ok "skills $($c.Dim)claude $($found.claude.Count), agy $($found.agy.Count); only $($agyExcludedSkills -join ', ') differ$($c.Reset)"
    }
    return $ok
}

# --- Guards ------------------------------------------------------------------
# Deterministic rules enforced outside the model, by whatever tool runs the action:
#   git/hooks/        global commit-msg guard (and chaining stubs for every other hook), made
#                     global by core.hooksPath. Rejects a message that credits an AI agent.
#   agents/hooks/guard.py  PreToolUse hook shared by Claude Code (claude/settings.json) and agy
#                     (agy/hooks.json). Blocks force-pushing main/master and reading
#                     life-os/documentos from outside life-os.
# Both settings files call the guard through ~/.dotfiles-hooks, a link to agents/hooks.
$gitHooksDir = Join-Path $repo 'git' 'hooks'
$guardScript = Join-Path $repo 'agents' 'hooks' 'guard.py'
$guardHome = Join-Path $HOME '.dotfiles-hooks'
# Repos that keep their own hooks in .git/hooks (simple-git-hooks): the global stubs must chain.
$guardRealRepos = @('verificacion-pagos', 'despacho-vicerrectoria')

function Invoke-Guard($payload) {
    $out = $payload | ConvertTo-Json -Depth 6 -Compress | python $guardScript 2>&1 | Out-String
    return @{ Code = $LASTEXITCODE; Out = $out }
}

# Writes with LF endings and no BOM: these run under sh.
function Write-HookFile($path, $body) {
    [System.IO.File]::WriteAllText($path, "#!/bin/sh`n$body`n", [System.Text.UTF8Encoding]::new($false))
}

function Warn-RepoLocalHooksPath {
    $codeRoot = 'D:\Code'
    if (-not (Test-Path $codeRoot)) { return }
    $found = @()
    foreach ($dir in Get-ChildItem $codeRoot -Directory -ErrorAction SilentlyContinue) {
        if (-not (Test-Path (Join-Path $dir.FullName '.git'))) { continue }
        $local = (git -C $dir.FullName config --local --get core.hooksPath 2>$null)
        if ($local) {
            $found += "$($dir.Name) ($local)"
        }
    }
    if ($found.Count -gt 0) {
        foreach ($entry in $found) {
            Write-Warn "repo skips global commit-msg guard (sets own core.hooksPath): $entry"
        }
    } else {
        Write-Ok "no repos under $codeRoot set a local core.hooksPath"
    }
}

# Proves each guard fires and lets a normal commit and push through. Runs in temp repos,
# so it touches no real repo and needs nothing installed; the real repos are only given a
# message file and a hook that is told to skip itself.
function Test-Guards {
    $script:guardFails = 0
    function Assert-Guard([string]$name, [bool]$condition) {
        if ($condition) { Write-Ok $name } else { Write-Fail $name; $script:guardFails++ }
    }
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) { Write-Fail "python not found, the guard needs it"; return $false }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Fail "git not found"; return $false }

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "dotfiles-guards-$([guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    try {
        $work = Join-Path $tmp 'work'
        $remote = Join-Path $tmp 'remote.git'
        git init -q --bare $remote
        git init -q -b main $work
        git -C $work config user.name 'Guard Test'
        git -C $work config user.email 'guard@example.com'
        git -C $work config commit.gpgsign false
        git -C $work remote add origin $remote

        # --- commit-msg: global hook, in a repo with no hooks of its own ---
        function Try-Commit([string[]]$messages) {
            $margs = @(); foreach ($m in $messages) { $margs += @('-m', $m) }
            git -C $work -c "core.hooksPath=$gitHooksDir" commit -q --allow-empty @margs *> $null
            return $LASTEXITCODE
        }
        Write-Note "commit-msg"
        Assert-Guard 'a normal commit goes through' ((Try-Commit @('chore: normal commit', 'A body line.')) -eq 0)
        foreach ($ai in 'Claude', 'Anthropic', 'Gemini', 'Google AI', 'Copilot', 'Cursor', 'Antigravity', 'Codex', 'OpenAI', 'Agy') {
            Assert-Guard "rejects Co-Authored-By: $ai" ((Try-Commit @('chore: x', "Co-Authored-By: $ai <noreply@example.com>")) -ne 0)
        }
        Assert-Guard 'rejects "Generated with Claude Code"' ((Try-Commit @('chore: x', 'Generated with Claude Code')) -ne 0)
        Assert-Guard 'rejects a trailer naming a model (Gemini 4 Neon)' ((Try-Commit @('chore: x', 'Co-Authored-By: Gemini 4 Neon <g@example.com>')) -ne 0)
        Assert-Guard 'lets a human co-author through' ((Try-Commit @('chore: x', 'Co-Authored-By: Ana Perez <ana@example.com>')) -eq 0)
        Assert-Guard 'lets a message about an agent through ("docs(claude): ...")' ((Try-Commit @('docs(claude): describe the Gemini table')) -eq 0)
        Assert-Guard 'lets prose "built by Claude Code agents" through' ((Try-Commit @('chore: fix scripts built by Claude Code agents')) -eq 0)
        Assert-Guard 'lets prose "using the Gemini table" through' ((Try-Commit @('docs: render using the Gemini table')) -eq 0)
        Assert-Guard 'lets prose mentioning "cursor" through' ((Try-Commit @('fix(editor): keep cursor on the active line', 'Built with a blinking cursor indicator.')) -eq 0)

        # --- chaining: the repo's own hooks in .git/hooks still run ---
        Write-Note "chaining to the repo's own hooks"
        $repoHooks = Join-Path $work '.git' 'hooks'
        Write-HookFile (Join-Path $repoHooks 'commit-msg') 'echo ran > chain-commit-msg.txt; exit 1'
        Assert-Guard "the repo's commit-msg hook still rejects" ((Try-Commit @('chore: clean message')) -ne 0)
        Assert-Guard "the repo's commit-msg hook ran" (Test-Path (Join-Path $work 'chain-commit-msg.txt'))
        Write-HookFile (Join-Path $repoHooks 'commit-msg') 'exit 0'
        Write-HookFile (Join-Path $repoHooks 'pre-commit') 'echo ran > chain-pre-commit.txt; exit 0'
        Assert-Guard "a clean commit passes both hooks" ((Try-Commit @('chore: clean message')) -eq 0)
        Assert-Guard "the repo's pre-commit hook ran" (Test-Path (Join-Path $work 'chain-pre-commit.txt'))

        # --- push through the global hooksPath ---
        Write-Note "push"
        git -C $work -c "core.hooksPath=$gitHooksDir" push -q origin main *> $null
        Assert-Guard 'a normal push goes through' ($LASTEXITCODE -eq 0)
        Write-HookFile (Join-Path $repoHooks 'pre-push') 'echo ran > chain-pre-push.txt; exit 1'
        git -C $work -c "core.hooksPath=$gitHooksDir" push -q origin main:other *> $null
        Assert-Guard "the repo's pre-push hook still blocks" ($LASTEXITCODE -ne 0)
        Assert-Guard "the repo's pre-push hook ran" (Test-Path (Join-Path $work 'chain-pre-push.txt'))
        Remove-Item (Join-Path $repoHooks 'pre-push') -Force

        # --- the two real repos with hooks of their own ---
        Write-Note "repos with their own hooks"
        $badMsg = Join-Path $tmp 'bad.txt'
        $okMsg = Join-Path $tmp 'ok.txt'
        [System.IO.File]::WriteAllText($badMsg, "chore: x`n`nCo-Authored-By: Claude <noreply@anthropic.com>`n")
        [System.IO.File]::WriteAllText($okMsg, "chore: x`n")
        foreach ($name in $guardRealRepos) {
            $dir = @('D:\Code', (Join-Path $HOME 'Code')) | ForEach-Object { Join-Path $_ $name } | Where-Object { Test-Path (Join-Path $_ '.git') } | Select-Object -First 1
            if (-not $dir) { Write-Note "$name is not on this machine, skipped"; continue }
            git -C $dir -c "core.hooksPath=$gitHooksDir" hook run --ignore-missing commit-msg -- $badMsg *> $null
            Assert-Guard "$name rejects a Claude trailer" ($LASTEXITCODE -ne 0)
            git -C $dir -c "core.hooksPath=$gitHooksDir" hook run --ignore-missing commit-msg -- $okMsg *> $null
            Assert-Guard "$name accepts a clean message" ($LASTEXITCODE -eq 0)
            # SKIP_SIMPLE_GIT_HOOKS makes the repo's hook print a line and exit, so seeing the
            # line proves the stub reached it without running lint-staged.
            $env:SKIP_SIMPLE_GIT_HOOKS = '1'
            try {
                foreach ($hook in 'pre-commit', 'pre-push') {
                    if (-not (Test-Path (Join-Path $dir '.git' 'hooks' $hook))) { continue }
                    $out = git -C $dir -c "core.hooksPath=$gitHooksDir" hook run $hook 2>&1 | Out-String
                    Assert-Guard "$name chains to its own $hook" (($LASTEXITCODE -eq 0) -and ($out -match 'skipping hook'))
                }
            } finally { Remove-Item Env:SKIP_SIMPLE_GIT_HOOKS -ErrorAction SilentlyContinue }
        }

        # --- PreToolUse guard, Claude Code payloads (exit 2 denies) ---
        Write-Note "PreToolUse guard, Claude Code"
        $other = Join-Path $tmp 'elsewhere'
        function Claude-Bash($command, $cwd) { Invoke-Guard @{ tool_name = 'Bash'; tool_input = @{ command = $command }; cwd = $cwd } }
        foreach ($cmd in 'git push --force origin main', 'git push -f origin master', 'git push --force-with-lease origin main',
                         'git add . && git push origin +main', 'git push --force-with-lease=main origin main') {
            Assert-Guard "blocks: $cmd" ((Claude-Bash $cmd $work).Code -eq 2)
        }
        Assert-Guard 'blocks a bare `git push -f` while on main' ((Claude-Bash 'git push -f' $work).Code -eq 2)
        foreach ($cmd in 'git push origin main', 'git push -u origin main', 'git push --force origin feature/x', 'git push -f origin feature/x', 'git status') {
            Assert-Guard "allows: $cmd" ((Claude-Bash $cmd $work).Code -eq 0)
        }
        git -C $work checkout -q -b feature/x
        Assert-Guard 'allows a bare `git push -f` on a feature branch' ((Claude-Bash 'git push -f' $work).Code -eq 0)
        git -C $work checkout -q main

        $docs = 'D:\Code\life-os\documentos\plan.md'
        Assert-Guard 'blocks Read of life-os/documentos from another repo' ((Invoke-Guard @{ tool_name = 'Read'; tool_input = @{ file_path = $docs }; cwd = $work }).Code -eq 2)
        Assert-Guard 'blocks a Bash read of life-os/documentos from another repo' ((Claude-Bash "cat $docs" $work).Code -eq 2)
        Assert-Guard 'allows Read of life-os/documentos inside life-os' ((Invoke-Guard @{ tool_name = 'Read'; tool_input = @{ file_path = $docs }; cwd = 'D:\Code\life-os' }).Code -eq 0)
        Assert-Guard 'allows Read of an ordinary file' ((Invoke-Guard @{ tool_name = 'Read'; tool_input = @{ file_path = (Join-Path $work 'README.md') }; cwd = $work }).Code -eq 0)
        Assert-Guard 'allows writing text that only mentions the path' ((Invoke-Guard @{ tool_name = 'Write'; tool_input = @{ file_path = (Join-Path $work 'n.md'); content = "see $docs" }; cwd = $work }).Code -eq 0)

        # --- PreToolUse guard, agy payloads (deny or allow on stdout, exit 0) ---
        Write-Note "PreToolUse guard, agy"
        function Agy-Call($name, $toolArgs) { Invoke-Guard @{ toolCall = @{ name = $name; args = $toolArgs }; workspacePaths = @($work) } }
        $denied = Agy-Call 'run_command' @{ CommandLine = 'git push --force origin main'; Cwd = $work }
        Assert-Guard 'agy: denies a force-push to main' (($denied.Code -eq 0) -and ($denied.Out -match '"decision":\s*"deny"'))
        $allowed = Agy-Call 'run_command' @{ CommandLine = 'git push origin main'; Cwd = $work }
        Assert-Guard 'agy: allows a normal push' (($allowed.Code -eq 0) -and ($allowed.Out -match '"decision":\s*"allow"'))
        $denied = Agy-Call 'view_file' @{ AbsolutePath = $docs }
        Assert-Guard 'agy: denies reading life-os/documentos from another repo' ($denied.Out -match '"decision":\s*"deny"')
        $allowed = Invoke-Guard @{ toolCall = @{ name = 'view_file'; args = @{ AbsolutePath = $docs } }; workspacePaths = @('D:\Code\life-os') }
        Assert-Guard 'agy: allows reading life-os/documentos inside life-os' ($allowed.Out -match '"decision":\s*"allow"')

        # --- the guard is wired where each tool reads its hooks ---
        Write-Note "wiring"
        $claudeHooks = (Get-Content (Join-Path $repo 'claude' 'settings.json') -Raw | ConvertFrom-Json -AsHashtable).hooks
        $agyHooks = Get-Content (Join-Path $repo 'agy' 'hooks.json') -Raw
        $claudeCmd = ($claudeHooks.PreToolUse | ConvertTo-Json -Depth 8)
        Assert-Guard 'claude/settings.json runs the guard before every tool' ($claudeCmd -match 'dotfiles-hooks/guard\.py')
        Assert-Guard 'claude/settings.json fails open when guard.py is missing' ($claudeCmd -match 'exists\(p\)')
        Assert-Guard 'agy/hooks.json runs the guard before every tool' (($agyHooks -match 'PreToolUse') -and ($agyHooks -match 'dotfiles-hooks/guard\.py'))
        Assert-Guard 'agy/hooks.json fails open with allow when guard.py is missing' (($agyHooks -match 'exists\(p\)') -and ($agyHooks -match 'allow'))
    } finally {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }

    # Warn about repos under D:\Code that override core.hooksPath (husky, lefthook, .githooks)
    # and therefore skip the global commit-msg guard. Read-only: touches no repo config.
    Warn-RepoLocalHooksPath

    # What this machine has applied. A warning, not a failure: the tests above prove the
    # guards work, this says whether ./install.ps1 has switched them on here yet.
    $global = git config --global --get core.hooksPath
    if ($global -and ((Resolve-Path $global -ErrorAction SilentlyContinue).Path -eq (Resolve-Path $gitHooksDir).Path)) {
        Write-Ok "git core.hooksPath $($c.Dim)points at git/hooks$($c.Reset)"
    } else {
        Write-Warn "git core.hooksPath is not set to $(Format-Path $gitHooksDir) $($c.Dim)here yet, run ./install.ps1 -Components git$($c.Reset)"
    }
    if (Test-Path (Join-Path $guardHome 'guard.py')) {
        Write-Ok "$(Format-Path $guardHome) $($c.Dim)links to agents/hooks$($c.Reset)"
    } else {
        Write-Warn "$(Format-Path $guardHome) is missing $($c.Dim)here yet, run ./install.ps1 -Components claude,agy$($c.Reset)"
    }
    return ($script:guardFails -eq 0)
}


if ($Check) {
    Write-Section "Generated instructions"
    $okInstructions = Sync-AgentInstructions $true
    Write-Section "Skill parity"
    $okSkills = Test-SkillParity
    Write-Section "Guards"
    $okGuards = Test-Guards
    if ($okInstructions -and $okSkills -and $okGuards) { exit 0 } else { exit 1 }
}


function Link-Config($target, $source) {
    $shown = Format-Path $target
    $dir = Split-Path $target
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $existing = Get-Item -Path $target -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType -eq "SymbolicLink") {
            # Already a link (maybe stale) — drop it and re-create. Deleted through
            # .NET rather than Remove-Item -Recurse, which on a directory symlink can
            # walk into the target and delete the repo's own files.
            if ($existing.PSIsContainer) {
                [System.IO.Directory]::Delete($existing.FullName)
            } else {
                [System.IO.File]::Delete($existing.FullName)
            }
        } else {
            # A real file/dir is in the way. Back it up instead of destroying it.
            if (-not (Test-Path $backupDir)) {
                New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
            }
            $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $dest = Join-Path $backupDir ((Split-Path $target -Leaf) + ".$stamp")
            Move-Item -Path $target -Destination $dest -Force
            Write-Warn "$shown $($c.Dim)already existed, backed up to $(Format-Path $dest)$($c.Reset)"
        }
    }

    try {
        New-Item -ItemType SymbolicLink -Path $target -Target $source -ErrorAction Stop | Out-Null
    } catch {
        Write-Fail "$shown $($c.Dim)$($_.Exception.Message)$($c.Reset)"
        return
    }

    Write-Ok $shown
}

# Leaves Claude Code on the dotfiles baseline: only the baseline and WezTerm
# plugins, only the
# executor + browse + notebooklm-mcp MCPs, and only the skills symlinked from this repo. Computes
# everything that's extra, shows it grouped, and asks for ONE single confirmation
# (default No) before deleting. Doesn't touch project repos, dotfiles-managed symlinks,
# or claude.ai connectors (Canva/Drive live on the account, not in ~/.claude.json).
#
# Runs once per profile, with CLAUDE_CONFIG_DIR already pointing at it. The main
# profile keeps its .claude.json in $HOME; an extra profile keeps it inside its own
# folder, and its skills folder is a link to the main one, so only the main one is
# checked for loose skills.
function Clean-ClaudeBaseline($repo, $profileDir, $isMain) {
    $plugins = @(); $mcp = @(); $skills = @(); $other = @()
    $keepMcp = @('executor', 'browse', 'notebooklm-mcp')
    $keepPlugins = @($baselinePlugins + $weztermPlugins | ForEach-Object { $_.Split('@')[0] })

    # 1. Plugins outside the baseline (ignores inline/harness ones, which aren't
    # uninstallable). A plugin installed in more than one scope is listed once per
    # scope, so dedupe: `claude plugin uninstall` takes the id, not the scope.
    foreach ($line in (claude plugin list 2>$null)) {
        if ($line -match '([\w.-]+@[\w.-]+)') {
            $id = $Matches[1]
            $name = $id.Split('@')[0]
            if ($name -notin $keepPlugins -and $id -notmatch '@inline$') { $plugins += $id }
        }
    }
    $plugins = @($plugins | Select-Object -Unique)

    # 2. MCP servers outside the baseline (read from .claude.json; -AsHashtable for empty keys).
    $claudeJson = if ($isMain) { Join-Path $HOME '.claude.json' } else { Join-Path $profileDir '.claude.json' }
    if (Test-Path $claudeJson) {
        try {
            $cfg = Get-Content $claudeJson -Raw | ConvertFrom-Json -AsHashtable
            if ($cfg.mcpServers) {
                foreach ($name in $cfg.mcpServers.Keys) { if ($name -notin $keepMcp) { $mcp += $name } }
            }
        } catch {}
    }

    # 3. Skills in ~/.claude/skills that are NOT symlinks to <repo>/agents/skills.
    $skillsDir = Join-Path $profileDir 'skills'
    $repoSkills = Join-Path $repo 'agents' 'skills'
    if ($isMain -and (Test-Path $skillsDir)) {
        Get-ChildItem -Path $skillsDir -Force | ForEach-Object {
            $isRepoLink = ($_.LinkType -eq 'SymbolicLink') -and $_.Target -and `
                $_.Target.StartsWith($repoSkills, [StringComparison]::OrdinalIgnoreCase)
            $isOrcaLink = ($_.LinkType -eq 'SymbolicLink') -and ($_.Name -in $orcaSkills)
            if (-not ($isRepoLink -or $isOrcaLink)) { $skills += $_.FullName }
        }
    }

    # 4. Loose rules and global settings.local.json (not managed by the repo).
    $rulesDir = Join-Path $profileDir 'rules'
    if (Test-Path $rulesDir) {
        Get-ChildItem -Path $rulesDir -Force -File -Recurse | ForEach-Object { $other += $_.FullName }
    }
    $localSettings = Join-Path $profileDir 'settings.local.json'
    if (Test-Path $localSettings) { $other += $localSettings }

    if (($plugins.Count + $mcp.Count + $skills.Count + $other.Count) -eq 0) {
        Write-Ok "cleanup: already on the baseline"
        return
    }

    Write-Section "Claude cleanup $($c.Dim)$(Format-Path $profileDir), outside the dotfiles baseline$($c.Reset)"
    if ($plugins) { Write-Note "plugins to uninstall";          $plugins | ForEach-Object { Write-Host "      $($c.Red)-$($c.Reset) $_" } }
    if ($mcp)     { Write-Note "MCP servers to remove";         $mcp     | ForEach-Object { Write-Host "      $($c.Red)-$($c.Reset) $_" } }
    if ($skills)  { Write-Note "loose skills to delete";        $skills  | ForEach-Object { Write-Host "      $($c.Red)-$($c.Reset) $(Format-Path $_)" } }
    if ($other)   { Write-Note "rules / settings.local to delete"; $other | ForEach-Object { Write-Host "      $($c.Red)-$($c.Reset) $(Format-Path $_)" } }

    Write-Host ""
    $ans = Read-Host "  Proceed with cleanup? $($c.Dim)(y/N)$($c.Reset)"
    if ($ans -notmatch '^[ysYS]') { Write-Note "cleanup skipped"; return }

    foreach ($p in $plugins) { claude plugin uninstall $p -y --scope user 2>$null; Write-Ok "uninstalled plugin $p" }
    foreach ($m in $mcp)     { claude mcp remove $m --scope user 2>$null;          Write-Ok "removed MCP $m" }
    foreach ($s in $skills)  { Remove-Item $s -Recurse -Force;                     Write-Ok "deleted $(Format-Path $s)" }
    foreach ($o in $other)   { Remove-Item $o -Force;                              Write-Ok "deleted $(Format-Path $o)" }
}

# Claude Code's MCP servers and plugins can't be symlinked — they live in .claude.json
# and in the plugin store — so they're registered through the CLI, once per profile.
function Install-ClaudeExtras($repo) {
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Section "Claude Code $($c.Dim)MCP servers and plugins$($c.Reset)"
        Write-Warn "claude CLI not found, skipping the MCPs and the plugins"
        return
    }

    Install-Browse

    foreach ($profileDir in $claudeProfiles) {
        $isMain = $profileDir -eq $claudeMain
        Write-Section "Claude Code $($c.Dim)MCP servers and plugins · $(Format-Path $profileDir)$($c.Reset)"
        # The CLI picks the profile from CLAUDE_CONFIG_DIR; the main one is the default.
        if ($isMain) { Remove-Item Env:CLAUDE_CONFIG_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_CONFIG_DIR = $profileDir }
        try {
            Install-ClaudeProfileExtras $repo $profileDir $isMain
        } finally {
            Remove-Item Env:CLAUDE_CONFIG_DIR -ErrorAction SilentlyContinue
        }
    }

    Enable-GitSymlinks
}

# One global hooksPath for every repo, every agent and the user. The stubs in git/hooks chain
# to the repo's own .git/hooks, so simple-git-hooks and lint-staged keep running. A repo that
# sets its own core.hooksPath (husky, lefthook, .githooks) overrides this one: its hooks run
# and the commit-msg guard does not.
function Install-GitHooks($repo) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Warn "git not found, skipping the hooks"; return }
    git config --global core.hooksPath $gitHooksDir
    if (-not $IsWindows) {
        Get-ChildItem $gitHooksDir -File | Where-Object { $_.Name -ne 'lib.sh' } | ForEach-Object { chmod +x $_.FullName }
    }
    Write-Ok "git core.hooksPath $($c.Dim)$(Format-Path $gitHooksDir)$($c.Reset)"
    Warn-RepoLocalHooksPath
}

function Enable-GitSymlinks {
    # Git on Windows checks symlinks out as plain (broken) text files unless this is on,
    # and project repos use .claude/skills -> .agents/skills symlinks. Requires Developer
    # Mode (see the header). On macOS and Linux git handles symlinks natively.
    if ($IsWindows -and -not $script:gitSymlinksEnabled) {
        git config --global core.symlinks true
        $script:gitSymlinksEnabled = $true
        Write-Ok "git core.symlinks $($c.Dim)enabled$($c.Reset)"
    }
}

# browse (https://opencode.ai/browse) drives the user's own Brave through its extension, so
# the agent has the user's sign-ins. The binary lands in ~/.local/bin and updates itself;
# adding the extension and pairing it (browse pair) is a one-time step by hand. Windows only.
$browseExe = Join-Path $HOME '.local' 'bin' 'browse.exe'

# Orca plugins kept here, one folder each under orca/ (today the Astro theme for the app and the
# terminal), then the ones in $orcaCatalogPlugins from the official catalog. Orca copies a folder in on install, so after
# editing one, rerun this to update the installed copy. A changed folder gets a new fingerprint
# that Orca wants approved; these folders are this repo's own, so the script approves it.
function Install-OrcaPlugins($repo) {
    Write-Section "Orca $($c.Dim)plugins$($c.Reset)"
    if (-not (Get-Command orca -ErrorAction SilentlyContinue)) {
        Write-Warn "orca CLI not found, skipping the plugins (open Orca once so it adds the CLI)"
        return
    }
    foreach ($dir in Get-ChildItem -Path (Join-Path $repo 'orca') -Directory) {
        $out = orca plugin install $dir.FullName 2>&1 | Out-String
        if ($out -match '(ap1-[0-9a-f]+)') {
            $out = orca plugin install $dir.FullName --approve $Matches[1] 2>&1 | Out-String
        }
        if ($LASTEXITCODE -eq 0) { Write-Ok "$($dir.Name) $($c.Dim)installed$($c.Reset)" }
        else { Write-Fail "$($dir.Name) $($c.Dim)$($out.Trim())$($c.Reset)" }
    }
    foreach ($id in $orcaCatalogPlugins) {
        $out = orca plugin install $id --catalog official 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) { Write-Ok "$id $($c.Dim)installed from the official catalog$($c.Reset)" }
        else { Write-Fail "$id $($c.Dim)$($out.Trim())$($c.Reset)" }
    }
}

function Install-Browse {
    if ($script:browseInstalled) { return }
    $script:browseInstalled = $true
    Write-Section "browse $($c.Dim)the browser MCP, in the user's Brave$($c.Reset)"
    if (-not $IsWindows) {
        Write-Note "not Windows: install browse from https://opencode.ai/browse"
        return
    }
    if (Test-Path $browseExe) {
        Write-Ok "browse $($c.Dim)already installed, it updates itself$($c.Reset)"
    } else {
        & ([scriptblock]::Create((Invoke-RestMethod https://opencode.ai/browse/install.ps1))) --no-setup | Out-Null
        Write-Ok "browse $($c.Dim)installed in $(Format-Path $browseExe)$($c.Reset)"
    }

    # browse drives tabs through the extension debugger API, and Brave shows a "started
    # debugging this browser" bar meanwhile; dismissing it detaches browse mid-task. The flag
    # hides it, and only takes effect when Brave starts, so it goes on every launcher: the
    # shortcuts (the taskbar pin is the Start menu one) and the handler for links opened from
    # other apps. A Brave update can rewrite the Start menu shortcut; rerunning restores it.
    $silent = '--silent-debugger-extension-api'
    $brave = Join-Path $env:ProgramFiles 'BraveSoftware' 'Brave-Browser' 'Application' 'brave.exe'
    if (-not (Test-Path $brave)) {
        Write-Warn "Brave not found at $brave, skipping its launchers (winget install Brave.Brave)"
        return
    }
    $shell = New-Object -ComObject WScript.Shell
    $launchers = @(
        (Join-Path $env:ProgramData 'Microsoft' 'Windows' 'Start Menu' 'Programs' 'Brave.lnk')
        (Join-Path $env:APPDATA 'Microsoft' 'Internet Explorer' 'Quick Launch' 'Brave.lnk')
    )
    foreach ($path in $launchers | Where-Object { Test-Path $_ }) {
        $lnk = $shell.CreateShortcut($path)
        if ($lnk.Arguments -like "*$silent*") { Write-Ok "$(Format-Path $path) $($c.Dim)already silent$($c.Reset)"; continue }
        $lnk.Arguments = "$($lnk.Arguments) $silent".Trim()
        try {
            $lnk.Save()
            Write-Ok "$(Format-Path $path) $($c.Dim)$silent$($c.Reset)"
        } catch {
            Write-Warn "$(Format-Path $path) needs admin: add $silent to its arguments from an elevated shell"
        }
    }
    $handler = 'HKCU:\Software\Classes\BraveHTML\shell\open\command'
    New-Item -Path $handler -Force | Out-Null
    Set-Item -Path $handler -Value "`"$brave`" $silent --single-argument %1"
    Write-Ok "Brave link handler $($c.Dim)$silent$($c.Reset)"
}

function Install-ClaudeProfileExtras($repo, $profileDir, $isMain) {
    # Executor: single MCP hub for all external integrations (Notion, Context7, Vercel, ...).
    # Connections themselves are managed at app.executor.sh; first use prompts an OAuth
    # authorize, where the organization is picked. An entry with another URL is replaced.
    $executorUrl = "https://mcp.executor.sh/mcp"
    if (((claude mcp get executor 2>$null) -join "`n") -notmatch [regex]::Escape("URL: $executorUrl")) {
        claude mcp remove executor --scope user 2>$null | Out-Null
        claude mcp add --transport http executor $executorUrl --scope user | Out-Null
        Write-Ok "executor $($c.Dim)added, run /mcp to authorize$($c.Reset)"
    } else {
        Write-Ok "executor $($c.Dim)already configured$($c.Reset)"
    }

    # browse: the only browser MCP. Playwright-style execute scripts, snapshots, screenshots,
    # console/network and handoff to the user, in the user's Brave through the browse
    # extension (binary installed by Install-Browse). An entry with another command is
    # replaced.
    # NOTE: the stdio separator must be quoted ('--'). `claude` resolves to claude.ps1, and
    # PowerShell swallows a bare -- as its end-of-parameters token, so the CLI would then
    # parse the command's own flags (-y, --from) as claude options and fail.
    if (((claude mcp get browse 2>$null) -join "`n") -notmatch [regex]::Escape($browseExe)) {
        claude mcp remove browse --scope user 2>$null | Out-Null
        claude mcp add browse --scope user '--' $browseExe mcp | Out-Null
        Write-Ok "browse $($c.Dim)added, drives Brave through its extension$($c.Reset)"
    } else {
        Write-Ok "browse $($c.Dim)already configured$($c.Reset)"
    }

    # NotebookLM: notebooks as a long-context knowledge system (notebook_query, source_add,
    # studio/audio, ...). Runs locally over stdio via uvx from PyPI (needs uv), so nothing
    # is installed permanently. Auth is cookie-based per Google account: run
    # `uvx --from notebooklm-mcp-cli nlm login` once. Exposes ~43 tools, so keep it toggled
    # off with /mcp when not working on a notebook-backed project.
    if ((claude mcp list 2>$null) -notmatch "notebooklm-mcp") {
        claude mcp add notebooklm-mcp --scope user '--' uvx --from notebooklm-mcp-cli notebooklm-mcp | Out-Null
        Write-Ok "notebooklm-mcp $($c.Dim)added, authenticate with nlm login$($c.Reset)"
    } else {
        Write-Ok "notebooklm-mcp $($c.Dim)already configured$($c.Reset)"
    }
    # nlm login opens its own isolated profile in whichever Chromium it finds; point it at
    # Brave so no machine needs Google Chrome.
    if (Get-Command nlm -ErrorAction SilentlyContinue) {
        nlm config set auth.browser brave | Out-Null
    }

    # Plugins of the baseline: three Trail of Bits audit skills (fail-open defaults,
    # Semgrep/CodeQL, dependency risk) and midudev's context-meter, plus the WezTerm-only
    # better-claude mods. settings.json declares both marketplaces; each clone is added
    # here when it is missing.
    $marketplaces = claude plugin marketplace list 2>$null
    if ($marketplaces -notmatch "trailofbits") {
        claude plugin marketplace add trailofbits/skills | Out-Null
    }
    if ($marketplaces -notmatch "better-claude") {
        claude plugin marketplace add midudev/better-claude | Out-Null
    }
    $installed = claude plugin list 2>$null
    foreach ($plugin in $baselinePlugins + $weztermPlugins) {
        $name = $plugin.Split('@')[0]
        if ($installed -notmatch [regex]::Escape($plugin)) {
            claude plugin install $plugin --scope user | Out-Null
            # install turns the plugin on in settings.json; a WezTerm one goes back off.
            if ($plugin -in $weztermPlugins) { claude plugin disable $plugin --scope user | Out-Null }
            Write-Ok "$name $($c.Dim)installed$($c.Reset)"
        } else {
            Write-Ok "$name $($c.Dim)already installed$($c.Reset)"
        }
    }

    # Cleanup: removes whatever's extra relative to the baseline (runs after
    # linking skills, so it doesn't flag as "loose" the ones this script just symlinked).
    Clean-ClaudeBaseline $repo $profileDir $isMain
}

# Antigravity CLI rewrites ~/.gemini/antigravity-cli/settings.json atomically on startup
# and stores machine-local state (trustedWorkspaces, model, gcp) inside it, so symlinking
# it would either break on rewrite or dirty the repo with machine paths. Merge the repo's
# managed base keys into the real file instead, leaving existing machine state intact.
function Merge-AgySettings($repo, $target) {
    $shown = Format-Path $target
    $dir = Split-Path $target
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $source = Join-Path $repo 'agy' 'settings.json'
    $base = Get-Content $source -Raw | ConvertFrom-Json -AsHashtable
    $merged = [ordered]@{}
    $hadFile = $false
    $wasLink = $false

    $existingItem = Get-Item -Path $target -Force -ErrorAction SilentlyContinue
    if ($existingItem) {
        $hadFile = $true
        $wasLink = $existingItem.LinkType -eq 'SymbolicLink'
        $raw = Get-Content $target -Raw -ErrorAction SilentlyContinue
        if ($raw -and $raw.Trim()) {
            try {
                $parsed = $raw | ConvertFrom-Json -AsHashtable
                foreach ($k in $parsed.Keys) { $merged[$k] = $parsed[$k] }
            } catch {
                if (-not (Test-Path $backupDir)) {
                    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
                }
                $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
                $dest = Join-Path $backupDir ("agy-settings.json.$stamp")
                Copy-Item -Path $target -Destination $dest -Force
                Write-Warn "$shown $($c.Dim)was not valid JSON, backed up to $(Format-Path $dest)$($c.Reset)"
            }
        }
        if ($wasLink) {
            [System.IO.File]::Delete($existingItem.FullName)
        }
    }

    $changed = (-not $hadFile) -or $wasLink
    foreach ($k in $base.Keys) {
        if (-not $merged.Contains($k) -or (($merged[$k] | ConvertTo-Json -Compress -Depth 10) -ne ($base[$k] | ConvertTo-Json -Compress -Depth 10))) {
            $merged[$k] = $base[$k]
            $changed = $true
        }
    }

    if ($changed) {
        $json = ($merged | ConvertTo-Json -Depth 10) + "`n"
        [System.IO.File]::WriteAllText($target, $json, [System.Text.UTF8Encoding]::new($false))
        Write-Ok "$shown $($c.Dim)merged base settings (preserved local state)$($c.Reset)"
    } else {
        Write-Ok "$shown $($c.Dim)already up to date$($c.Reset)"
    }
}

# Antigravity CLI keeps settings.json as a merged real file (above) and registers MCPs in
# ~/.gemini/config/mcp_config.json via `agy mcp add` so toggling servers with /mcp never
# dirties the repo or breaks a symlink.
# agy reads ~/.gemini/config/hooks.json (named groups; Orca keeps its own orca-status group there).
# Merges the groups from agy/hooks.json into it and leaves every other group untouched.
function Merge-AgyHooks($repo, $targetPath) {
    $srcPath = Join-Path $repo 'agy' 'hooks.json'
    if (-not (Test-Path $srcPath)) { return }
    $src = Get-Content $srcPath -Raw | ConvertFrom-Json -AsHashtable
    $dst = [ordered]@{}
    if (Test-Path $targetPath) {
        try {
            $parsed = Get-Content $targetPath -Raw | ConvertFrom-Json -AsHashtable
            foreach ($k in $parsed.Keys) { $dst[$k] = $parsed[$k] }
        } catch {
            Write-Warn "$(Format-Path $targetPath) $($c.Dim)is not valid JSON, left alone$($c.Reset)"; return
        }
    }
    $changed = $false
    foreach ($k in $src.Keys) {
        if (($dst[$k] | ConvertTo-Json -Compress -Depth 10) -ne ($src[$k] | ConvertTo-Json -Compress -Depth 10)) {
            $dst[$k] = $src[$k]
            $changed = $true
        }
    }
    if (-not $changed) {
        Write-Ok "$(Format-Path $targetPath) $($c.Dim)guard group already there$($c.Reset)"; return
    }
    $parent = Split-Path -Parent $targetPath
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [System.IO.File]::WriteAllText($targetPath, (($dst | ConvertTo-Json -Depth 10) + "`n"), [System.Text.UTF8Encoding]::new($false))
    Write-Ok "$(Format-Path $targetPath) $($c.Dim)guard group merged$($c.Reset)"
}

function Install-AgyExtras($repo) {
    $agySettings = Join-Path $HOME '.gemini' 'antigravity-cli' 'settings.json'
    Write-Section "Antigravity CLI $($c.Dim)base settings and MCP servers$($c.Reset)"
    Merge-AgySettings $repo $agySettings
    Merge-AgyHooks $repo (Join-Path $agyConfig 'hooks.json')

    if (-not (Get-Command agy -ErrorAction SilentlyContinue)) {
        Write-Warn "agy CLI not found, skipping the MCPs"
        return
    }

    Install-Browse

    $mcpPath = Join-Path $HOME '.gemini' 'config' 'mcp_config.json'
    $servers = @{}
    if (Test-Path $mcpPath) {
        $raw = Get-Content $mcpPath -Raw -ErrorAction SilentlyContinue
        if ($raw -and $raw.Trim()) {
            try {
                $parsed = $raw | ConvertFrom-Json -AsHashtable
                if ($parsed.mcpServers) { $servers = $parsed.mcpServers }
            } catch {}
        }
    }

    $executorUrl = 'https://mcp.executor.sh/mcp'
    $curExecutor = $servers['executor']
    $curExecutorUrl = if ($curExecutor) { if ($curExecutor['serverUrl']) { $curExecutor['serverUrl'] } else { $curExecutor['url'] } } else { $null }
    if ($curExecutorUrl -ne $executorUrl) {
        agy mcp remove executor 2>$null | Out-Null
        agy mcp add executor $executorUrl | Out-Null
        Write-Ok "executor $($c.Dim)added, run /mcp in agy to authorize$($c.Reset)"
    } else {
        Write-Ok "executor $($c.Dim)already configured$($c.Reset)"
    }

    $browseCmd = if ($IsWindows) { $browseExe } else { 'browse' }
    $curBrowse = $servers['browse']
    if (-not $curBrowse -or $curBrowse['command'] -ne $browseCmd) {
        agy mcp remove browse 2>$null | Out-Null
        agy mcp add browse $browseCmd mcp | Out-Null
        Write-Ok "browse $($c.Dim)added, drives Brave through its extension$($c.Reset)"
    } else {
        Write-Ok "browse $($c.Dim)already configured$($c.Reset)"
    }

    if (-not $servers.ContainsKey('notebooklm-mcp')) {
        agy mcp add notebooklm-mcp '--' uvx --from notebooklm-mcp-cli notebooklm-mcp | Out-Null
        agy mcp disable notebooklm-mcp | Out-Null
        Write-Ok "notebooklm-mcp $($c.Dim)added (disabled by default; enable with /mcp)$($c.Reset)"
    } else {
        Write-Ok "notebooklm-mcp $($c.Dim)already configured$($c.Reset)"
    }
    if (Get-Command nlm -ErrorAction SilentlyContinue) {
        nlm config set auth.browser brave | Out-Null
    }

    Enable-GitSymlinks
}

# --- Component catalog -------------------------------------------------------
# Each component owns its target paths per OS and the tools it expects to find.
# $PROFILE resolves the PowerShell profile directory on every OS (Documents\PowerShell
# on Windows, ~/.config/powershell elsewhere); only the file name is pinned, so the
# link lands right even when the script runs from a non-console host.
$zedSettings = if ($IsWindows) {
    Join-Path $env:APPDATA 'Zed' 'settings.json'
} else {
    Join-Path $configHome 'zed' 'settings.json'
}

# Claude profiles: ~/.claude plus every ~/.claude-<name> (another account, run with
# CLAUDE_CONFIG_DIR). All of them get the same settings, CLAUDE.md, skills, MCPs and plugins.
$claudeMain = Join-Path $HOME '.claude'
$claudeProfiles = @($claudeMain) + @(Get-ChildItem -Path $HOME -Directory -Force -Filter '.claude-*' |
    ForEach-Object { $_.FullName })

$claudeLinks = @()
foreach ($profileDir in $claudeProfiles) {
    $claudeLinks += @{ Target = (Join-Path $profileDir 'settings.json'); Source = (Join-Path $repo 'claude' 'settings.json') }
    $claudeLinks += @{ Target = (Join-Path $profileDir 'settings.wezterm.json'); Source = (Join-Path $repo 'claude' 'settings.wezterm.json') }
    $claudeLinks += @{ Target = (Join-Path $profileDir 'CLAUDE.md');     Source = (Join-Path $repo 'claude' 'CLAUDE.md') }
}
# The guard script both harnesses call, under one stable path that settings.json can name.
$guardLink = @{ Target = $guardHome; Source = (Join-Path $repo 'agents' 'hooks') }
$claudeLinks += $guardLink
# Link each skill individually so repo-managed skills coexist with local/plugin ones.
Get-ChildItem -Path (Join-Path $repo 'agents' 'skills') -Directory | ForEach-Object {
    $claudeLinks += @{ Target = (Join-Path $claudeMain 'skills' $_.Name); Source = $_.FullName }
}
foreach ($name in $orcaSkills) {
    $claudeLinks += @{ Target = (Join-Path $claudeMain 'skills' $name); Source = (Join-Path $orcaSkillsDir $name) }
}
# An extra profile shares the main skills folder whole, local skills included.
foreach ($profileDir in ($claudeProfiles | Where-Object { $_ -ne $claudeMain })) {
    $claudeLinks += @{ Target = (Join-Path $profileDir 'skills'); Source = (Join-Path $claudeMain 'skills') }
}

# Antigravity CLI (agy): global rules and skills live in ~/.gemini/config/ (shared with
# Antigravity App and kept separate from Orca's junctions in ~/.gemini/skills/). Base
# settings.json is merged in Install-AgyExtras rather than symlinked; only the WezTerm
# layer is symlinked because --settings is read-only.
$agyConfig = Join-Path $HOME '.gemini' 'config'
$agyCliDir = Join-Path $HOME '.gemini' 'antigravity-cli'
$agyLinks = @(
    @{ Target = (Join-Path $agyConfig 'AGENTS.md');              Source = (Join-Path $repo 'agy' 'AGENTS.md') }
    @{ Target = (Join-Path $agyCliDir 'settings.wezterm.json');  Source = (Join-Path $repo 'agy' 'settings.wezterm.json') }
    $guardLink
)
Get-ChildItem -Path (Join-Path $repo 'agents' 'skills') -Directory |
    Where-Object { $_.Name -notin $agyExcludedSkills } |
    ForEach-Object {
        $agyLinks += @{ Target = (Join-Path $agyConfig 'skills' $_.Name); Source = $_.FullName }
    }
foreach ($name in $orcaSkills) {
    $agyLinks += @{ Target = (Join-Path $agyConfig 'skills' $name); Source = (Join-Path $orcaSkillsDir $name) }
}

$catalog = [ordered]@{
    'wezterm' = @{
        Summary = 'terminal: theme, keybindings, panes, tab bar'
        Deps    = @('wezterm')
        Links   = @(
            @{ Target = (Join-Path $HOME '.wezterm.lua'); Source = (Join-Path $repo 'wezterm' '.wezterm.lua') }
        )
    }
    'oh-my-posh' = @{
        Summary = 'prompt theme (Material, tweaked)'
        Deps    = @('oh-my-posh')
        Links   = @(
            @{ Target = (Join-Path $configHome 'oh-my-posh' 'material.omp.json'); Source = (Join-Path $repo 'oh-my-posh' 'material.omp.json') }
        )
    }
    'powershell' = @{
        Summary = 'profile: Oh My Posh init + Unix-style aliases + purple theme'
        Deps    = @('eza')
        Links   = @(
            @{ Target = (Join-Path (Split-Path $PROFILE) 'Microsoft.PowerShell_profile.ps1'); Source = (Join-Path $repo 'powershell' 'Microsoft.PowerShell_profile.ps1') }
        )
    }
    'zed' = @{
        Summary = 'editor: theme, fonts, LSP, agent'
        Deps    = @('zed')
        Links   = @(
            @{ Target = $zedSettings; Source = (Join-Path $repo 'zed' 'settings.json') }
        )
    }
    'orca' = @{
        Summary = 'Orca plugins: the Astro theme and OLED for the editor'
        Deps    = @('orca')
        Links   = @()
        Post    = { param($repo) Install-OrcaPlugins $repo }
    }
    'git' = @{
        Summary = 'global hooks: commit-msg guard, chained to each repo''s own'
        Deps    = @('git')
        Links   = @()
        Post    = { param($repo) Install-GitHooks $repo }
    }
    'claude' = @{
        Summary = 'settings, CLAUDE.md, skills, hooks, MCPs, plugin'
        Deps    = @('claude', 'node', 'uv', 'python')
        Links   = $claudeLinks
        Post    = { param($repo) Install-ClaudeExtras $repo }
    }
    'agy' = @{
        Summary = 'Antigravity CLI: settings, AGENTS.md, skills, hooks, MCPs'
        Deps    = @('agy', 'uv', 'python')
        Links   = $agyLinks
        Post    = { param($repo) Install-AgyExtras $repo }
    }
}

# Install hints per OS, shown only for tools that are actually missing.
$depHints = @{
    'wezterm'    = @{ Windows = 'winget install wez.wezterm';                macOS = 'brew install --cask wezterm';                        Linux = 'https://wezterm.org/install/linux' }
    'oh-my-posh' = @{ Windows = 'winget install JanDeDobbeleer.OhMyPosh';    macOS = 'brew install jandedobbeleer/oh-my-posh/oh-my-posh';  Linux = 'curl -s https://ohmyposh.dev/install.sh | bash -s' }
    'zed'        = @{ Windows = 'winget install ZedIndustries.Zed';          macOS = 'brew install --cask zed';                            Linux = 'curl -f https://zed.dev/install.sh | sh' }
    'claude'     = @{ Windows = 'npm install -g @anthropic-ai/claude-code';  macOS = 'npm install -g @anthropic-ai/claude-code';           Linux = 'npm install -g @anthropic-ai/claude-code' }
    'agy'        = @{ Windows = 'irm https://antigravity.google/cli/install.ps1 | iex'; macOS = 'curl -fsSL https://antigravity.google/cli/install.sh | bash'; Linux = 'curl -fsSL https://antigravity.google/cli/install.sh | bash' }
    'node'       = @{ Windows = 'winget install OpenJS.NodeJS';              macOS = 'brew install node';                                  Linux = 'https://nodejs.org/en/download' }
    'python'     = @{ Windows = 'winget install Python.Python.3.13';         macOS = 'brew install python';                               Linux = 'sudo apt install python3 (then alias python)' }
    'git'        = @{ Windows = 'winget install Git.Git';                    macOS = 'brew install git';                                   Linux = 'sudo apt install git' }
    'uv'         = @{ Windows = 'winget install astral-sh.uv';               macOS = 'brew install uv';                                    Linux = 'curl -LsSf https://astral.sh/uv/install.sh | sh' }
    'orca'       = @{ Windows = 'https://orca.dev';                          macOS = 'https://orca.dev';                                   Linux = 'https://orca.dev' }
    'eza'        = @{ Windows = 'winget install eza-community.eza';          macOS = 'brew install eza';                                   Linux = 'https://github.com/eza-community/eza/blob/main/INSTALL.md' }
}

$nameWidth = ($catalog.Keys | Measure-Object -Property Length -Maximum).Maximum

# Arrow-key picker: ↑↓ to move, space to toggle, a for all/none, enter to confirm.
# Everything starts checked, so a bare Enter installs the whole thing.
function Select-ComponentsInteractive($catalog) {
    $names = @($catalog.Keys)
    $checked = @{}
    foreach ($n in $names) { $checked[$n] = $true }
    $cursor = 0

    Write-Section "Components $($c.Dim)↑↓ move · space toggle · a all/none · enter confirm$($c.Reset)"

    try { [Console]::CursorVisible = $false } catch {}
    try {
        $first = $true
        while ($true) {
            if (-not $first) { Write-Host ("`e[{0}A" -f $names.Count) -NoNewline }
            $first = $false

            for ($i = 0; $i -lt $names.Count; $i++) {
                $n = $names[$i]
                $box = if ($checked[$n]) { "$($c.Green)[x]$($c.Reset)" } else { "$($c.Dim)[ ]$($c.Reset)" }
                $padded = $n.PadRight($nameWidth)
                if ($i -eq $cursor) {
                    $line = "$($c.Cyan)❯$($c.Reset) $box $($c.Bold)$padded$($c.Reset)  $($c.Dim)$($catalog[$n].Summary)$($c.Reset)"
                } else {
                    $line = "  $box $padded  $($c.Dim)$($catalog[$n].Summary)$($c.Reset)"
                }
                Write-Host "`e[2K$line"
            }

            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow'   { $cursor = ($cursor - 1 + $names.Count) % $names.Count; continue }
                'DownArrow' { $cursor = ($cursor + 1) % $names.Count; continue }
                'Spacebar'  { $checked[$names[$cursor]] = -not $checked[$names[$cursor]]; continue }
                'Enter'     { return @($names | Where-Object { $checked[$_] }) }
                'Escape'    { return @() }
            }
            switch ($key.KeyChar) {
                'k' { $cursor = ($cursor - 1 + $names.Count) % $names.Count }
                'j' { $cursor = ($cursor + 1) % $names.Count }
                'a' {
                    $target = -not (@($names | Where-Object { $checked[$_] }).Count -eq $names.Count)
                    foreach ($n in $names) { $checked[$n] = $target }
                }
                'q' { return @() }
            }
        }
    } finally {
        try { [Console]::CursorVisible = $true } catch {}
    }
}

# Fallback for when there's no interactive console to read keys from (piped input, CI).
function Select-ComponentsNumbered($catalog) {
    $names = @($catalog.Keys)
    Write-Section "Components"
    for ($i = 0; $i -lt $names.Count; $i++) {
        $n = $names[$i]
        Write-Host "  $($c.Cyan)$($i + 1)`)$($c.Reset) $($n.PadRight($nameWidth))  $($c.Dim)$($catalog[$n].Summary)$($c.Reset)"
    }

    Write-Host ""
    $ans = Read-Host "  Pick them comma-separated, by number or name $($c.Dim)(Enter = all)$($c.Reset)"
    if (-not $ans -or -not $ans.Trim()) { return $names }

    $picked = @()
    foreach ($token in ($ans -split ',')) {
        $t = $token.Trim()
        if (-not $t) { continue }
        if ($t -match '^\d+$' -and [int]$t -ge 1 -and [int]$t -le $names.Count) {
            $picked += $names[[int]$t - 1]
        } elseif ($names -contains $t) {
            $picked += $t
        } else {
            Write-Warn "ignoring '$t', not a component"
        }
    }
    return @($picked | Select-Object -Unique)
}

function Select-Components($catalog) {
    if ([Console]::IsInputRedirected) { return Select-ComponentsNumbered $catalog }
    try {
        return Select-ComponentsInteractive $catalog
    } catch {
        # No key-reading console available after all.
        return Select-ComponentsNumbered $catalog
    }
}

# --- Run ---------------------------------------------------------------------
Write-Box 'dotfiles' "$os · PowerShell $($PSVersionTable.PSVersion)"

if ($Components) {
    $unknown = @($Components | Where-Object { $_ -notin $catalog.Keys })
    if ($unknown) {
        Write-Fail "unknown component(s): $($unknown -join ', ')"
        Write-Note "valid ones: $($catalog.Keys -join ', ')"
        exit 1
    }
    $selected = @($Components | Select-Object -Unique)
} elseif ($All) {
    $selected = @($catalog.Keys)
} else {
    $selected = Select-Components $catalog
}

if (-not $selected) {
    Write-Section "Nothing selected"
    Write-Note "no changes made"
    exit 0
}

if (('claude' -in $selected) -or ('agy' -in $selected)) {
    Write-Section "Generated instructions $($c.Dim)agents/AGENTS.md → claude/CLAUDE.md, agy/AGENTS.md$($c.Reset)"
    Sync-AgentInstructions $false | Out-Null
}

foreach ($name in $selected) {
    Write-Section "$name $($c.Dim)$($catalog[$name].Summary)$($c.Reset)"
    foreach ($link in $catalog[$name].Links) {
        Link-Config $link.Target $link.Source
    }
}

foreach ($name in $selected) {
    if ($catalog[$name].Post) {
        & $catalog[$name].Post $repo
    }
}

# --- Missing dependencies ----------------------------------------------------
$missing = @()
foreach ($name in $selected) {
    foreach ($dep in $catalog[$name].Deps) {
        if ($dep -notin $missing -and -not (Get-Command $dep -ErrorAction SilentlyContinue)) {
            $missing += $dep
        }
    }
}

if ($missing) {
    Write-Section "Missing on this machine"
    foreach ($dep in $missing) {
        Write-Host "  $($c.Yellow)•$($c.Reset) $($dep.PadRight($nameWidth))  $($c.Dim)$($depHints[$dep].$os)$($c.Reset)"
    }
}

# --- What's left to do by hand -----------------------------------------------
$next = @("restart WezTerm or open a new PowerShell tab")
if ('wezterm' -in $selected) {
    $next += "install JetBrainsMono Nerd Font by hand: https://nerdfonts.com"
}
if ('claude' -in $selected) {
    $next += "run /mcp in Claude Code to authorize Executor"
}
if ('agy' -in $selected) {
    $next += "run /mcp in agy to authorize Executor"
}
if (('claude' -in $selected) -or ('agy' -in $selected)) {
    $next += "authenticate NotebookLM: uvx --from notebooklm-mcp-cli nlm login"
    $next += "for the browse MCP, add the browse extension in Brave and pair it with ~\.local\bin\browse.exe pair"
}
if ('zed' -in $selected) {
    $next += "install the Zed extensions listed in zed/extensions.md"
}

Write-Section "Next"
foreach ($step in $next) { Write-Host "  $($c.Cyan)→$($c.Reset) $($c.Dim)$step$($c.Reset)" }
Write-Host ""
