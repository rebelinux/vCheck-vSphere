$Title = "QuickStats Capacity Planning"
$Header = "QuickStats Capacity Planning"
$Comments = "The following gives brief capacity information for each cluster based on QuickStats CPU/Mem usage and counting for HA failover requirements"
$Display = "Table"
$Author = "Raphael Schitz, Frederic Martin"
$PluginVersion = 1.8
$PluginCategory = "vSphere"


# Start of Settings
# Max CPU usage for non HA cluster
$limitResourceCPUClusNonHA = 0.6
# Max MEM usage for non HA cluster
$limitResourceMEMClusNonHA = 0.6
# End of Settings

# Update settings where there is an override
$limitResourceCPUClusNonHA = Get-vCheckSetting $Title "limitResourceCPUClusNonHA" $limitResourceCPUClusNonHA
$limitResourceMEMClusNonHA = Get-vCheckSetting $Title "limitResourceMEMClusNonHA" $limitResourceMEMClusNonHA

Add-Type -AssemblyName System.Web
$capacityinfo = @()
foreach ($cluv in ($clusviews | Where-Object { $_.Summary.NumHosts -gt 0 } | Sort-Object Name)) {

    if ( $cluv.Configuration.DasConfig.Enabled -eq $true ) {
        $DasRealCpuCapacity = $cluv.Summary.EffectiveCpu - (($cluv.Summary.EffectiveCpu * $cluv.Configuration.DasConfig.FailoverLevel) / $cluv.Summary.NumHosts)
        $DasRealMemCapacity = $cluv.Summary.EffectiveMemory - (($cluv.Summary.EffectiveMemory * $cluv.Configuration.DasConfig.FailoverLevel) / $cluv.Summary.NumHosts)
    } else {
        $DasRealCpuCapacity = $cluv.Summary.EffectiveCpu * $limitResourceCPUClusNonHA
        $DasRealMemCapacity = $cluv.Summary.EffectiveMemory * $limitResourceMEMClusNonHA
    }

    $cluvmlist = $VM | Where-Object { $cluv.Host -contains $_.VMHost.Id }

    #CPU
    $CluCpuUsage = (Get-View $cluv.ResourcePool).Summary.runtime.cpu.OverallUsage
    $CluCpuUsageAvg = $CluCpuUsage
    if ($cluvmlist -and $cluv.host -and $CluCpuUsageAvg -gt 0) {
        $VmCpuAverage = $CluCpuUsageAvg / ($cluvmlist.count)
        $CpuVmLeft = [math]::round(($DasRealCpuCapacity - $CluCpuUsageAvg) / $VmCpuAverage, 0)
    } elseif ($CluCpuUsageAvg -eq 0) { $CpuVmLeft = "N/A" }
    else { $CpuVmLeft = 0 }

    #MEM
    $CluMemUsage = (Get-View $cluv.ResourcePool).Summary.runtime.memory.OverallUsage
    $CluMemUsageAvg = $CluMemUsage / 1MB
    if ($cluvmlist -and $cluv.host -and $CluMemUsageAvg -gt 100) {
        $VmMemAverage = $CluMemUsageAvg / (Get-Cluster -Id $cluv.MoRef | Get-VM).count
        $MemVmLeft = [math]::round(($DasRealMemCapacity - $CluMemUsageAvg) / $VmMemAverage, 0)
    } elseif ($CluMemUsageAvg -lt 100) { $MemVmLeft = "N/A" }
    else { $MemVmLeft = 0 }

    # vCPU to pCPU ratio
    if ($cluvmlist) {
        $vCPUCPUthreadratio = ("1:{0}" -f [math]::round(($cluvmlist | Measure-Object -Sum -Property NumCpu).sum / $cluv.summary.NumCpuThreads, 1))
        $vCPUpCPUratio = ("1:{0}" -f [math]::round(($cluvmlist | Measure-Object -Sum -Property NumCpu).sum / $cluv.summary.NumCpuCores, 1))
        $VMVMHostRatio = ("1:{0}" -f [math]::round(($cluvmlist).count / $cluv.Summary.NumHosts, 1))
    } else {
        $vCPUpCPUratio = "0 (vCPU < pCPU)"
        $VMVMHostRatio = 0
    }

    $clucapacity = [PSCustomObject] @{
        Datacenter = (Get-VIObjectByVIView -MORef $cluv.Parent).Parent.Name
        ClusterName = [System.Web.HttpUtility]::UrlDecode($cluv.name)
        "Estimated Num VM Left (CPU)" = $CpuVmLeft
        "Estimated Num VM Left (MEM)" = $MemVmLeft
        "vCPU/pCPU Core ratio" = $vCPUpCPUratio
        "vCPU/pCPU Thread ratio" = $vCPUCPUthreadratio
        "VM/VMHost ratio" = $VMVMHostRatio
    }

    $capacityinfo += $clucapacity
}

$capacityinfo | Sort-Object Datacenter, ClusterName

# Changelog
## 1.8 : Use 'Get-Cluster -Id' and [System.Web.HttpUtility]::UrlDecode to handle special characters in cluster name.
##       Fix bug where $MemVmLeft was not getting reset and displays value from previous cluster.
