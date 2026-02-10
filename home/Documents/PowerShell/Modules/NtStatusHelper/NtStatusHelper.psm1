# NtStatusHelper.psm1

$dllPath = Join-Path $PSScriptRoot 'NtStatusHelper.dll'

if (-not (
    [System.AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.GetName().Name -eq 'NtStatusHelper' }
)) {
    Add-Type -Path $dllPath
}

function Convert-I32ToU32 {
    param([int32]$i32)
    if ($i32 -lt 0) { $i32 + 0x100000000 } else { $i32 }
}

function Convert-NtStatus {
    param([int32]$code)
    $u32 = Convert-I32ToU32 $code
    $msg = [NtStatusHelper]::GetNtStatusMessage($u32)
    if ($u32 -ge 0xC0000000) {
        Write-Host "NTSTATUS 0x$($u32.ToString('X8')) => $msg" -ForegroundColor Red
    } else {
        Write-Output ("NTSTATUS 0x{0:X8} => {1}" -f $u32, $msg)
    }
}

function Test-NtStatus {
    Convert-NtStatus $LASTEXITCODE
}

Export-ModuleMember -Function Convert-I32ToU32, Convert-NtStatus, Test-NtStatus

