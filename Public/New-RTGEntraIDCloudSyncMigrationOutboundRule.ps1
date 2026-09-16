function New-RTGEntraIDCloudSyncMigrationOutboundRule {
    <#
    .SYNOPSIS
    Creates a new outbound ADSync rule for Connect Sync to Cloud Sync Migration pilot.

    .DESCRIPTION
    This function creates a new outbound ADSync rule for Connect Sync to Cloud Sync Migration pilot using the provided parameters, including the ADSync connector, precedence, connected system object type, metaverse object type, scoping filter attribute name, scoping filter comparison value, and scoping filter comparison operator.

    .PARAMETER ADSyncConnector
    The ADSync connector for the specified domain.

    .PARAMETER Precedence
    The precedence of the sync rule. Valid values are between 1 and 1000.

    .PARAMETER ConnectedSystemObjectType
    The source object type. Valid values are 'Contact', 'Group', and 'User'.

    .PARAMETER MetaverseObjectType
    The target object type. Valid values are 'Group' and 'Person'.

    .PARAMETER ScopingFilterAttributeName
    The attribute name for the scoping filter.

    .PARAMETER ScopingFilterComparisonValue
    The comparison value for the scoping filter.

    .PARAMETER ScopingFilterComparisonOperator
    The comparison operator for the scoping filter.

    .EXAMPLE
    $Params = @{
        ADSyncConnector = Get-ADSyncConnector | Where-Object { $_.SubType -eq 'Windows Azure Active Directory (Microsoft)' }
        Precedence = 35
        ConnectedSystemObjectType = "user"
        MetaverseObjectType = "person"
        ScopingFilterAttributeName = "cloudNoFlow"
        ScopingFilterComparisonValue = "True"
        ScopingFilterComparisonOperator = [Microsoft.IdentityManagement.PowerShell.ObjectModel.ComparisonOperator]::EQUAL
    }

    New-RTGEntraIDCloudSyncMigrationOutboundRule @Params

    This example creates a new outbound ADSync rule for Cloud Migration with the specified parameters.

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
        [Parameter(Mandatory)]
        [ValidateSet("Group","Person")]
        [string] $MetaverseObjectType,
        [Parameter(Mandatory)] [string] $ScopingFilterAttributeName,
        [Parameter(Mandatory)] [string] $ScopingFilterComparisonValue,
        [Parameter(Mandatory)] [Microsoft.IdentityManagement.PowerShell.ObjectModel.ComparisonOperator] $ScopingFilterComparisonOperator
    )


    $Params = @{
        ADSyncConnector = $ADSyncConnector
        Direction = "Outbound"
        Name = "Custom - Out to AAD -  Exclude Microsoft Cloud Sync Pilot $ConnectedSystemObjectType objects from Microsoft Connect Sync"
        Description = "Used when piloting Microsoft Connect Sync to Microsoft Cloud Sync migration pilot"
        ConnectedSystemObjectType = $MetaverseObjectType
        MetaverseObjectType = $ConnectedSystemObjectType
        Precedence = $Precedence
        LinkType = "JoinNoFlow"
    }

    Write-Verbose "Creating Outbound ADSync rule with the following parameters:"
    Write-Verbose "Name: $($Params.Name)"
    Write-Verbose "Description: $($Params.Description)"
    Write-Verbose "Direction: $($Params.Direction)"
    Write-Verbose "Precedence: $($Params.Precedence)"
    Write-Verbose "SourceObjectType: $($Params.ConnectedSystemObjectType)"
    Write-Verbose "TargetObjectType: $($Params.MetaverseObjectType)"
    Write-Verbose "Connector: $($ADSyncConnector.Identifier)"
    Write-Verbose "LinkType: $($Params.LinkType)"

    $ADSyncCloudMigrationRule = New-RTGEntraIDCloudSyncMigrationRule @Params

    $Params = @{
        ADSyncCloudMigrationRule = $ADSyncCloudMigrationRule
        Attribute = $ScopingFilterAttributeName
        ComparisonValue = $ScopingFilterComparisonValue
        ComparisonOperator = $ScopingFilterComparisonOperator
    }

    Write-Verbose "Creating scope condition with the following parameters:"
    Write-Verbose "Attribute: $($Params.Attribute)"
    Write-Verbose "ComparisonValue: $($Params.ComparisonValue)"
    Write-Verbose "ComparisonOperator: $($Params.ComparisonOperator)"

    Add-RTGEntraIDCloudSyncMigrationScopeCondition @Params

    Write-Verbose "Adding Outbound ADSync rule to synchronization rule with the following parameters:"
    Write-Verbose "SynchronizationRule: $($ADSyncCloudMigrationRule.Name)"

    if ($PSCmdlet.ShouldProcess($ADSyncCloudMigrationRule.Name, "Add ADSync rule")) {
        Add-ADSyncRule -SynchronizationRule $ADSyncCloudMigrationRule
    }
}