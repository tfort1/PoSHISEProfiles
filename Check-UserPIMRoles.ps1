Param(
    [parameter(mandatory=$true)]$Who
)

# Pre-filling other variables
$tenantID = (Get-AzureADCurrentSessionInfo).TenantId.Guid
$subjectid = Get-AzureADUser -SearchString $who | Out-GridView -PassThru
$subjectId = $subjectId.ObjectId

<# Connecting to AAD
$UserName = $env:username+'@'+$env:USERDNSDOMAIN.ToLower()
Connect-AzureAD -AzureEnvironmentName AzureUSGovernment -AccountId $UserName
#>

# Summarizing currently active roles and displaying in a table
foreach ($subject in $subjectId) {
    $report = @()
    $Roles = Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $tenantID -Filter "subjectId eq '$subject'"# | Where-Object {$_.AssignmentState -eq "Active"}
    $user = (Get-AzureADUser -ObjectId $subject).DisplayName

    Write-Host -ForegroundColor Cyan "`nCurrent roles and expiration for: " -NoNewline ; Write-Host -ForegroundColor Green $user
    foreach ($role in $Roles) {
        $inpObj = New-Object PSObject
        $inpObj | Add-Member -MemberType NoteProperty -Name "Role Name" -Value (Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantId -Id $role.RoleDefinitionId).DisplayName
        $inpObj | Add-Member -MemberType NoteProperty -Name "Assignment State" -Value $role.AssignmentState
        if (!$role.EndDateTime) {$expiration = "Permanent assignment"}
        else {$expiration = $role.EndDateTime.ToLocalTime()}
        $inpObj | Add-Member -MemberType NoteProperty -Name "Role Expiration" -Value $expiration
        $report += $inpObj
    }
    $report | Sort-Object "Display Name","Assignment State" | Format-Table -AutoSize
}
