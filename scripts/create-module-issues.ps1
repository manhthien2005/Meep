# scripts/create-module-issues.ps1
# Dispatcher: dot-source helpers + module files, chay theo -Module param
# Usage:
#   .\scripts\create-module-issues.ps1                       # tat ca modules
#   .\scripts\create-module-issues.ps1 -Module reaction      # chi Reaction
#   .\scripts\create-module-issues.ps1 -Module "feed,space"  # Feed + Space
#
# Modules: contracts | friend | feed | notification | profile | settings
#          reaction  | diary  | space | widget       | chat    | all

param([string]$Module = "all")

$env:Path     = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:GH_TOKEN = [System.Environment]::GetEnvironmentVariable("GH_TOKEN", "User")
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding           = [System.Text.UTF8Encoding]::new()

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Dot-source helpers (config + New-Issue, New-Module, etc.)
. "$scriptDir\_helpers.ps1"

# Dot-source tung module
. "$scriptDir\modules\auth.ps1"
. "$scriptDir\modules\contracts.ps1"
. "$scriptDir\modules\friend.ps1"
. "$scriptDir\modules\feed.ps1"
. "$scriptDir\modules\notification.ps1"
. "$scriptDir\modules\profile.ps1"
. "$scriptDir\modules\settings.ps1"
. "$scriptDir\modules\reaction.ps1"
. "$scriptDir\modules\diary.ps1"
. "$scriptDir\modules\space.ps1"
. "$scriptDir\modules\widget.ps1"
. "$scriptDir\modules\chat.ps1"

# Dispatch
$modulesToRun = if ($Module -eq "all") {
    @("auth","contracts","friend","feed","notification","profile","settings","reaction","diary","space","widget","chat")
} else {
    $Module.ToLower() -split "," | ForEach-Object { $_.Trim() }
}

Write-Host "Modules: $($modulesToRun -join ', ')" -ForegroundColor Yellow

foreach ($m in $modulesToRun) {
    switch ($m) {
        "auth"         { Create-AuthModule }
        "contracts"    { Create-ContractsModule }
        "friend"       { Create-FriendModule }
        "feed"         { Create-FeedModule }
        "notification" { Create-NotificationModule }
        "profile"      { Create-ProfileModule }
        "settings"     { Create-SettingsModule }
        "reaction"     { Create-ReactionModule }
        "diary"        { Create-DiaryModule }
        "space"        { Create-SpaceModule }
        "widget"       { Create-WidgetModule }
        "chat"         { Create-ChatModule }
        default { Write-Host "Unknown: $m" -ForegroundColor Red }
    }
}

Write-Host "`nDone!" -ForegroundColor Cyan
