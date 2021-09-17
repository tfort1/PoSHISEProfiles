##########################################################################
# Tier0 Script is for high-level, highly-protected roles.  Roles will 
# be configured for 1 (now 2) hour max duration, no standing access, and will
# NOT require MFA upon activation.
#
# Current Roles:
# Conditional Access Administrator
# Global Administrator
# Privileged Role Administrator
##########################################################################


param (
    [Parameter(Mandatory=$true)]$role,
    [Parameter(Mandatory=$false)]$tenantID = (Get-AzureADTenantDetail).ObjectId
)
$roles = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantId | Where-Object {$_.displayName -like "*$role*"} | Out-GridView -PassThru

if (!$role) {Write-Host -ForegroundColor Red "Role not defined" ; break}

# Settings
$userEligibleSettings_notifications = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$userEligibleSettings_notifications.RuleIdentifier = "NotificationRule"
$userEligibleSettings_notifications.Setting = '{"policies":[{"deliveryMechanism":"Email","setting":[{"recipientType":2,"notificationLevel":2,"isDefaultReceiverEnabled":true,"customReceivers":null},{"recipientType":0,"notificationLevel":2,"isDefaultReceiverEnabled":true,"customReceivers":null},{"recipientType":1,"notificationLevel":2,"isDefaultReceiverEnabled":true,"customReceivers":null}]}]}'

$userMemberSettings_activationJustification = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$userMemberSettings_activationJustification.RuleIdentifier = "JustificationRule"
$userMemberSettings_activationJustification.Setting = '{"required":true}'
$userMemberSettings_activationDuration = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$userMemberSettings_activationDuration.RuleIdentifier = "ExpirationRule"
#$userMemberSettings_activationDuration.Setting = '{"maximumGrantPeriod":"1:00:00","maximumGrantPeriodInMinutes":60,"permanentAssignment":true}' # 1 hour
$userMemberSettings_activationDuration.Setting = '{"maximumGrantPeriod":"2:00:00","maximumGrantPeriodInMinutes":120,"permanentAssignment":true}' # 2 hours
$userMemberSettings_activationMFARequired = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$userMemberSettings_activationMFARequired.RuleIdentifier = "MfaRule"
#$userMemberSettings_activationMFARequired.Setting = '{"mfaRequired":true}'
$userMemberSettings_activationMFARequired.Setting = '{"mfaRequired":false}'
$userMemberSettings_activationApprovers = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$userMemberSettings_activationApprovers.RuleIdentifier = "ApprovalRule"
# $userMemberSettings_activationApprovers.Setting = '{"Enabled":true,"IsCriteriaSupported":true,"Approvers":[{"Id":"6f60e502-4002-4bdc-bd08-29f9476751ff","Type":"Group","DisplayName":"pim approvers","PrincipalName":""}],"BusinessFlowId":"b58d7b70-dda0-4e03-8262-8198aabf6565","HasNotificationPolicy":true}' # enabled
$userMemberSettings_activationApprovers.Setting = '{"Enabled":false,"IsCriteriaSupported":true,"Approvers":[{"Id":"6f60e502-4002-4bdc-bd08-29f9476751ff","Type":"Group","DisplayName":"pim approvers","PrincipalName":""}],"BusinessFlowId":"b58d7b70-dda0-4e03-8262-8198aabf6565","HasNotificationPolicy":true}' # disabled
$userMemberSettings_acitvationTicketInformation = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$userMemberSettings_acitvationTicketInformation.RuleIdentifier = "TicketingRule"
$userMemberSettings_acitvationTicketInformation.Setting = '{"ticketingRequired":false}'
$userMemberSettings_activationAcrsRule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$userMemberSettings_activationAcrsRule.RuleIdentifier = "AcrsRule"
$userMemberSettings_activationAcrsRule.Setting = '{"acrsRequired":false,"acrs":null}'
$userMemberSettings_notifications = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$userMemberSettings_notifications.RuleIdentifier = "NotificationRule"
$userMemberSettings_notifications.Setting = '{"policies":[{"deliveryMechanism":"email","setting":[{"customreceivers":["PIM@jsfjpo.mail.onmicrosoft.com"],"isdefaultreceiverenabled":true,"notificationlevel":2,"recipienttype":2},{"customreceivers":null,"isdefaultreceiverenabled":true,"notificationlevel":2,"recipienttype":0},{"customreceivers":null,"isdefaultreceiverenabled":true,"notificationlevel":2,"recipienttype":1}]}]}'

$adminMemberSettings_assignmentDuration = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$adminMemberSettings_assignmentDuration.RuleIdentifier = "ExpirationRule"
# $adminMemberSettings_assignmentDuration.Setting = '{"maximumGrantPeriod":"15.00:00:00","maximumGrantPeriodInMinutes":21600,"permanentAssignment":false}' # 15 days
$adminMemberSettings_assignmentDuration.Setting = '{"maximumGrantPeriod":"365.00:00:00","maximumGrantPeriodInMinutes":525600,"permanentAssignment":true}' # forever
$adminMemberSettings_assignmentMFARequired = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$adminMemberSettings_assignmentMFARequired.RuleIdentifier = "MfaRule"
$adminMemberSettings_assignmentMFARequired.Setting = '{"mfaRequired":false}'
$adminMemberSettings_assignmentJustification = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$adminMemberSettings_assignmentJustification.RuleIdentifier = "JustificationRule"
$adminMemberSettings_assignmentJustification.Setting = '{"required":true}'
$adminMemberSettings_notifications = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$adminMemberSettings_notifications.RuleIdentifier = "NotificationRule"
$adminMemberSettings_notifications.Setting = '{"policies":[{"deliveryMechanism":"email","setting":[{"customreceivers":["PIM@jsfjpo.mail.onmicrosoft.com"],"isdefaultreceiverenabled":true,"notificationlevel":2,"recipienttype":2},{"customreceivers":null,"isdefaultreceiverenabled":true,"notificationlevel":2,"recipienttype":0},{"customreceivers":["PIM@jsfjpo.mail.onmicrosoft.com"],"isdefaultreceiverenabled":true,"notificationlevel":2,"recipienttype":1}]}]}'

$adminEligibleSettings_eligibleDuration = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$adminEligibleSettings_eligibleDuration.RuleIdentifier = "ExpirationRule"
# $adminEligibleSettings_eligibleDuration.Setting = '{"permanentAssignment":true,"maximumGrantPeriodInMinutes":525600}' # forever
$adminEligibleSettings_eligibleDuration.Setting = '{"maximumGrantPeriod":"365.00:00:00","maximumGrantPeriodInMinutes":525600,"permanentAssignment":true}' # forever
$adminEligibleSettings_eligibleMFARequired = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$adminEligibleSettings_eligibleMFARequired.RuleIdentifier = "MfaRule"
$adminEligibleSettings_eligibleMFARequired.Setting = '{"mfaRequired":false}'
$adminEligibleSettings_notifications = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
$adminEligibleSettings_notifications.RuleIdentifier = "NotificationRule"
$adminEligibleSettings_notifications.Setting = '{"policies":[{"deliveryMechanism":"email","setting":[{"customreceivers":["PIM@jsfjpo.mail.onmicrosoft.com"],"isdefaultreceiverenabled":true,"notificationlevel":2,"recipienttype":2},{"customreceivers":null,"isdefaultreceiverenabled":true,"notificationlevel":2,"recipienttype":0},{"customreceivers":["PIM@jsfjpo.mail.onmicrosoft.com"],"isdefaultreceiverenabled":true,"notificationlevel":2,"recipienttype":1}]}]}'
#>

foreach ($role in $roles) {
$roleName = $role.DisplayName
$roleExternalId = $role.ExternalId
$roleID = (Get-AzureADMSPrivilegedRoleSetting -ProviderId 'aadRoles' -Filter "ResourceId eq '$tenantID' and RoleDefinitionId eq '$roleExternalId'").Id

Write-Host -ForegroundColor Cyan $role.DisplayName

Set-AzureADMSPrivilegedRoleSetting -ProviderId 'aadRoles' -Id $roleID -ResourceId $tenantID -RoleDefinitionId $roleExternalId -UserMemberSettings $userMemberSettings_notifications, $userMemberSettings_activationJustification,$userMemberSettings_activationDuration,$userMemberSettings_activationMFARequired,$userMemberSettings_activationApprovers,$userMemberSettings_acitvationTicketInformation,$userMemberSettings_activationAcrsRule -AdminMemberSettings $adminMemberSettings_notifications, $adminMemberSettings_assignmentDuration,$adminMemberSettings_assignmentMFARequired,$adminMemberSettings_assignmentJustification -AdminEligibleSettings $adminEligibleSettings_notifications, $adminEligibleSettings_eligibleDuration,$adminEligibleSettings_eligibleMFARequired -UserEligibleSettings $userEligibleSettings_notifications
}