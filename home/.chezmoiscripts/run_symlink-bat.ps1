if ($IsWindows) {
    $src = Join-Path $Env:USERPROFILE '.config\bat'
    $dst = Join-Path $Env:APPDATA 'bat'
    $dst_scoop = Join-Path $Env:USERPROFILE 'scoop\persist\bat'
    if (-Not (Test-Path $dst)) {
        New-Item -ItemType Junction -Path $dst -Value $src
    }
    if (-Not (Test-Path $dst_scoop) -or ((Get-Item $dst_scoop).LinkType -ne 'Junction')) {
        if (Test-Path $dst_scoop) {
            Remove-Item $dst_scoop -Force -Recurse
        }
        New-Item -ItemType Junction -Path $dst_scoop -Value $src
    }
}