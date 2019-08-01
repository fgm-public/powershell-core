#!/bin/pwsh
#/snap/bin/pwsh

<#
    .SYNOPSIS
        Create ZFS storage pool

    .DESCRIPTION
        Create ZFS storage pool with custom properties and reservation.

    .EXAMPLE
        ./Create-ZFSPool.ps1

    .FUNCTIONALITY
        Powershell-core script
        
    .NOTES
        PowerShell-Core 6.2
        Script intended for unix like/based systems with label-id disk naming notation.

        21.04.2019 - public version
#>

$pool_name = 'zp1'
$pool_reserv = '80G'
$disk_shift = "-o ashift=12"
$vdev_type = 'mirror'
$pool_properties = 'compression=lz4',
                   'dedup=sha256'

$disks = Get-Content ./disk.list |
    ConvertFrom-Json -AsHashtable

$vdev_disks = $disks.Item('/dev/sdb'),
              $disks.Item('/dev/sdc'),
              $disks.Item('/dev/sdd'),
              $disks.Item('/dev/sde')

$cache_disks = $disks.Item('/dev/sdf'),
               $disks.Item('/dev/sdg')

$log_disk = $disks.Item('/dev/sdh')

$pool_params = -join(
                        "create ",
                        "$disk_shift ", 
                        "$pool_name ",
                        "$vdev_type $($vdev_disks[0..1]) ",
                        "$vdev_type $($vdev_disks[2..3]) ",
                        "log $log_disk ",
                        "cache $cache_disks"
)

Start-Process zpool -ArgumentList $pool_params
Start-Sleep -Seconds 3

foreach ($property in $pool_properties){
    Start-Process zfs -ArgumentList "set $property $pool_name"
    Start-Sleep -Seconds 3
}

$reserve_params = -join(
                        "create ",
                        "-o refreservation=$pool_reserv ",
                        "$pool_name/.reserv"
                    )

Start-Process zfs -ArgumentList $reserve_params
Start-Sleep -Seconds 3

zfs get compression
zfs list