function New-RTGEntraIDCloudSyncMigrationInboundRule {
    <#
    .SYNOPSIS
    Creates a new inbound ADSync rule for Connect Sync to Cloud Sync Migration pilot.

    .DESCRIPTION
    This function creates a new inbound ADSync rule for Connect Sync to Cloud Sync Migration pilot using the provided parameters, including the ADSync connector, precedence, connected system object type, comparison value, and comparison value type.

    .PARAMETER ADSyncConnector
    The ADSync connector for the specified domain.

    .PARAMETER Precedence
    The precedence of the sync rule.

    .PARAMETER ConnectedSystemObjectType
    The source object type. Valid values are 'user', 'group', and 'contact'.

    .PARAMETER ScopingFilterComparisonValue
    The Scoping Filter comparison value for the scope condition.

    .PARAMETER ScopingFilterComparisonValueType
    The type of the Scoping Filter comparison value. Valid values are 'OU' and 'Group'.

    .EXAMPLE
    $Params = @{
        ADSyncConnector = Get-ADSyncConnector -Name "LittlestBears.com"
        Precedence = 50
        ConnectedSystemObjectType = "user"
        ScopingFilterComparisonValue = "CN=Cloud_Synced_Objects,OU=Connect Synced Groups,OU=Groups,OU=Tier 2,OU=Demo Organization,DC=LittlestBears,DC=com"
        ScopingFilterComparisonValueType = "Group"
    }

    New-RTGEntraIDCloudSyncMigrationInboundRule @Params

    This example creates a new inbound ADSync rule for Connect Sync to Cloud Sync Migration pilot with the specified parameters.

    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)] [Microsoft.IdentityManagement.PowerShell.ObjectModel.Connector] $ADSyncConnector,
        [Parameter(Mandatory)]
        [ValidateRange(1,1000)]
        [int] $Precedence,
        [Parameter(Mandatory)]
        [ValidateSet("Contact","Group","User")]
        [string] $ConnectedSystemObjectType,
        [Parameter(Mandatory)] [string] $ScopingFilterComparisonValue,
        [Parameter(Mandatory)]
        [ValidateSet("OU","Group")] [string] $ScopingFilterComparisonValueType
    )

    switch ( $ConnectedSystemObjectType ) {
        "user" {
            $MetaverseObjectType = "person"
        }
        "group" {
            $MetaverseObjectType = "group"
        }
        "contact" {
            $MetaverseObjectType = "person"
        }
        Default {
            Write-Error "ConnectedSystemObjectType must be user, group, or contact"
            break
        }
    }

    $Params = @{
        ADSyncConnector = $ADSyncConnector
        Direction = "Inbound"
        Name = "Custom - In from AD -  Exclude Exclude Microsoft Cloud Sync Pilot $ConnectedSystemObjectType objects from Microsoft Connect Sync"
        Description = "Used when piloting Microsoft Connect Sync to Microsoft Cloud Sync migration pilot"
        ConnectedSystemObjectType = $ConnectedSystemObjectType
        MetaverseObjectType = $MetaverseObjectType
        Precedence = $Precedence
        LinkType = "Join"
    }

    Write-Verbose "Creating Inbound ADSync rule with the following parameters:"
    Write-Verbose "Name: $($Params.Name)"
    Write-Verbose "Description: $($Params.Description)"
    Write-Verbose "Direction: $($Params.Direction)"
    Write-Verbose "Precedence: $($Params.Precedence)"
    Write-Verbose "SourceObjectType: $($Params.ConnectedSystemObjectType)"
    Write-Verbose "TargetObjectType: $($Params.MetaverseObjectType)"
    Write-Verbose "Connector: $($ADSyncConnector.Identifier)"
    Write-Verbose "LinkType: $($Params.LinkType)"

    $ADSyncCloudMigrationRule = New-RTGEntraIDCloudSyncMigrationRule @Params

    Switch ( $ScopingFilterComparisonValueType ) {
        "OU" {
            $ComparisonOperator = [Microsoft.IdentityManagement.PowerShell.ObjectModel.ComparisonOperator]::ENDSWITH
            $Attribute = "dn"
        }
        "Group" {
            $ComparisonOperator = [Microsoft.IdentityManagement.PowerShell.ObjectModel.ComparisonOperator]::ISMEMBEROF
            $Attribute = ""
        }
        Default {
            Write-Error "ComparisonValueType must be Group or OU"
            break
        }
    }

    $Params = @{
        ADSyncCloudMigrationRule = $ADSyncCloudMigrationRule
        Attribute = $Attribute
        ComparisonValue = $ScopingFilterComparisonValue
        ComparisonOperator = $ComparisonOperator
        }

    Write-Verbose "Creating scope condition with the following parameters:"
    Write-Verbose "Attribute: $($Params.Attribute)"
    Write-Verbose "ComparisonValue: $($Params.ComparisonValue)"
    Write-Verbose "ComparisonOperator: $($Params.ComparisonOperator)"

    Add-RTGEntraIDCloudSyncMigrationScopeCondition @Params

    $Params = @{
        ADSyncCloudMigrationRule = $ADSyncCloudMigrationRule
        FlowType = "Constant"
        TargetAttribute = "cloudNoFlow"
        Source = "True"
        ApplyOnce = $false
        MergeType = "Update"
    }

    Write-Verbose "Creating attribute flow mapping with the following parameters:"
    Write-Verbose "FlowType: $($Params.FlowType)"
    Write-Verbose "TargetAttribute: $($Params.TargetAttribute)"
    Write-Verbose "Source: $($Params.Source)"
    Write-Verbose "ApplyOnce: $($Params.ApplyOnce)"
    Write-Verbose "MergeType: $($Params.MergeType)"

    Add-RTGEntraIDCloudSyncMigrationAttributeFlowMapping @Params

    Write-Verbose "Adding Inbound ADSync rule to synchronization rule with the following parameters:"
    Write-Verbose "SynchronizationRule: $($ADSyncCloudMigrationRule.Name)"

    if ($PSCmdlet.ShouldProcess($ADSyncCloudMigrationRule.Name, "Add ADSync rule")) {
        Add-ADSyncRule -SynchronizationRule $ADSyncCloudMigrationRule
    }
}