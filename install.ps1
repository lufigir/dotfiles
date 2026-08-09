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
            Write-Output "Backed up existing $target -> $dest"
        }
    }

    try {
        New-Item -ItemType SymbolicLink -Path $target -Target $source -ErrorAction Stop | Out-Null
    } catch {
        Write-Warning "Failed to link $target -> $source ($($_.Exception.Message))"
        return
    }

    Write-Output "Linked $target -> $source"
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
        Write-Output "Cleanup: nothing to remove, Claude is already on the baseline."
        return
    }

    Write-Output "`n=== Claude cleanup (outside the dotfiles baseline) ==="
    if ($plugins) { Write-Output "Plugins to uninstall:";         $plugins | ForEach-Object { Write-Output "  - $_" } }
    if ($mcp)     { Write-Output "MCP servers to remove:";        $mcp     | ForEach-Object { Write-Output "  - $_" } }
    if ($skills)  { Write-Output "Loose skills to delete:";       $skills  | ForEach-Object { Write-Output "  - $_" } }
    if ($other)   { Write-Output "Rules / settings.local to delete:"; $other | ForEach-Object { Write-Output "  - $_" } }

    $ans = Read-Host "`nProceed with cleanup? (y/N)"
    if ($ans -notmatch '^[ysYS]') { Write-Output "Cleanup skipped."; return }

    foreach ($p in $plugins) { claude plugin uninstall $p -y --scope user 2>$null; Write-Output "Uninstalled plugin: $p" }
    foreach ($m in $mcp)     { claude mcp remove $m --scope user 2>$null;          Write-Output "Removed MCP: $m" }
    foreach ($s in $skills)  { Remove-Item $s -Recurse -Force;                     Write-Output "Deleted loose skill: $s" }
    foreach ($o in $other)   { Remove-Item $o -Force;                              Write-Output "Deleted: $o" }
    Write-Output "Cleanup complete."
}

# Claude Code's MCP servers and plugins can't be symlinked — they live in ~/.claude.json
# and in the plugin store — so they're registered through the CLI instead.
function Install-ClaudeExtras($repo) {
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Warning "claude CLI not found — skipping the Executor + Chrome DevTools + NotebookLM MCPs and the skill-creator plugin. Install Claude Code, then re-run this script."
        return
    }

    # Executor: single MCP hub for all external integrations (Notion, Context7, Vercel, ...).
    # Connections themselves are managed at executor.sh; first use prompts an OAuth authorize.
    $executorUrl = "https://executor.sh/felipe-giraldo-s-organization/mcp"
    if ((claude mcp list 2>$null) -notmatch "executor") {
        claude mcp add --transport http executor $executorUrl --scope user
        Write-Output "Added Executor MCP (run /mcp in Claude Code to authorize)"
    } else {
        Write-Output "Executor MCP already configured"
    }

    # Chrome DevTools: browser automation + debugging (navigate, click, screenshots,
    # console/network, performance traces). Runs locally over stdio via npx (needs Node 22+)
    # and drives its own dedicated Chrome profile, so it never touches the personal one.
    # NOTE: the stdio separator must be quoted ('--'). `claude` resolves to claude.ps1, and
    # PowerShell swallows a bare -- as its end-of-parameters token, so the CLI would then
    # parse the command's own flags (-y, --from) as claude options and fail.
    if ((claude mcp list 2>$null) -notmatch "chrome-devtools") {
        claude mcp add chrome-devtools --scope user '--' npx -y chrome-devtools-mcp@latest
        Write-Output "Added Chrome DevTools MCP"
    } else {
        Write-Output "Chrome DevTools MCP already configured"
    }

    # NotebookLM: notebooks as a long-context knowledge system (notebook_query, source_add,
    # studio/audio, ...). Runs locally over stdio via uvx from PyPI (needs uv), so nothing
    # is installed permanently. Auth is cookie-based per Google account: run
    # `uvx --from notebooklm-mcp-cli nlm login` once. Exposes ~43 tools, so keep it toggled
    # off with /mcp when not working on a notebook-backed project.
    if ((claude mcp list 2>$null) -notmatch "notebooklm-mcp") {
        claude mcp add notebooklm-mcp --scope user '--' uvx --from notebooklm-mcp-cli notebooklm-mcp
        Write-Output "Added NotebookLM MCP (run 'uvx --from notebooklm-mcp-cli nlm login' to authenticate)"
    } else {
        Write-Output "NotebookLM MCP already configured"
    }

    # Only plugin we keep is skill-creator.
    if ((claude plugin list 2>$null) -notmatch "skill-creator") {
        claude plugin install skill-creator@claude-plugins-official
    } else {
        Write-Output "skill-creator plugin already installed"
    }

    # Git on Windows checks symlinks out as plain (broken) text files unless this is on,
    # and project repos use .claude/skills -> .agents/skills symlinks. Requires Developer
    # Mode (see the header). On macOS and Linux git handles symlinks natively.
    if ($IsWindows) {
        git config --global core.symlinks true
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
        Summary = 'WezTerm config (theme, keybindings, panes, tab bar)'
        Deps    = @('wezterm')
        Links   = @(
            @{ Target = (Join-Path $HOME '.wezterm.lua'); Source = (Join-Path $repo 'wezterm' '.wezterm.lua') }
        )
    }
    'oh-my-posh' = @{
        Summary = 'Oh My Posh prompt theme (Material, tweaked)'
        Deps    = @('oh-my-posh')
        Links   = @(
            @{ Target = (Join-Path $configHome 'oh-my-posh' 'material.omp.json'); Source = (Join-Path $repo 'oh-my-posh' 'material.omp.json') }
        )
    }
    'powershell' = @{
        Summary = 'PowerShell profile (Oh My Posh init + Unix-style aliases)'
        Deps    = @()
        Links   = @(
            @{ Target = (Join-Path (Split-Path $PROFILE) 'Microsoft.PowerShell_profile.ps1'); Source = (Join-Path $repo 'powershell' 'Microsoft.PowerShell_profile.ps1') }
        )
    }
    'zed' = @{
        Summary = 'Zed settings (theme, fonts, LSP, agent)'
        Deps    = @('zed')
        Links   = @(
            @{ Target = $zedSettings; Source = (Join-Path $repo 'zed' 'settings.json') }
        )
    }
    'claude' = @{
        Summary = 'Claude Code settings, CLAUDE.md, skills, MCPs and plugin'
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
}

function Select-Components($catalog) {
    $names = @($catalog.Keys)
    Write-Output "`nComponents available:"
    for ($i = 0; $i -lt $names.Count; $i++) {
        Write-Output ("  {0}) {1,-11} {2}" -f ($i + 1), $names[$i], $catalog[$names[$i]].Summary)
    }
    $ans = Read-Host "`nPick them comma-separated, by number or name (Enter = all)"
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
            Write-Warning "Ignoring '$t': not a component."
        }
    }
    return @($picked | Select-Object -Unique)
}

# --- Run ---------------------------------------------------------------------
Write-Output "dotfiles -> $os (PowerShell $($PSVersionTable.PSVersion))"

if ($Components) {
    $unknown = @($Components | Where-Object { $_ -notin $catalog.Keys })
    if ($unknown) {
        Write-Host "Unknown component(s): $($unknown -join ', '). Valid ones: $($catalog.Keys -join ', ')."
        exit 1
    }
    $selected = @($Components | Select-Object -Unique)
} elseif ($All) {
    $selected = @($catalog.Keys)
} else {
    $selected = Select-Components $catalog
}

if (-not $selected) {
    Write-Output "Nothing selected, nothing to do."
    exit 0
}

Write-Output "Installing: $($selected -join ', ')`n"

foreach ($name in $selected) {
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
    Write-Output "`n=== Missing on this machine ==="
    foreach ($dep in $missing) {
        Write-Output ("  {0,-11} {1}" -f $dep, $depHints[$dep].$os)
    }
}

Write-Output "`nDone. Restart WezTerm or open a new PowerShell tab."
if ('wezterm' -in $selected) {
    Write-Output "WezTerm needs JetBrainsMono Nerd Font installed by hand: https://nerdfonts.com"
}
if ('claude' -in $selected) {
    Write-Output "Open Claude Code and run /mcp to authorize Executor (Notion, Context7, Supabase, Vercel)."
    Write-Output "Authenticate NotebookLM once with: uvx --from notebooklm-mcp-cli nlm login"
    Write-Output "The Chrome DevTools MCP also needs Google Chrome installed."
}
