param (
    [Parameter(Mandatory=$true)]$who,
    [Parameter(Mandatory=$true)]$role,
    [Parameter(Mandatory=$false)]$tenantID = (Get-AzureADTenantDetail).ObjectId
)

Write-Host -ForegroundColor Magenta "----------------------------------------------------------"
Write-Host -ForegroundColor Magenta " Run this script separately for Active vs. Eligible roles "
Write-Host -ForegroundColor Magenta "----------------------------------------------------------"

# Selecting the user in question and obtaining the 'objectid'
$subjectid = Get-AzureADUser -SearchString $who | Out-GridView -PassThru
$subjectId = $subjectId.ObjectId

# Selecting the roles that meet the criteria of '$role'
$roles = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantId | where {$_.displayName -like "*$role*"} | Out-GridView -PassThru

# Selecting if the role will be permanent (active) or need to be activated (eligible)
$assignmentState = Read-Host "Is this an Active (A) or Eligible (E) assignment?"
if ($assignmentState -eq "A") {$assignmentState = "Active" ; $justification = "Reader roles do not require activation."}
elseif ($assignmentState -eq "E") {$assignmentState = "Eligible" ; $justification = $null} 

# Defining the schedule as: 'effective immediately with an infinite duration'
$schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
$schedule.Type = "Once"
$schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# Adding the aforementioned user to the aforementioned role/roles
foreach ($role in $roles) {
Write-Host -ForegroundColor Cyan $role.DisplayName
Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $tenantID -RoleDefinitionId $role.Id -SubjectId $subjectid -Type 'adminAdd' -AssignmentState $assignmentState -Schedule $schedule -Reason $justification }

# Clearing the previously used attributes
$subjectid = $null ; $roles = $null ; $role = $null ; $schedule = $null ; $assignmentState = $null ; $justification = $null