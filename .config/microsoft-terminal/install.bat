:: PLEASE NOTE: this must be run manually outside of WSL, must be run when the 'Microsoft Terminal' is not running.
:: CONTEXT: https://github.com/microsoft/terminal/issues/1812
del %LocalAppData%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
mklink /h %LocalAppData%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json %UserProfile%\Documents\MEGA\.dotfiles\microsoft-terminal\settings.json