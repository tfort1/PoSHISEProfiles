# Testing to see if Azure AD Preview (need AAD Preview) module is installed
$checkModuleInstalled = Get-Module -Name AzureADPreview -ListAvailable
if (!$checkModuleInstalled) {Write-Host -Foregroundcolor Red "Module not installed" ; break}
else {Import-Module AzureADPreview}

# Connecting to AAD
<#
$UserName = $env:username+'@'+$env:USERDNSDOMAIN.ToLower()
Connect-AzureAD -AzureEnvironmentName AzureUSGovernment -AccountId $UserName
AAD
#>


# Automatically grabbing ObjectId and TenantID of current user
$tenantID = (Get-AzureADCurrentSessionInfo).TenantId.Guid
$subjectID = (Get-AzureADUser -SearchString (Get-AzureADCurrentSessionInfo).Account.Id.Split("@")[0]).ObjectId

# If latency causes either $tenantId or $subjectId to fail, reverting to manual entry
if (!$tenantID) {$tenantId = Read-Host "What is the tenant ID? (can be found at https://portal.azure.us/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Overview)"}
if (!$subjectID) {$subjectID = Read-Host "Who is using this? (username@jsfjpo.onmicrosoft.com)" ; $subjectID = (Get-AzureADUser -SearchString $subject).ObjectId}

# Changing window title
$oldUI = $Host.UI.RawUI.WindowTitle
$Host.UI.RawUI.WindowTitle += " Activing PIM Roles"

# Creating schedule to start "now" and end in 10 hours (max duation for tier1 roles)
$tier1Schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
$tier1Schedule.Type = "Once"
$tier1Schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$tier1Schedule.EndDateTime = (Get-Date).AddHours(10).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# Creating schedule to start "now" and end in 2 hour (max duration for tier0 roles)
$tier0Schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
$tier0Schedule.Type = "Once"
$tier0Schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$tier0Schedule.EndDateTime = (Get-Date).AddHours(2).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# Gathering all assigned roles
$myRoles = Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $tenantID -Filter "subjectId eq '$subjectID'"

# Presenting user to pick role for assignment
$roles = $myRoles | Where-Object {$_.AssignmentState -eq "Eligible"} | ForEach-Object { Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantId -Id $_.RoleDefinitionId } | Select-Object DisplayName,Id | Sort-Object DisplayName | Out-GridView -PassThru

$justification = Read-Host "What is the justification for the role activation?"

foreach ($role in $roles) {
    $roleID = $role.Id
    $roleName = $role.DisplayName
    if ($roleName -eq "Global Administrator") {$schedule = $tier0Schedule}
    elseif ($roleName -eq "Conditional Access Administrator") {$schedule = $tier0Schedule}
    elseif ($roleName -eq "Privileged Role Administrator") {$schedule = $tier0Schedule}
    else {$schedule = $tier1Schedule}
    
    Write-Host -ForegroundColor Cyan $roleName

    # Activating chosen roles (line 42)
    Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId aadRoles -ResourceId $tenantID -RoleDefinitionId $roleID -SubjectId $subjectID -Type 'UserAdd' -AssignmentState 'Active' -Reason $justification -Schedule $schedule -ErrorAction SilentlyContinue
}

Write-Host "Gathing a list of current roles..."
sleep 9

# Summarizing currently active roles and displaying in a table
$report = @()
$activeRoles = Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $tenantID -Filter "subjectId eq '$subjectID'" | Where-Object {$_.AssignmentState -eq "Active"}
$user = (Get-AzureADUser -ObjectId $subjectID).DisplayName

Write-Host -ForegroundColor Cyan "`nCurrent roles and expiration for: " -NoNewline ; Write-Host -ForegroundColor Green $user
foreach ($role in $activeRoles) {
    $inpObj = New-Object PSObject
    $inpObj | Add-Member -MemberType NoteProperty -Name "Role Name" -Value (Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantId -Id $role.RoleDefinitionId).DisplayName
    if (!$role.EndDateTime) {$expiration = "Permanent assignment"}
    else {$expiration = $role.EndDateTime.ToLocalTime()}
    $inpObj | Add-Member -MemberType NoteProperty -Name "Role Expiration" -Value $expiration
    $report += $inpObj
}
$report | Sort-Object "Role Expiration","Display Name" | Format-Table -AutoSize
$Host.UI.RawUI.WindowTitle = $oldUI

<# Disconnecting from AAD
Disconnect-AzureAD -Confirm:$false
#>
