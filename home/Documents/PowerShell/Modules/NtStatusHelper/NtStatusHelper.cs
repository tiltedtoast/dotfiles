using System;
using System.Runtime.InteropServices;

public static class NtStatusHelper
{
    const int FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100;
    const int FORMAT_MESSAGE_IGNORE_INSERTS = 0x00000200;
    const int FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000;
    const int FORMAT_MESSAGE_FROM_HMODULE = 0x00000800;

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr LocalFree(IntPtr hMem);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    static extern int FormatMessage(
        int dwFlags,
        IntPtr lpSource,
        int dwMessageId,
        int dwLanguageId,
        out IntPtr lpBuffer,
        int nSize,
        IntPtr Arguments
    );

    [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
    static extern IntPtr LoadLibrary(string lpFileName);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
    static extern bool FreeLibrary(IntPtr hModule);

    public static string GetNtStatusMessage(uint ntstatus)
    {
        IntPtr hModule = LoadLibrary("NTDLL.DLL");
        if (hModule == IntPtr.Zero)
        {
            return "Failed to load NTDLL.DLL";
        }
        int flags =
            FORMAT_MESSAGE_ALLOCATE_BUFFER
            | FORMAT_MESSAGE_FROM_SYSTEM
            | FORMAT_MESSAGE_FROM_HMODULE
            | FORMAT_MESSAGE_IGNORE_INSERTS;
        int langId = 0; // LANG_NEUTRAL | SUBLANG_DEFAULT
        int result = FormatMessage(
            flags,
            hModule,
            (int)ntstatus,
            langId,
            out IntPtr lpMsgBuf,
            0,
            IntPtr.Zero
        );

        string message;
        if (result == 0)
        {
            int error = Marshal.GetLastWin32Error();
            message = $"FormatMessage failed with error {error}";
        }
        else
        {
            message = Marshal.PtrToStringUni(lpMsgBuf);
            LocalFree(lpMsgBuf);
        }
        FreeLibrary(hModule);
        return message;
    }
}
