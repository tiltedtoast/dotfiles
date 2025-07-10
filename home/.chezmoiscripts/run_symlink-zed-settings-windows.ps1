if ($IsWindows) {
    $src = Join-Path $Env:USERPROFILE '.config\zed\settings.json'
    $dst = Join-Path $Env:APPDATA 'zed\settings.json'
    if (-Not (Test-Path $dst)) {
        New-Item -ItemType SymbolicLink -Path $dst -Value $src
    }
}