if ($IsWindows) {
    $src = Join-Path $Env:USERPROFILE '.config\nvim'
    $dst = Join-Path $Env:LOCALAPPDATA 'nvim'
    if (-Not (Test-Path $dst)) {
        New-Item -ItemType Junction -Path $dst -Value $src
    }
}