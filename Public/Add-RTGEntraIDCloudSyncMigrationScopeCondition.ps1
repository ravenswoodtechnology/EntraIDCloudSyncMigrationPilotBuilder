function Add-RTGEntraIDCloudSyncMigrationScopeCondition {
    <#
    .SYNOPSIS
    Creates a new ADSync scope condition for Connect Sync to Cloud Sync Migration pilot and adds it to the the supplied AD Sync rule.

    .DESCRIPTION
    This function creates a new ADSync scope condition for Connect Sync to Cloud Sync Migration pilot using the provided parameters and adds it to to the supplied AD Sync rule, including the ADSync rule, attribute, comparison value, and comparison operator.

    .PARAMETER ADSyncCloudMigrationRule
    The ADSync rule for the Connect Sync to Cloud Sync Migration pilot.

    .PARAMETER ComparisonValue
    The comparison value for the scope condition.

    .PARAMETER Attribute
    The attribute for the scope condition. Default is an empty string.

    .PARAMETER ComparisonOperator
    The comparison operator for the scope condition.

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
    $ComparisonValue = "CN=Cloud_Synced_Objects,OU=Connect Synced Groups,OU=Groups,OU=Tier 2,OU=Demo Organization,DC=LittlestBears,DC=com"
    $ComparisonOperator = [Microsoft.IdentityManagement.PowerShell.ObjectModel.ComparisonOperator]::ISMEMBEROF

    Add-RTGEntraIDCloudSyncMigrationScopeCondition -ADSyncCloudMigrationRule $ADSyncCloudMigrationRule -ComparisonValue $ComparisonValue -ComparisonOperator $ComparisonOperator

    This example creates a new ADSync scope condition for Connect Sync to Cloud Sync Migration pilot with the specified parameters and adds it to the ADSyncCloudMigrationRule.

    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [Microsoft.IdentityManagement.PowerShell.ObjectModel.SynchronizationRule] $ADSyncCloudMigrationRule,
        [Parameter(Mandatory)] [string] $ComparisonValue,
        [string] $Attribute = "",
        [Parameter(Mandatory)] [Microsoft.IdentityManagement.PowerShell.ObjectModel.ComparisonOperator] $ComparisonOperator
    )

    # Create a new scope condition with the defined attribute, comparison value, and comparison operator
    $ScopeCondition = [Microsoft.IdentityManagement.PowerShell.ObjectModel.ScopeCondition]::new($Attribute, $ComparisonValue, $ComparisonOperator)

    Write-Verbose "Creating scope condition with the following parameters:"
    Write-Verbose "Attribute: $Attribute"
    Write-Verbose "ComparisonValue: $ComparisonValue"
    Write-Verbose "ComparisonOperator: $ComparisonOperator"

    # Define parameters for adding the scope condition group
    $Params = @{
        SynchronizationRule = $ADSyncCloudMigrationRule
        ScopeConditions = @($ScopeCondition)
    }

    Write-Verbose "Adding scope condition group with the following parameters:"
    Write-Verbose "SynchronizationRule: $($ADSyncCloudMigrationRule.Name)"
    Write-Verbose "ScopeConditions: $($ScopeConditions.Count)"

    # Add the scope condition group with the defined parameters
    Add-ADSyncScopeConditionGroup @Params
}