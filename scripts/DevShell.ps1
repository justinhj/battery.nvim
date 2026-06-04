if ($env:DEV_SHELL) {
    [Console]::Error.WriteLine("info: dev-shell already activated")
    return
}
$env:DEV_SHELL = "battery.nvim"

$repo = (Get-Location).Path
$gitDir = Join-Path $repo ".git"
if (-not (Test-Path -LiteralPath $gitDir -PathType Container)) {
    [Console]::Error.WriteLine("error: `$PWD ($repo) is not a git repository")
    return
}

$env:XDG_DATA_HOME = Join-Path $repo ".xdg/data"
$env:XDG_CONFIG_HOME = Join-Path $repo ".xdg/config"
$env:XDG_STATE_HOME = Join-Path $repo ".xdg/state"
$env:XDG_CACHE_HOME = Join-Path $repo ".xdg/cache"

foreach ($dir in @(
        $env:XDG_DATA_HOME,
        $env:XDG_CONFIG_HOME,
        $env:XDG_STATE_HOME,
        $env:XDG_CACHE_HOME
    )) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

$packDir = Join-Path $env:XDG_CONFIG_HOME "nvim/pack/dev/opt"
New-Item -ItemType Directory -Path $packDir -Force | Out-Null

$linkPath = Join-Path $packDir "battery.nvim"
if (Test-Path -LiteralPath $linkPath) {
    $item = Get-Item -LiteralPath $linkPath -Force
    $isReparsePoint = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    if (-not $isReparsePoint) {
        [Console]::Error.WriteLine("error: $linkPath already exists and is not a symlink or junction")
        return
    }
} else {
    try {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $repo -ErrorAction Stop | Out-Null
    } catch {
        New-Item -ItemType Junction -Path $linkPath -Target $repo -ErrorAction Stop | Out-Null
    }
}

if (-not $global:__BatteryDevShellPromptWrapped) {
    $promptCommand = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
    if ($null -ne $promptCommand) {
        $global:__BatteryDevShellOriginalPrompt = $promptCommand.ScriptBlock
    }

    function global:prompt {
        $prefix = "(dev-shell) "
        if ($global:__BatteryDevShellOriginalPrompt) {
            return $prefix + (& $global:__BatteryDevShellOriginalPrompt)
        }

        return $prefix + "PS $((Get-Location).Path)> "
    }

    $global:__BatteryDevShellPromptWrapped = $true
}
