#region Internationalization
################################################################################
#                             Internationalization                             #
################################################################################
# Default language en-US
Import-LocalizedData -BaseDirectory ($ScriptPath + '\Lang') -BindingVariable pLang -UICulture en-US -ErrorAction SilentlyContinue

# Override the default (en-US) if it exists in lang directory
Import-LocalizedData -BaseDirectory ($ScriptPath + "\Lang") -BindingVariable pLang -ErrorAction SilentlyContinue

#endregion Internationalization

$Title = "VMs in uncontrolled snapshot mode"
$Header = "VMs in uncontrolled snapshot mode: [count]"
$Comments = "The following VMs are in snapshot mode, but vCenter isn't aware of it. See http://kb.vmware.com/kb/1002310"
$Display = "Table"
$Author = "Rick Glover, Matthias Koehler, Dan Rowe, Bill Wall"
$PluginVersion = 1.6
$PluginCategory = "vSphere"

# Start of Settings
# Do not report uncontrolled snapshots on VMs that are defined here
$ExcludeDS = "ExcludeMe"
# End of Settings

$i = 0;
foreach ($eachDS in ($Datastores | Where-Object { $_.Name -notmatch $ExcludeDS } | Where-Object { $_.State -eq "Available" })) {
    Write-Progress -Id 2 -Parent 1 -Activity $pLang.pluginActivity -Status ($pLang.pluginStatus -f $i, $Datastores.count, $eachDS.Name) -PercentComplete ($i * 100 / $Datastores.count)

    $FilePath = $eachDS.DatastoreBrowserPath + '\*\*delta.vmdk*'
    $fileList = @(Get-ChildItem -Path "$FilePath" | Select-Object Name, FolderPath, FullName)
    $FilePath = $eachDS.DatastoreBrowserPath + '\*\-*-flat.vmdk'
    $fileList += Get-ChildItem -Path "$FilePath" | Select-Object Name, FolderPath, FullName

    $i++

    foreach ($vmFile in $filelist | Sort-Object FolderPath) {
        $vmFile.FolderPath -match '^\[([^\]]+)\] ([^/]+)' > $null
        $VMName = $matches[2]
        $eachVM = $FullVM | Where-Object { $_.Name -eq $VMName }
        if (-Not $eachVM.snapshot) {
            # Only process VMs without snapshots
            New-Object -TypeName PSObject -Property @{
                VM = $eachVM.Name
                Datacenter = $eachDS.Datacenter
                Path = $vmFile.FullName
            }
        }
    }
}
Write-Progress -Id 1 -Activity $pLang.pluginActivity -Status $pLang.Complete -Completed

# Changelog
## 1.6 : Added setting to exclude DS
