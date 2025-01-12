$Title = "Backup Garbage"
$Header = "Backup Garbage: [count]"
$Comments = "The following VMs have snapshots left over from backup products. You may wish to investigate if these are still needed."
$Display = "Table"
$Author = "Alan Renouf, Frederic Martin, Dan Barr"
$PluginVersion = 1.5
$PluginCategory = "vSphere"


# Start of Settings
# Names used in backup product snapshots. Defaults include VCB, Veeam, NetBackup, Commvault, and Rubrik
$BackupNames = "VCB|Consolidate|veeam|NBU_SNAPSHOT|GX_BACKUP|RUBRIK"
# End of Settings

$FullVM | Where-Object { $_.snapshot | ForEach-Object { $_.rootsnapshotlist | Where-Object { $_.name -match $BackupNames } } } | Sort-Object Name | Select-Object Name

# Change Log
## 1.4 : Renamed to "Backup Garbage" to be more generic. Moved snapshot names to a setting and added Commvault to defaults. Corrected -contains to -match for regex compare.
## 1.5 : Added Rubrik as a default backup product
