$configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
oh-my-posh init pwsh --config (Join-Path $configHome 'oh-my-posh' 'material.omp.json') | Invoke-Expression

# --- Palette -----------------------------------------------------------------
# Same purple palette as the WezTerm colors and the oh-my-posh prompt. Kept as raw
# hex so it can feed both $PSStyle (which wants escape sequences) and EZA_COLORS
# (which wants bare SGR parameters).

$palette = @{
    Purple  = 0xB084F5
    Magenta = 0xC792EA
    Pink    = 0xE0A6E8
    Green   = 0x7FDBAA
    Yellow  = 0xF5D76E
    Cyan    = 0x63D9E0
    Blue    = 0x7C7CE0
    Text    = 0xE0D6F5
    Dim     = 0x7A5C9E
    Faint   = 0x4B3B5C
    Red     = 0xF5B8E8
}
$fg = { param($n) $PSStyle.Foreground.FromRgb($palette[$n]) }
$sgr = { param($n) $v = $palette[$n]; '38;2;{0};{1};{2}' -f (($v -shr 16) -band 0xFF), (($v -shr 8) -band 0xFF), ($v -band 0xFF) }

# --- Unix-like aliases (cp, mv, rm, cat, pwd, clear are already native in pwsh) ---

# Windows only: on macOS/Linux the real binaries are on PATH and beat these one-line
# stand-ins (grep -r, which -a, touch -d, ...), so defining them there would be a downgrade.
if ($IsWindows) {
    function touch { param([string]$Path) if (Test-Path $Path) { (Get-Item $Path).LastWriteTime = Get-Date } else { New-Item -ItemType File -Path $Path | Out-Null } }
    function which { param([string]$Name) Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue }
    function grep { param([string]$Pattern, [string]$Path) if ($Path) { Select-String -Pattern $Pattern -Path $Path } else { $input | Select-String -Pattern $Pattern } }
}

# Everywhere: these are bash/zsh builtins, not binaries, so pwsh lacks them on every OS.
function ll { Get-ChildItem -Force @args }
function export { param([string]$Assignment) $name, $value = $Assignment -split '=', 2; Set-Item -Path "Env:$name" -Value $value }
function mkdirp { param([string]$Path) New-Item -ItemType Directory -Force -Path $Path | Out-Null }

# --- Listings ----------------------------------------------------------------
# eza replaces ls with icons, per-file git status and a tree mode. It emits text
# rather than FileInfo objects, so Get-ChildItem (gci) stays the one to pipe from.

if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Alias ls -Force -ErrorAction SilentlyContinue

    $env:EZA_COLORS = @(
        "di=1;$(& $sgr Purple)"                                        # directories
        "ex=$(& $sgr Green)"                                           # executables
        "ln=$(& $sgr Cyan)"                                            # symlinks
        "hd=1;$(& $sgr Magenta)"                                       # table header
        "xx=$(& $sgr Faint)"                                           # punctuation
        "sn=$(& $sgr Text)"; "sb=$(& $sgr Dim)"                        # size number / unit
        "da=$(& $sgr Dim)"                                             # dates
        "uu=$(& $sgr Magenta)"; "gu=$(& $sgr Dim)"                     # own user / group
        "ur=$(& $sgr Magenta)"; "uw=$(& $sgr Pink)"; "ux=$(& $sgr Green)"; "ue=$(& $sgr Green)"
        "gr=$(& $sgr Dim)"; "gw=$(& $sgr Dim)"; "gx=$(& $sgr Dim)"
        "tr=$(& $sgr Dim)"; "tw=$(& $sgr Dim)"; "tx=$(& $sgr Dim)"
        "ga=$(& $sgr Green)"; "gm=$(& $sgr Yellow)"; "gd=$(& $sgr Red)"; "gv=$(& $sgr Blue)"
    ) -join ':'

    # The long list: size, relative date, per-file git status, and the branch of any
    # subdirectory that is itself a repo. --git-repos-no-status costs ~90ms on a folder
    # full of repos; the full --git-repos walks every object and takes seconds, so it
    # gets its own command (lg) instead of slowing down the everyday listing.
    function Invoke-Eza {
        eza --icons --group-directories-first --long --header --git --git-repos-no-status --time-style=relative @args
    }

    # ls stays the plain grid; ll is the detailed one and keeps showing dotfiles,
    # the way `Get-ChildItem -Force` did before eza.
    function ls { eza --icons --group-directories-first @args }
    function la { eza --icons --group-directories-first --all @args }
    function ll { Invoke-Eza --all @args }
    function lt { eza --icons --group-directories-first --tree --level=2 @args }
    function lg { Invoke-Eza --all --git-repos @args }
}

# --- Theme -------------------------------------------------------------------
# $PSStyle ships with PowerShell 7.2+, so Get-ChildItem, table headers, errors and
# the PSReadLine syntax highlighting all get themed without installing anything.

$PSStyle.FileInfo.Directory = $PSStyle.Bold + (& $fg Purple)
$PSStyle.FileInfo.SymbolicLink = & $fg Cyan
$PSStyle.FileInfo.Executable = & $fg Green
$PSStyle.FileInfo.Extension.Clear()
$extensionColors = @{
    Green  = '.exe', '.msi', '.bat', '.cmd', '.com', '.ps1', '.psm1', '.sh'
    Pink   = '.zip', '.tar', '.gz', '.tgz', '.7z', '.rar', '.xz', '.zst', '.bz2'
    Yellow = '.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp', '.ico', '.mp4', '.webm', '.mp3', '.wav'
    Blue   = '.json', '.jsonc', '.yaml', '.yml', '.toml', '.ini', '.xml', '.env', '.lock', '.conf', '.config'
    Cyan   = '.md', '.mdx', '.txt', '.rst', '.pdf'
    Dim    = '.log', '.tmp', '.bak', '.cache', '.pyc', '.map'
}
foreach ($name in $extensionColors.Keys) {
    foreach ($ext in $extensionColors[$name]) { $PSStyle.FileInfo.Extension[$ext] = & $fg $name }
}

# Table headers, errors and progress: the defaults are bright green/red and clash
$PSStyle.Formatting.TableHeader = $PSStyle.Bold + (& $fg Magenta)
$PSStyle.Formatting.FormatAccent = & $fg Dim
$PSStyle.Formatting.Error = & $fg Red
$PSStyle.Formatting.ErrorAccent = & $fg Pink
$PSStyle.Formatting.Warning = & $fg Yellow
$PSStyle.Formatting.Verbose = & $fg Cyan
$PSStyle.Formatting.Debug = & $fg Dim
$PSStyle.Progress.Style = $PSStyle.Bold + (& $fg Magenta)

# Syntax highlighting while typing
if (Get-Module -ListAvailable PSReadLine) {
    Set-PSReadLineOption -Colors @{
        Command                = $PSStyle.Bold + (& $fg Magenta)
        Keyword                = & $fg Pink
        Parameter              = & $fg Purple
        Operator               = & $fg Pink
        Variable               = & $fg Cyan
        String                 = & $fg Green
        Number                 = & $fg Yellow
        Type                   = & $fg Blue
        Member                 = & $fg Text
        Default                = & $fg Text
        Comment                = $PSStyle.Italic + (& $fg Dim)
        Emphasis               = & $fg Yellow
        Error                  = & $fg Red
        Selection              = $PSStyle.Background.FromRgb(0x4B2E83) + (& $fg Text)
        InlinePrediction       = & $fg Faint
        ListPrediction         = & $fg Dim
        ListPredictionSelected = $PSStyle.Background.FromRgb(0x2E1D47)
        ContinuationPrompt     = & $fg Dim
    }
}

Remove-Variable palette, fg, sgr, extensionColors, name, ext -ErrorAction SilentlyContinue
