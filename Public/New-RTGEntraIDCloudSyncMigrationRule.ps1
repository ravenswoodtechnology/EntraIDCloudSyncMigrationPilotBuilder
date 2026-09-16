function New-RTGEntraIDCloudSyncMigrationRule {
    <#
    .SYNOPSIS
    Creates a new ADSync rule with the specified parameters for Connect Sync to Cloud Sync Migration pilot.

    .DESCRIPTION
    This function creates a new ADSync rule for Connect Sync to Cloud Sync Migration pilot using the provided parameters, including the ADSync connector, direction, name, description, connected system object type, metaverse object type, link type, and precedence.

    .PARAMETER ADSyncConnector
    The ADSync connector for the specified domain.

    .PARAMETER Direction
    The direction of the sync rule. Valid values are 'Inbound' and 'Outbound'.

    .PARAMETER Name
    The name of the sync rule.

    .PARAMETER Description
    The description of the sync rule.

    .PARAMETER ConnectedSystemObjectType
    The source object type. Valid values are 'Contact', 'Group', and 'User'.

    .PARAMETER MetaverseObjectType
    The target object type. Valid values are 'Group' and 'Person'.

    .PARAMETER LinkType
    The link type for the sync rule.

    .PARAMETER Precedence
    The precedence of the sync rule. Valid values are between 1 and 1000.

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

    New-RTGEntraIDCloudSyncMigrationRule @Params

    This example creates a new ADSync rule with the specified parameters.

    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)] [Microsoft.IdentityManagement.PowerShell.ObjectModel.Connector] $ADSyncConnector,
        [Parameter(Mandatory)] [Microsoft.IdentityManagement.PowerShell.ObjectModel.SynchronizationRuleDirection] $Direction,
        [Parameter(Mandatory)] [string] $Name,
        [string] $Description,
        [Parameter(Mandatory)]
        [ValidateSet("Contact","Group","User","Person")]
        [string] $ConnectedSystemObjectType,
        [Parameter(Mandatory)]
        [ValidateSet("Contact","Group","User","Person")]
        [string] $MetaverseObjectType,
        [Parameter(Mandatory)]
        [Microsoft.IdentityManagement.PowerShell.ObjectModel.SyncRuleLinkType] $LinkType,
        [Parameter(Mandatory)]
        [ValidateRange(1,1000)]
        [int] $Precedence
    )

    # Define parameters for the new ADSync rule
    $Params = @{
        Name = $Name
        Description = $Description
        Direction = $Direction
        Precedence = $Precedence
        PrecedenceAfter = '00000000-0000-0000-0000-000000000000'
        PrecedenceBefore = '00000000-0000-0000-0000-000000000000'
        SourceObjectType = $ConnectedSystemObjectType
        TargetObjectType = $MetaverseObjectType
        Connector = $ADSyncConnector.Identifier
        LinkType = $LinkType
        SoftDeleteExpiryInterval = 0
        ImmutableTag =  ''
    }

    Write-Verbose "Creating ADSync rule with the following parameters:"
    Write-Verbose "Name: $Name"
    Write-Verbose "Description: $Description"
    Write-Verbose "Direction: $Direction"
    Write-Verbose "Precedence: $Precedence"
    Write-Verbose "SourceObjectType: $ConnectedSystemObjectType"
    Write-Verbose "TargetObjectType: $MetaverseObjectType"
    Write-Verbose "Connector: $($ADSyncConnector.Identifier)"
    Write-Verbose "LinkType: $LinkType"

    if ($PSCmdlet.ShouldProcess($Name, "Create ADSync rule")) {
        New-ADSyncRule @Params
    }
}