$Title = "Eval License Keys"
$Header = "Hosts using an Evaluation Key : [count]"
$Comments = "The following hosts are using an evaluation key that will expire, causing them to disconnect from vCenter."
$Display = "Table"
$Author = "Doug Taliaferro"
$PluginVersion = 1.0
$PluginCategory = "vSphere"

# Start of Settings
# End of Settings

$VMH | Where-Object { ($_.ConnectionState -match "^Connected|Maintenance") -and ($_.LicenseKey -eq "00000-00000-00000-00000-00000") } | Select-Object Name, LicenseKey
