function Invoke-RTGEntraIDCloudSyncMigrationCompatibiltyCheck {

    <#
    .SYNOPSIS
        Checks the compatibility of the AD Sync Connector configurations with Cloud Sync Migration.

    .DESCRIPTION
        This function checks the AD Sync Connector configurations to ensure they are compatible with Cloud Sync Migration.
        It verifies the global settings parameters for the source anchor attribute, device writeback configuration, and sign-on method.

    .PARAMETER None
        This function does not take any parameters.

    .EXAMPLE
        Invoke-RTGEntraIDCloudSyncMigrationCompatibiltyCheck

        This example checks the compatibility of the AD Sync Connector configurations with Cloud Sync Migration.

    #>

    [CmdletBinding()] param ()

    $ADSyncCloudMigrationCompatibiltyCheck = $true
    $ADSyncGlobalSettings = Get-ADSyncGlobalSettings
    $ADSyncGlobalSettingsParameters = $ADSyncGlobalSettings.Parameters | Where-Object { $_.Name -in @("Microsoft.UserSignIn.SignOnMethod","Microsoft.DeviceWriteBack.Container","Microsoft.SynchronizationOption.AnchorAttribute","Microsoft.OptionalFeature.DeviceWriteUp") }

    ForEach ( $ADSyncGlobalSettingsParameter in $ADSyncGlobalSettingsParameters ) {
        Switch ( $ADSyncGlobalSettingsParameter.Name ) {
            "Microsoft.SynchronizationOption.AnchorAttribute" {
                if ($ADSyncGlobalSettingsParameter.Value -notin @("mS-DS-ConsistencyGuid","objectGuid") ) {
                    Write-Error "AD Sync Connector Source Anchor attribute is not set to mS-DS-ConsistencyGuid or objectGuid"
                    Write-Verbose "AD Sync Connector Source Anchor attribute is set to $($ADSyncGlobalSettingsParameter.Value)"
                    $ADSyncCloudMigrationCompatibiltyCheck = $false
                }
            }
            "Microsoft.DeviceWriteBack.Container" {
                if (-not ([string]::IsNullOrWhiteSpace($ADSyncGlobalSettingsParameter.Value)) ) {
                    Write-Error "AD Sync Connector is configured for Device Writeback"
                    $ADSyncCloudMigrationCompatibiltyCheck = $false}
            }
            "Microsoft.OptionalFeature.DeviceWriteUp" {
                if (-not ([string]::IsNullOrWhiteSpace($ADSyncGlobalSettingsParameter.Value)) ) {
                    Write-Warning "AD Sync Connector is configured for Device Synchronization"
                    $ADSyncCloudMigrationCompatibiltyCheck = $true
                }
            }
            "Microsoft.UserSignIn.SignOnMethod" {
                if ( $ADSyncGlobalSettingsParameter.Value -notin @("PasswordHashSync","Federation") ) {
                    Write-Error "AD Sync Connector SignOnMethod is not set to PasswordHashSync or Federation"
                    Write-Verbose "AD Sync Connector SignOnMethod is set to $($ADSyncGlobalSettingsParameter.Value)"
                    $ADSyncCloudMigrationCompatibiltyCheck = $false
                }
            }
        }
    }

    if ( $ADSyncCloudMigrationCompatibiltyCheck -eq $false ) {
        Write-Error "AD Sync Connector contains one or more incompatible configurations with Cloud Sync Migration"
        return
    }
    else {
        Write-Verbose "AD Sync Connector configurations are compatible with Cloud Sync Migration"
    }
}