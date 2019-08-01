#!/bin/pwsh
#/snap/bin/pwsh

<#
    .SYNOPSIS
    Creates new ZFS filesystem and share it by SMB

    .DESCRIPTION
    Creates new ZFS filesystem with custom properties.
    Set owners and permissions and share it by SMB.

    .PARAMETER Pool
        Defines pool name where new share will be created.
    .PARAMETER Share
        Defines new share name.
    .PARAMETER Owner
        Defines owner of new share.
    .PARAMETER OwnerGroup
        Defines owner group of new share.
    .PARAMETER Permissions
        Defines POSIX permissions for new share

    .EXAMPLE
        ./Set-SmbZfsShare.ps1 tank smb1 nobody nogroup 750

    .FUNCTIONALITY
        Powershell-core script
        
    .NOTES
        PowerShell-Core 6.2
        Script intended for unix like/based systems.

        21.04.2019 - public version
#>

param(
    [Parameter (Mandatory=$False, Position=0)]
    [string] $Pool = 'tank',
    [Parameter (Mandatory=$False, Position=1)]
    [string] $Share = 'home',
    [Parameter (Mandatory=$False, Position=2)]
    [string] $Owner = 'user@contoso.com',
    [Parameter (Mandatory=$False, Position=3)]
    [string] $OwnerGroup = 'share_admins@contoso.com',
    [Parameter (Mandatory=$False, Position=4)]
    [string] $Permissions = '750 '
)

$ShareName = -join ($Pool, '/', $Share)
$ShareConfigFolder = '/var/lib/samba/usershares/'
$ShareConfigFile = -join ($ShareConfigFolder, $Pool, '_', $Share)
$ShareOptions = './zfs_smb_share_config'

$CreateParams = -join(
                    'create ',
                    '-o casesensitivity=mixed ',
                    '-o xattr=sa ',
                    '-o aclinherit=passthrough ',
                    '-o exec=off ',
                    '-o setuid=off ',
                    '-o atime=off ',
                    '-o compression=lz4 ',
                    '-o sharesmb=on ',
                    '-o snapdir=visible ',
                    $ShareName
)

######################################################################

Start-Process zfs -ArgumentList $CreateParams

Write-Host `n`n "New smb share created:" -ForeGroundColor Green `n
zfs list |
    Select-String -Pattern $Share

$ChownParams = "${Owner}:${OwnerGroup} /$ShareName"
Start-Process chown -ArgumentList $ChownParams

$ChmodParams = -join($Permissions, ' /', $ShareName)
Start-Process chmod -ArgumentList $ChmodParams

Write-Host `n`n "Access permissions on share set properly:" -ForeGroundColor Green `n
ls -lah "/$Pool"

Start-Sleep -Seconds 3

(Get-Content $ShareConfigFile) + (Get-Content $ShareOptions) |
    Set-Content "$ShareConfigFile"

Write-Host `n`n "Share config file modified:" -ForeGroundColor Green `n
Get-Content $ShareConfigFile
