function Invoke-RTGEntraIDCloudSyncMigrationPilotMigration {
    <#
    .SYNOPSIS
        Initiates the AD Sync Cloud Sync Migration pilot.

    .DESCRIPTION
        This function initiates the AD Sync Cloud Sync Migration pilot by validating the compatibility of the AD Sync Connector, ensuring the connector is not busy,
        stopping the sync cycle, disabling the scheduler, and calculating the precedences for the migration rules.

    .PARAMETER ADSyncInboundConnectorName
        The name of the inbound AD Sync connector.

    .PARAMETER InboundScopingFilterComparisonValue
        The comparison value for the inbound scoping filter.

    .PARAMETER InboundScopingFilterComparisonValueType
        The type of the comparison value for the inbound scoping filter.

    .EXAMPLE
        $Params = @{
            ADSyncInboundConnectorName = "LittlestBears.com"
            InboundScopingFilterComparisonValue = "CN=Cloud_Synced_Objects,OU=Connect Synced Groups,OU=Groups,OU=Tier 2,OU=Demo Organization,DC=LittlestBears,DC=com"
            InboundScopingFilterComparisonValueType = "Group"
        }
        Invoke-RTGEntraIDCloudSyncMigrationPilotMigration @Params

        This example initiates the AD Sync Cloud Sync Migration pilot with the specified inbound scoping filter comparison value and type.

    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string] $ADSyncInboundConnectorName,
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [ValidatePattern("^(CN\=.+,|OU\=.+,|DC\=.+,)")]
        [string] $InboundScopingFilterComparisonValue,
        [Parameter(Mandatory)]
        [ValidateSet("OU","Group")]
        [string] $InboundScopingFilterComparisonValueType
    )

    Write-Verbose "Operation: Validating that ADSync Connector is compatible with Cloud Sync Migration"
    Invoke-RTGEntraIDCloudSyncMigrationCompatibiltyCheck

    Write-Verbose "Operation: Validating that ADSync Connector run status is not busy"

    $ADSyncConnectorRunStatus = Get-ADSyncConnectorRunStatus

    while ( $ADSyncConnectorRunStatus.RunState -eq "Busy" ) {
        Write-Verbose "ConnectorName: $($ADSyncConnectorRunStatus.ConnectorName)"
        Write-Verbose "RunState: $($ADSyncConnectorRunStatus.RunState)"
        Write-Verbose "Operation: Sleeping 3 min before next run status busy check."
        Start-Sleep -Seconds 180
        Write-Verbose "Operation: Validating that ADSync Connector run status is not busy"
        $ADSyncConnectorRunStatus = Get-ADSyncConnectorRunStatus
    }

    Write-Verbose "Operation: Stopping ADSync Sync Cycle"
    Stop-ADSyncSyncCycle

    Write-Verbose "Operation: Disabling ADSync Scheduler Sync Cycle"
    Set-ADSyncScheduler -SyncCycleEnabled $false

    Write-Verbose "Operation: Validating ADSync Scheduler Sync Cycle has been disabled"
    $ADSyncSchedulerSyncCycleStatus = Get-ADSyncScheduler
    if ($ADSyncSchedulerSyncCycleStatus.SyncCycleEnabled -eq $true) {
        Write-Error "ADSync Scheduler Sync Cycle has not been disabled."
        return
    }
    Write-Verbose "Operation: Retrieving ADSync rules precedences"
    [Array] $ADSyncRulesPrecedences = $(Get-ADSyncRule).Precedence
    Write-Verbose "Operation: Sorting ADSync rules precedences"
    [Array]::Sort($ADSyncRulesPrecedences)
    $PrecedenceLowerBound = $ADSyncRulesPrecedences[0]
    Write-Verbose "Precedence lower bound: $PrecedenceLowerBound"

    [Array] $InboundPredecences = @()
    [Array] $OutboundPredecences = @()
    for ( $i = 0; $i -lt 6; $i++ ) {
    $PrecedenceLowerBound -= 5
    Write-Verbose "Current precedence lower bound: $PrecedenceLowerBound"
    switch ($PrecedenceLowerBound) {
        { ( $PrecedenceLowerBound % 10) -eq 0 } {
            $InboundPredecences += $PrecedenceLowerBound
            Write-Verbose "Added to inbound precedences: $PrecedenceLowerBound"
        }
        { ( ( $PrecedenceLowerBound % 5) -eq 0 ) -and ( ($PrecedenceLowerBound % 10) -ne 0 ) } {
            $OutboundPredecences += $PrecedenceLowerBound
            Write-Verbose "Added to outbound precedences: $PrecedenceLowerBound"
        }
    }
}

    if ( ($InboundPredecences.Count -lt 3 ) -or ($OutboundPredecences.Count -lt 3) ) {
        Write-Error "Predecences not calculated."
        return
    }

    Write-Verbose "Inbound precedences: $($InboundPredecences -join ', ')"
    Write-Verbose "Outbound precedences: $($OutboundPredecences -join ', ')"

    $Param = @{
        InboundADSyncConnector = Get-ADSyncConnector -Name $ADSyncInboundConnectorName
        InboundPrecedences = $InboundPredecences
        InboundScopingFilterComparisonValue = $InboundScopingFilterComparisonValue
        InboundScopingFilterComparisonValueType = $InboundScopingFilterComparisonValueType
        OutboundADSyncConnector = Get-ADSyncConnector | Where-Object { $_.SubType -eq 'Windows Azure Active Directory (Microsoft)' }
        OutboundPrecedences = $OutboundPredecences
    }

    Add-RTGEntraIDCloudSyncMigrationRule @Param

}