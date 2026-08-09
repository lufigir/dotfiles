$configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
oh-my-posh init pwsh --config (Join-Path $configHome 'oh-my-posh' 'material.omp.json') | Invoke-Expression

# --- Unix-like aliases (ls, cp, mv, rm, cat, pwd, clear are already native in pwsh) ---

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
