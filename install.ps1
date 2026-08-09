#!/usr/bin/env pwsh
# Links these dotfiles into place. Runs on Windows, macOS and Linux under PowerShell 7+.
#
#   ./install.ps1                          # interactive component picker
#   ./install.ps1 -All                     # everything, no prompts
#   ./install.ps1 -Components wezterm,zed  # just those
#
# On Windows it needs Developer Mode enabled (Settings > Privacy & security > For
# developers) so New-Item -ItemType SymbolicLink works without admin. On macOS and
# Linux symlinks need nothing.

param(
    [string[]]$Components,
    [switch]$All
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

# Leaves Claude Code on the dotfiles baseline: only the skill-creator
# plugin, only the
# executor + chrome-devtools + notebooklm-mcp MCPs, and only the skills symlinked from this repo. Computes
# everything that's extra, shows it grouped, and asks for ONE single confirmation
# (default No) before deleting. Doesn't touch project repos, dotfiles-managed symlinks,
# or claude.ai connectors (Canva/Drive live on the account, not in ~/.claude.json).
function Clean-ClaudeBaseline($repo) {
    $plugins = @(); $mcp = @(); $skills = @(); $other = @()
    $keepMcp = @('executor', 'chrome-devtools', 'notebooklm-mcp')
    $keepPlugins = @('skill-creator')

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

    # 2. MCP servers outside the baseline (read from ~/.claude.json; -AsHashtable for empty keys).
    $claudeJson = Join-Path $HOME '.claude.json'
    if (Test-Path $claudeJson) {
        try {
            $cfg = Get-Content $claudeJson -Raw | ConvertFrom-Json -AsHashtable
            if ($cfg.mcpServers) {
                foreach ($name in $cfg.mcpServers.Keys) { if ($name -notin $keepMcp) { $mcp += $name } }
            }
        } catch {}
    }

    # 3. Skills in ~/.claude/skills that are NOT symlinks to <repo>/claude/skills.
    $skillsDir = Join-Path $HOME '.claude' 'skills'
    $repoSkills = Join-Path $repo 'claude' 'skills'
    if (Test-Path $skillsDir) {
        Get-ChildItem -Path $skillsDir -Force | ForEach-Object {
            $isRepoLink = ($_.LinkType -eq 'SymbolicLink') -and $_.Target -and `
                $_.Target.StartsWith($repoSkills, [StringComparison]::OrdinalIgnoreCase)
            if (-not $isRepoLink) { $skills += $_.FullName }
        }
    }

    # 4. Loose rules and global settings.local.json (not managed by the repo).
    $rulesDir = Join-Path $HOME '.claude' 'rules'
    if (Test-Path $rulesDir) {
        Get-ChildItem -Path $rulesDir -Force -File -Recurse | ForEach-Object { $other += $_.FullName }
    }
    $localSettings = Join-Path $HOME '.claude' 'settings.local.json'
    if (Test-Path $localSettings) { $other += $localSettings }

    if (($plugins.Count + $mcp.Count + $skills.Count + $other.Count) -eq 0) {
        Write-Ok "cleanup: already on the baseline"
        return
    }

    Write-Section "Claude cleanup $($c.Dim)(outside the dotfiles baseline)$($c.Reset)"
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

# Claude Code's MCP servers and plugins can't be symlinked — they live in ~/.claude.json
# and in the plugin store — so they're registered through the CLI instead.
function Install-ClaudeExtras($repo) {
    Write-Section "Claude Code $($c.Dim)MCP servers and plugin$($c.Reset)"

    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Warn "claude CLI not found, skipping the MCPs and the skill-creator plugin"
        return
    }

    # Executor: single MCP hub for all external integrations (Notion, Context7, Vercel, ...).
    # Connections themselves are managed at executor.sh; first use prompts an OAuth authorize.
    $executorUrl = "https://executor.sh/felipe-giraldo-s-organization/mcp"
    if ((claude mcp list 2>$null) -notmatch "executor") {
        claude mcp add --transport http executor $executorUrl --scope user | Out-Null
        Write-Ok "executor $($c.Dim)added, run /mcp to authorize$($c.Reset)"
    } else {
        Write-Ok "executor $($c.Dim)already configured$($c.Reset)"
    }

    # Chrome DevTools: browser automation + debugging (navigate, click, screenshots,
    # console/network, performance traces). Runs locally over stdio via npx (needs Node 22+)
    # and drives its own dedicated Chrome profile, so it never touches the personal one.
    # NOTE: the stdio separator must be quoted ('--'). `claude` resolves to claude.ps1, and
    # PowerShell swallows a bare -- as its end-of-parameters token, so the CLI would then
    # parse the command's own flags (-y, --from) as claude options and fail.
    if ((claude mcp list 2>$null) -notmatch "chrome-devtools") {
        claude mcp add chrome-devtools --scope user '--' npx -y chrome-devtools-mcp@latest | Out-Null
        Write-Ok "chrome-devtools $($c.Dim)added$($c.Reset)"
    } else {
        Write-Ok "chrome-devtools $($c.Dim)already configured$($c.Reset)"
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

    # Only plugin we keep is skill-creator.
    if ((claude plugin list 2>$null) -notmatch "skill-creator") {
        claude plugin install skill-creator@claude-plugins-official | Out-Null
        Write-Ok "skill-creator $($c.Dim)installed$($c.Reset)"
    } else {
        Write-Ok "skill-creator $($c.Dim)already installed$($c.Reset)"
    }

    # Git on Windows checks symlinks out as plain (broken) text files unless this is on,
    # and project repos use .claude/skills -> .agents/skills symlinks. Requires Developer
    # Mode (see the header). On macOS and Linux git handles symlinks natively.
    if ($IsWindows) {
        git config --global core.symlinks true
        Write-Ok "git core.symlinks $($c.Dim)enabled$($c.Reset)"
    }

    # Cleanup: removes whatever's extra relative to the baseline (runs after
    # linking skills, so it doesn't flag as "loose" the ones this script just symlinked).
    Clean-ClaudeBaseline $repo
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

$claudeLinks = @(
    @{ Target = (Join-Path $HOME '.claude' 'settings.json'); Source = (Join-Path $repo 'claude' 'settings.json') }
    @{ Target = (Join-Path $HOME '.claude' 'CLAUDE.md');     Source = (Join-Path $repo 'claude' 'CLAUDE.md') }
)
# Link each skill individually so repo-managed skills coexist with local/plugin ones.
Get-ChildItem -Path (Join-Path $repo 'claude' 'skills') -Directory | ForEach-Object {
    $claudeLinks += @{ Target = (Join-Path $HOME '.claude' 'skills' $_.Name); Source = $_.FullName }
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
    'claude' = @{
        Summary = 'settings, CLAUDE.md, skills, MCPs, plugin'
        Deps    = @('claude', 'node', 'uv')
        Links   = $claudeLinks
        Post    = { param($repo) Install-ClaudeExtras $repo }
    }
}

# Install hints per OS, shown only for tools that are actually missing.
$depHints = @{
    'wezterm'    = @{ Windows = 'winget install wez.wezterm';                macOS = 'brew install --cask wezterm';                        Linux = 'https://wezterm.org/install/linux' }
    'oh-my-posh' = @{ Windows = 'winget install JanDeDobbeleer.OhMyPosh';    macOS = 'brew install jandedobbeleer/oh-my-posh/oh-my-posh';  Linux = 'curl -s https://ohmyposh.dev/install.sh | bash -s' }
    'zed'        = @{ Windows = 'winget install ZedIndustries.Zed';          macOS = 'brew install --cask zed';                            Linux = 'curl -f https://zed.dev/install.sh | sh' }
    'claude'     = @{ Windows = 'npm install -g @anthropic-ai/claude-code';  macOS = 'npm install -g @anthropic-ai/claude-code';           Linux = 'npm install -g @anthropic-ai/claude-code' }
    'node'       = @{ Windows = 'winget install OpenJS.NodeJS';              macOS = 'brew install node';                                  Linux = 'https://nodejs.org/en/download' }
    'uv'         = @{ Windows = 'winget install astral-sh.uv';               macOS = 'brew install uv';                                    Linux = 'curl -LsSf https://astral.sh/uv/install.sh | sh' }
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
        Write-Host "  $($c.Cyan)$($i + 1))$($c.Reset) $($n.PadRight($nameWidth))  $($c.Dim)$($catalog[$n].Summary)$($c.Reset)"
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
    $next += "authenticate NotebookLM: uvx --from notebooklm-mcp-cli nlm login"
    $next += "the Chrome DevTools MCP also needs Google Chrome installed"
}
if ('zed' -in $selected) {
    $next += "install the Zed extensions listed in zed/extensions.md"
}

Write-Section "Next"
foreach ($step in $next) { Write-Host "  $($c.Cyan)→$($c.Reset) $($c.Dim)$step$($c.Reset)" }
Write-Host ""
