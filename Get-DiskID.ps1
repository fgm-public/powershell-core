#!/bin/pwsh
#/snap/bin/pwsh

<#
    .SYNOPSIS
        Determines the correspondence between disk naming notations (disk by-label -> disk by-id)   

    .DESCRIPTION
        Determines the correspondence between disk naming notations (disk by-label -> disk by-id).
        Write result to console and store it to text file in JSON.
        Works only with whole physycal disks. 

    .PARAMETER Path
        Defines path to file where stores result.

    .EXAMPLE
        ./Get-DiskID.ps1
            Out result to console

        ./Get-DiskID.ps1 -Path ./disks.json
            Out result to disks.json file

    .FUNCTIONALITY
        Powershell-core script

    .NOTES
        PowerShell-Core 6.2
        Script intended for unix like/based systems with label-id disk naming notation.

        10.04.2019 - public version
#>

param(
    [Parameter (Mandatory=$False, Position=0)]
    [string] $Path = './disk.list'
)

$DiskInterface = 'scsi'
$DiskMapping = @{}
$DiskMapping.Clear()

$Disks = Get-ChildItem /dev/disk/by-id |
    Where-Object -Property Name -Match $DiskInterface |
    	Where-Object -Property Name -NotMatch 'part'

for($i=0;$i -lt $Disks.Count; $i++){
    $DiskMapping.Add($Disks.Target[$i], $Disks.Name[$i])
}

$Result = $DiskMapping.GetEnumerator() |
    Sort-Object Key

if ($Path){
    $DiskMapping |
        ConvertTo-Json |
            Out-File -Path $Path
}else{
    $Result
}