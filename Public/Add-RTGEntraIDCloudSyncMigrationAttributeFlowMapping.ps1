function Add-RTGEntraIDCloudSyncMigrationAttributeFlowMapping {
    <#
    .SYNOPSIS
    Adds a new attribute flow mapping for Connect Sync to Cloud Sync Migration pilot and adds it to the the supplied AD Sync rule.

    .DESCRIPTION
    This function adds a new attribute flow mapping and adds it to the the supplied AD Sync rule for Connect Sync to Cloud Sync Migration pilot using the provided parameters, including the ADSync rule, flow type, target attribute, source, apply once flag, and merge type.

    .PARAMETER ADSyncCloudMigrationRule
    The ADSync rule for the Connect Sync to Cloud Sync Migration pilot.

    .PARAMETER FlowType
    The flow type for the attribute mapping.

    .PARAMETER TargetAttribute
    The target attribute for the attribute mapping.

    .PARAMETER Source
    The source for the attribute mapping.

    .PARAMETER ApplyOnce
    A flag indicating whether the attribute mapping should be applied only once.

    .PARAMETER MergeType
    The merge type for the attribute mapping.

    .EXAMPLE
    $Params = @{
        ADSyncConnector = $ADSyncConnector
        Direction = "Inbound"
        Name = "Custom - In from AD -  Exclude Users from Microsoft Connect Sync"
        Description = "Used when piloting Microsoft Connect Sync to Microsoft Cloud Sync migration pilot"
        ConnectedSystemObjectType = "user"
        MetaverseObjectType = "person"
        Precedence = 15
        LinkType = "Join"
    }

    $ADSyncCloudMigrationRule = New-RTGEntraIDCloudSyncMigrationRule @Params

    $Params = @{
        ADSyncCloudMigrationRule = $ADSyncCloudMigrationRule
        FlowType = "Constant"
        TargetAttribute = "cloudNoFlow"
        Source = "True"
        ApplyOnce = $false
        MergeType = "Update"
    }

    Add-RTGEntraIDCloudSyncMigrationAttributeFlowMapping @Params

    This example creates a new ADSync rule and adds an attribute flow mapping for Connect Sync to Cloud Sync Migration pilot with the specified parameters.

    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [Microsoft.IdentityManagement.PowerShell.ObjectModel.SynchronizationRule] $ADSyncCloudMigrationRule,
        [Parameter(Mandatory)] [Microsoft.IdentityManagement.PowerShell.ObjectModel.AttributeMappingFlowType] $FlowType,
        [Parameter(Mandatory)] [string] $TargetAttribute,
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [bool] $ApplyOnce,
        [Microsoft.IdentityManagement.PowerShell.ObjectModel.AttributeValueMergeType] $MergeType
    )

    # Define parameters for adding the attribute flow mapping
    $Params = @{
        SynchronizationRule = $ADSyncCloudMigrationRule
        Source = $Source
        Destination = $TargetAttribute
        FlowType = $FlowType
        ExecuteOnce = $ApplyOnce
        ValueMergeType = $MergeType
    }

    Write-Verbose "Adding attribute flow mapping with the following parameters:"
    Write-Verbose "SynchronizationRule: $($ADSyncCloudMigrationRule.Name)"
    Write-Verbose "Source: $Source"
    Write-Verbose "Destination: $TargetAttribute"
    Write-Verbose "FlowType: $FlowType"
    Write-Verbose "ExecuteOnce: $ApplyOnce"
    Write-Verbose "ValueMergeType: $MergeType"

    # Add the attribute flow mapping with the defined parameters
    Add-ADSyncAttributeFlowMapping @Params
}