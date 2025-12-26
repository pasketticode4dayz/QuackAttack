Write-Host "PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan

# Load required assemblies
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Media;

public class KeyboardHook {
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    
    private static LowLevelKeyboardProc _proc = HookCallback;
    private static IntPtr _hookID = IntPtr.Zero;
    private static SoundPlayer player;
    private static bool isRunning = false;
    private static DateTime lastKeyTime = DateTime.MinValue;

    public delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    public static void SetSound(string soundPath) {
        player = new SoundPlayer(soundPath);
        player.Load();
    }

    public static void Start() {
        isRunning = true;
        _hookID = SetHook(_proc);
        if (_hookID == IntPtr.Zero) {
            throw new Exception("Failed to set keyboard hook");
        }
        while (isRunning) {
            Application.DoEvents();
            System.Threading.Thread.Sleep(100);
        }
    }

    public static void Stop() {
        isRunning = false;
        if (_hookID != IntPtr.Zero) {
            UnhookWindowsHookEx(_hookID);
        }
    }

    private static IntPtr SetHook(LowLevelKeyboardProc proc) {
        using (var curProcess = System.Diagnostics.Process.GetCurrentProcess())
        using (var curModule = curProcess.MainModule) {
            return SetWindowsHookEx(WH_KEYBOARD_LL, proc, GetModuleHandle(curModule.ModuleName), 0);
        }
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
            if ((DateTime.Now - lastKeyTime).TotalMilliseconds > 50 && player != null) {
                lastKeyTime = DateTime.Now;
                player.Play();
            }
        }
        return CallNextHookEx(_hookID, nCode, wParam, lParam);
    }
}
"@ -ReferencedAssemblies System.Windows.Forms, System.Drawing

# Set the sound file path
$soundPath = "C:\Users\nathan\Documents\VSCode\Powershell\QuackAttack\Quack.wav"

if (-not (Test-Path $soundPath)) {
    Write-Error "Sound file not found: $soundPath"
    exit 1
}

Write-Host "Keyboard sound hook activated! Press Ctrl+C to stop" -ForegroundColor Green

[KeyboardHook]::SetSound($soundPath)

try {
    [KeyboardHook]::Start()
} finally {
    [KeyboardHook]::Stop()
    Write-Host "Keyboard hook stopped" -ForegroundColor Yellow
}
