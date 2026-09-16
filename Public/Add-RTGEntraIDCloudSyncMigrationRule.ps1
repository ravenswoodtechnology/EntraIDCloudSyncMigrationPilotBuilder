function Add-RTGEntraIDCloudSyncMigrationRule {
    <#
    .SYNOPSIS
        Adds the AD Sync Connect Sync to Cloud Sync Migration pilot Rules for both inbound and outbound connectors.

    .DESCRIPTION
        This function creates AD Sync Connect Sync to Cloud Sync Migration pilot Rules for both inbound and outbound connectors based on the provided parameters.
        It processes the inbound and outbound precedences and creates the corresponding rules using the specified connectors and scoping filter values.

    .PARAMETER InboundADSyncConnector
        The inbound AD Sync connector object.

    .PARAMETER InboundPrecedences
        An array of precedences for the inbound rules.

    .PARAMETER InboundScopingFilterComparisonValue
        The comparison value for the inbound scoping filter.

    .PARAMETER InboundScopingFilterComparisonValueType
        The type of the comparison value for the inbound scoping filter.

    .PARAMETER OutboundADSyncConnector
        The outbound AD Sync connector object.

    .PARAMETER OutboundPrecedences
        An array of precedences for the outbound rules.

    .EXAMPLE
        $Param = @{
            InboundADSyncConnector = Get-ADSyncConnector -Name "LittlestBears.com"
            InboundPrecedences = @(20,30,40)
            InboundScopingFilterComparisonValue = "CN=Cloud_Synced_Objects,OU=Connect Synced Groups,OU=Groups,OU=Tier 2,OU=Demo Organization,DC=LittlestBears,DC=com"
            InboundScopingFilterComparisonValueType = "group"
            OutboundADSyncConnector = Get-ADSyncConnector | Where-Object { $_.SubType -eq 'Windows Azure Active Directory (Microsoft)' }
            OutboundPrecedences = @(25,35,45)
        }

        Add-RTGEntraIDCloudSyncMigrationRule @Param
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.IdentityManagement.PowerShell.ObjectModel.Connector] $InboundADSyncConnector,
        [Parameter(Mandatory = $true)]
        [Array] $InboundPrecedences,
        [Parameter(Mandatory = $true)]
        [string] $InboundScopingFilterComparisonValue,
        [Parameter(Mandatory = $true)]
        [string] $InboundScopingFilterComparisonValueType,
        [Microsoft.IdentityManagement.PowerShell.ObjectModel.Connector] $OutboundADSyncConnector,
        [Parameter(Mandatory = $true)]
        [Array] $OutboundPrecedences
    )

    $i = 0
    $InboundObjectTypes = @("user","contact","group")

    foreach ( $InboundPrecedence in $InboundPrecedences) {

        $Params = @{
            ADSyncConnector = $InboundADSyncConnector
            Precedence = $InboundPrecedence
            ConnectedSystemObjectType = $InboundObjectTypes[$i]
            ScopingFilterComparisonValue = $InboundScopingFilterComparisonValue
            ScopingFilterComparisonValueType = $InboundScopingFilterComparisonValueType
        }

        Write-Verbose "Creating Inbound ADSync rule with the following parameters:"
        Write-Verbose "ADSyncConnector: $($InboundADSyncConnector.Name)"
        Write-Verbose "Precedence: $InboundPrecedence"
        Write-Verbose "ConnectedSystemObjectType: $($InboundObjectTypes[$i])"
        Write-Verbose "ScopingFilterComparisonValue: $InboundScopingFilterComparisonValue"
        Write-Verbose "ScopingFilterComparisonValueType: $InboundScopingFilterComparisonValueType"

        # Create a new inbound AD Sync Cloud Migration rule with the specified parameters
        New-RTGEntraIDCloudSyncMigrationInboundRule @Params
        $i++
    }

    $i = 0
    $OutboundObjectTypes = @(
        [PSCustomObject]@{
            ConnectedSystemObjectType = "user";
            MetaverseObjectType = "person"
        },
        [PSCustomObject]@{
            ConnectedSystemObjectType = "contact";
            MetaverseObjectType = "person"
        },
        [PSCustomObject]@{
            ConnectedSystemObjectType = "group";
            MetaverseObjectType = "group"
        }
    )

    foreach ( $OutboundPrecedence in $OutboundPrecedences) {

        $Params = @{
            ADSyncConnector = $OutboundADSyncConnector
            Precedence = $OutboundPrecedence
            ConnectedSystemObjectType = $OutboundObjectTypes[$i].ConnectedSystemObjectType
            MetaverseObjectType = $OutboundObjectTypes[$i].MetaverseObjectType
            ScopingFilterAttributeName = "cloudNoFlow"
            ScopingFilterComparisonValue = "True"
            ScopingFilterComparisonOperator = [Microsoft.IdentityManagement.PowerShell.ObjectModel.ComparisonOperator]::EQUAL
        }

        Write-Verbose "Creating Outbound ADSync rule with the following parameters:"
        Write-Verbose "ADSyncConnector: $($OutboundADSyncConnector.Name)"
        Write-Verbose "Precedence: $OutboundPrecedence"
        Write-Verbose "ConnectedSystemObjectType: $($OutboundObjectTypes[$i].ConnectedSystemObjectType)"
        Write-Verbose "MetaverseObjectType: $($OutboundObjectTypes[$i].MetaverseObjectType)"
        Write-Verbose "ScopingFilterAttributeName: cloudNoFlow"
        Write-Verbose "ScopingFilterComparisonValue: True"
        Write-Verbose "ScopingFilterComparisonOperator: EQUAL"

        # Create a new outbound AD Sync Cloud Migration rule with the specified parameters
        New-RTGEntraIDCloudSyncMigrationOutboundRule @Params
        $i++
    }
}