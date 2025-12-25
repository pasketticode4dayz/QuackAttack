Write-Host "PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
Write-Host "Current directory: $(Get-Location)" -ForegroundColor Cyan

# Check for required assemblies
Write-Host "Checking for required assemblies..." -ForegroundColor Yellow
try {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    Write-Host "System.Windows.Forms loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to load System.Windows.Forms: $_"
    exit 1
}

try {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Media;
using System.Threading;

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
        player.Load(); // Changed from LoadAsync to Load for reliability
    }

    public static void Start() {
        isRunning = true;
        _hookID = SetHook(_proc);
        if (_hookID == IntPtr.Zero) {
            throw new Exception("Failed to set keyboard hook");
        }
        while (isRunning) {
            Application.DoEvents();
            Thread.Sleep(100);
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
            // Debounce: only play if enough time has passed since last keypress
            if ((DateTime.Now - lastKeyTime).TotalMilliseconds > 50 && player != null) {
                lastKeyTime = DateTime.Now;
                try {
                    // Use Play() instead of PlaySync() to avoid blocking the hook
                    player.Play();
                } catch {
                    // Silently ignore playback errors
                }
            }
        }
        return CallNextHookEx(_hookID, nCode, wParam, lParam);
    }
}
"@ -ReferencedAssemblies System.Windows.Forms, System.Drawing -ErrorAction Stop
    Write-Host "C# type compiled successfully" -ForegroundColor Green
} catch {
    Write-Error "Add-Type compilation failed: $($_.Exception.Message)"
    if ($_.Exception -is [System.Reflection.ReflectionTypeLoadException]) {
        $_.Exception.LoaderExceptions | ForEach-Object { Write-Error "LoaderException: $($_.Message)" }
    }
    exit 2
}

# Set the sound file path
$soundPath = "C:\Users\nathan\Documents\VSCode\Powershell\QuackAttack\Quack.wav"

# Verify WAV exists
if (-not (Test-Path $soundPath)) {
    Write-Error "Sound file not found: $soundPath"
    Write-Error "Looking in: $(Get-Location)"
    exit 3
}

Write-Host "Keyboard sound hook activated!" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

[KeyboardHook]::SetSound($soundPath)

try {
    # Start keyboard hook in background
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable('soundPath', $soundPath)
    
    $powershell = [powershell]::Create()
    $powershell.Runspace = $runspace
    $null = $powershell.AddScript({
        [KeyboardHook]::SetSound($soundPath)
        [KeyboardHook]::Start()
    })
    
    $handle = $powershell.BeginInvoke()
    
    # Simple loop that responds to Ctrl+C
    while ($true) {
        Start-Sleep -Milliseconds 100
    }
} catch {
    Write-Host "`nShutting down..." -ForegroundColor Yellow
} finally {
    try {
        [KeyboardHook]::Stop()
        if ($powershell) {
            $powershell.Stop()
            $powershell.Dispose()
        }
        if ($runspace) {
            $runspace.Close()
            $runspace.Dispose()
        }
        Write-Host "Keyboard hook stopped" -ForegroundColor Yellow
    } catch {
        Write-Warning "Cleanup failed: $($_.Exception.Message)"
    }
}
