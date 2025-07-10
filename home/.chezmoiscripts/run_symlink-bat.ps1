if ($IsWindows) {
    $src = Join-Path $Env:USERPROFILE '.config\bat'
    $dst = Join-Path $Env:APPDATA 'bat'
    if (-Not (Test-Path $dst)) {
        New-Item -ItemType Junction -Path $dst -Value $src
    }
}