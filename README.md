# RTGEntraIDCloudSyncMigrationPilotBuilder

A PowerShell module that automates the creation of the custom Microsoft Entra Connect Sync rules needed to run a **pilot migration from Microsoft Entra Connect Sync to Microsoft Entra Cloud Sync**, without disrupting synchronization for the rest of your organization.

It implements the "exclusion object" pattern documented by Microsoft for staged Cloud Sync pilots: objects that are in scope for the pilot are excluded from the on-premises Connect Sync outbound flow (via a `cloudNoFlow` attribute flow) so that Cloud Sync can take over synchronizing them to Microsoft Entra ID, while every other object continues to sync through Connect Sync as before.

> ⚠️ **This module modifies live Microsoft Entra Connect Sync configuration** (custom sync rules, scoping filters, and attribute flows) and can stop the sync scheduler. Review the [Before You Begin](#before-you-begin) section, test in a non-production environment first, and back up your Connect Sync server/configuration before running any of these commands against production.

## Requirements

- Windows PowerShell 5.1
- Must be run on (or with access to) a Microsoft Entra Connect Sync server
- The [`ADSync`](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-adsync) PowerShell module (installed automatically with Microsoft Entra Connect Sync)
- Permissions sufficient to read and modify the Connect Sync configuration (typically local Administrator on the sync server)

## Installation

Clone or download this repository, then import the module from the folder it was extracted to:

```powershell
Import-Module ".\RTGEntraIDCloudSyncMigrationPilotBuilder\RTGEntraIDCloudSyncMigrationPilotBuilder.psd1"
```

## Before You Begin

1. Confirm your Connect Sync configuration is compatible with Cloud Sync coexistence:
   ```powershell
   Invoke-RTGEntraIDCloudSyncMigrationCompatibiltyCheck -Verbose
   ```
   This checks that:
   - The source anchor is `mS-DS-ConsistencyGuid` or `objectGuid`
   - Device writeback is not configured
   - Sign-in is using Password Hash Sync or Federation
   - Warns (but does not block) if device synchronization is enabled
2. Identify (or create) the security group or organizational unit that will define which objects are in scope for the Cloud Sync pilot.
3. Have your Cloud Sync provisioning agent/connector already configured and scoped to the same group/OU in the Microsoft Entra admin center before running the migration, so cloud sync agent picks up the objects being excluded from Connect Sync.

## Quick Start

The simplest way to run the pilot migration end-to-end is with `Invoke-RTGEntraIDCloudSyncMigrationPilotMigration`, which performs the compatibility check, waits for the connector to be idle, pauses the sync scheduler, and creates all required inbound/outbound rules automatically:

```powershell
$Params = @{
    ADSyncInboundConnectorName              = "contoso.com"
    InboundScopingFilterComparisonValue     = "CN=Cloud_Sync_Pilot,OU=Groups,DC=contoso,DC=com"
    InboundScopingFilterComparisonValueType = "Group"
}

Invoke-RTGEntraIDCloudSyncMigrationPilotMigration @Params
```

This will:

1. Run the compatibility check and stop if the configuration is not eligible for Cloud Sync coexistence.
2. Wait until the Connect Sync connector is not busy, then stop the current sync cycle and disable the scheduler.
3. Calculate safe, unused rule precedence values.
4. Create the inbound rules (for `user`, `contact`, and `group` objects) that flag in-scope objects with a `cloudNoFlow` attribute.
5. Create the outbound rules that prevent Connect Sync from exporting those flagged objects to Microsoft Entra ID.

Once complete, re-enable the sync scheduler when you are ready to resume normal synchronization:

```powershell
Set-ADSyncScheduler -SyncCycleEnabled $true
```

## Functions

| Function | Description |
|---|---|
| `Invoke-RTGEntraIDCloudSyncMigrationCompatibiltyCheck` | Validates that the current Connect Sync configuration is compatible with a Cloud Sync coexistence pilot. |
| `Invoke-RTGEntraIDCloudSyncMigrationPilotMigration` | End-to-end orchestration: runs the compatibility check, pauses sync, calculates rule precedence, and creates all pilot rules. |
| `Add-RTGEntraIDCloudSyncMigrationRule` | Creates the full set of inbound and outbound pilot rules for a given inbound (AD) and outbound (Microsoft Entra ID) connector. |
| `New-RTGEntraIDCloudSyncMigrationInboundRule` | Creates a single inbound rule that scopes and flags objects (`cloudNoFlow`) for Cloud Sync pilot exclusion from Connect Sync export. |
| `New-RTGEntraIDCloudSyncMigrationOutboundRule` | Creates a single outbound rule that blocks export of objects flagged with `cloudNoFlow`. |
| `New-RTGEntraIDCloudSyncMigrationRule` | Low-level helper that creates a base Connect Sync rule (used internally by the inbound/outbound rule functions). |
| `Add-RTGEntraIDCloudSyncMigrationScopeCondition` | Adds a scope condition (e.g. group membership or OU) to a sync rule. |
| `Add-RTGEntraIDCloudSyncMigrationAttributeFlowMapping` | Adds an attribute flow mapping to a sync rule. |

Each function includes full comment-based help. Use `Get-Help <FunctionName> -Full` for detailed parameter documentation and examples, for example:

```powershell
Get-Help New-RTGEntraIDCloudSyncMigrationInboundRule -Full
```

## How It Works

Microsoft Entra Connect Sync assigns each sync rule a **precedence** value that determines evaluation order; lower numbers are evaluated first. This module inspects existing rule precedence values, then calculates unused precedence "slots" immediately above the lowest existing precedence to insert new custom rules without colliding with built-in or existing custom rules:

- **Inbound rules** (precedence values ending in `0`) flow a constant value of `True` into a `cloudNoFlow` attribute for in-scope `user`, `contact`, and `group` objects joined from Active Directory.
- **Outbound rules** (precedence values ending in `5`) use a `JoinNoFlow` link type scoped to objects where `cloudNoFlow = True`, preventing Connect Sync from exporting those objects to Microsoft Entra ID.

Together, these rules let Cloud Sync own synchronization for the pilot scope while Connect Sync continues to own everything else.

## Rollback

To reverse the pilot configuration, remove the custom rules this module created (visible in the Synchronization Rules Editor, prefixed `Custom - In from AD -` and `Custom - Out to AAD -`) and re-enable the sync scheduler:

```powershell
Get-ADSyncRule -Identifier <RuleIdentifier> | Remove-ADSyncRule
Set-ADSyncScheduler -SyncCycleEnabled $true
```

## Disclaimer

This module is provided as-is, without warranty of any kind. Always test in a non-production or lab environment before running against a production Microsoft Entra Connect Sync server, and ensure you have a current backup/export of your sync configuration.

## License

This project is licensed under the [MIT License](./LICENSE).

## Author

Ravenswood Technology Group, LLC
