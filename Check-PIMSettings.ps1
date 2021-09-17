param (
    [Parameter(Mandatory=$true)]$role,
    [Parameter(Mandatory=$false)]$tenantID = (Get-AzureADTenantDetail).ObjectId
)

$roles = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantId | where {$_.displayName -like "*$role*"} | Out-GridView -PassThru

foreach ($role in $roles) {
$roleName = $role.DisplayName
$roleExternalId = $role.ExternalId
$roleID = (Get-AzureADMSPrivilegedRoleSetting -ProviderId 'aadRoles' -Filter "ResourceId eq '$tenantID' and RoleDefinitionId eq '$roleExternalId'").Id

Write-Host -ForegroundColor Cyan $roleName
Get-AzureADMSPrivilegedRoleSetting -ProviderId aadRoles -Filter "ResourceId eq '$tenantID' and RoleDefinitionId eq '$roleExternalId'"
}
