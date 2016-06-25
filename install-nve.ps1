﻿<#
.Synopsis

.DESCRIPTION
   install-nve.ps1

   Copyright 2014 Karsten Bott

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

.LINK
   https://community.emc.com/blogs/bottk/2015/05/04/labbuildrannouncement-unattended-vipr-controller-deployment-for-vmware-workstation
.EXAMPLE
#>
[CmdletBinding()]
Param(
[Parameter(ParameterSetName = "import", Mandatory = $true)][switch]$import,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][switch]$Defaults = $true,
[Parameter(ParameterSetName = "defaults",Mandatory = $true)]
[Parameter(ParameterSetName = "import",Mandatory = $true)][ValidateSet('9.0.1-72')]$nve_ver,
[Parameter(ParameterSetName = "defaults", Mandatory = $false)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile=".\defaults.xml"
)

$targetname = "nvenode1"
$rootuser = "root"
$rootpassword = "changeme"
$Product = "Networker"
$nve_dotver = $nve_ver -replace "-","."
$Product_tag = "nve-$nve_dotver"
$labdefaults = Get-labDefaults
$vmnet = $labdefaults.vmnet
$subnet = $labdefaults.MySubnet
$BuildDomain = $labdefaults.BuildDomain
$Builddir = $PSScriptRoot
try
    {
    $Sourcedir = $labdefaults.Sourcedir
    }
catch [System.Management.Automation.ValidationMetadataException]
    {
    Write-Warning "Could not test Sourcedir Found from Defaults, USB stick connected ?"
    Break
    }
catch [System.Management.Automation.ParameterBindingException]
    {
    Write-Warning "No valid Sourcedir Found from Defaults, USB stick connected ?"
    Break
    }
try
    {
    $Masterpath = $LabDefaults.Masterpath
    }
catch
    {
    Write-Host -ForegroundColor Gray " ==> No Masterpath specified, trying default"
    $Masterpath = $Builddir
    }
$Hostkey = $labdefaults.HostKey
$Gateway = $labdefaults.Gateway
$DefaultGateway = $labdefaults.Defaultgateway
$DNS1 = $labdefaults.DNS1
$DNS2 = $labdefaults.DNS2


switch ($PsCmdlet.ParameterSetName)
{
    "import"
        {
        Write-Verbose $Product_tag
        $Networker_dir = Join-Path $Sourcedir $Product
        Write-Verbose $Networker_dir
        $nve_dir = Join-Path $Networker_dir $Product_tag
        Write-Verbose "NVE Dir : $nve_dir"
        Write-Verbose "Masterpath : $masterpath" 
        if (!($Importfile = Get-ChildItem -Path $nve_dir -Filter "$Product_tag.ovf" -ErrorAction SilentlyContinue))
            {
            Write-Verbose "OVF does not exist, we need to extract from OVA" 

            if (!([array]$OVAPath = Get-ChildItem -Path "$Sourcedir\$Product" -Include "$Product_tag.ova" -ErrorAction SilentlyContinue) -or $forcedownload.IsPresent)
                {
                write-warning "No $Product OVA found, Checking for Downloaded Package"
                Receive-LABNetworker -nve -nve_ver $nve_ver -Destination "$Sourcedir\$Product" -verbose
                }
            [array]$OVAPath = Get-ChildItem -Path "$Sourcedir\$Product" -Recurse -include "$Product_tag.ova"  -Exclude ".*" | Sort-Object -Descending
            $Importfile = $OVApath[0]
            $OVA_Destination = join-path $Importfile.DirectoryName $Importfile.BaseName
            Write-Host -ForegroundColor Magenta " ==>Extraxting from OVA Package $Importfile"
            $Expand = Expand-LAB7Zip -Archive $Importfile.FullName -destination $OVA_Destination
            try
                {
                Write-Host -ForegroundColor Magenta " ==>Validating OVF from OVA Package"
                $Importfile = Get-ChildItem -Filter "*.ovf" -Path $Importfile.DirectoryName -ErrorAction SilentlyContinue
                }
            catch
                {
                Write-Warning "we could not find a ovf file at $($Importfile.Directoryname)"
                return
                }
            ## tweak ovf
            Write-Host -ForegroundColor Magenta " ==>Adjusting OVF file for VMwARE Workstation"
            $content = Get-Content -Path $Importfile.FullName
            $Out_Line = $true
            $OutContent = @()
            ForEach ($Line In $content)
                {
                If ($Line -match '<ProductSection')
                    {
                    $Out_Line = $false
                    }
                If ($Out_Line -eq $True)
                    {
                    $OutContent += $Line
                    }
                If ($Line -match '</ProductSection')
                    {
                    $Out_Line = $True
                    }
                }
            $OutContent | Set-Content -Path $Importfile.FullName
            }
        else
            {
            Write-Host -ForegroundColor Gray " ==> OVF already extracted, found $($Importfile.Basename)"#
            }
        if (!($mastername)) 
            {
            $mastername = $Importfile.BaseName
            }

        Write-Host -ForegroundColor Magenta " ==>Checkin for VM $mastername"

        if (Get-VMX -Path $masterpath\$mastername)
            {
            Write-Warning "Base VM $mastername already exists, please delete first"
            exit
            }
        else
            {
            Write-Host -ForegroundColor Magenta " ==>Importing Base VM"
            if ((import-VMXOVATemplate -OVA $Importfile.FullName -Name $mastername -destination $masterpath  -acceptAllEulas).success -eq $true)
                {
                Write-Host -ForegroundColor Gray "[Preparation of Template done, please run $($MyInvocation.MyCommand) -MasterPath $mastername]"
                }
            else
                {
                Write-Host "Error importing Base VM. Already Exists ?"
                exit
                }

    }


        <#
        $Mastercontent = Get-Content .\Scripts\NVE\NVEMAster.vmx
        $Mastercontent = $Mastercontent -replace "NVEMaster","$mastername"
        $Mastercontent | Set-Content -Path ".\$mastername\$mastername.vmx"
        $Mastervmx = get-vmx -path ".\$mastername\$mastername.vmx"
        $Mastervmx | New-VMXSnapshot -SnapshotName Base
        $Mastervmx | Set-VMXTemplate
        #>
    
    }

"defaults"

 {

[System.Version]$subnet = $Subnet.ToString()
$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
if (!$Defaultgateway)
    {
    $Defaultgateway = "$subnet.12"
    }
Write-Host -ForegroundColor Magenta " ==>Checking if node $targetname already exists"
if (get-vmx $targetname -WarningAction SilentlyContinue)
    {
    Write-Warning " the Virtual Machine already exists"
    Break
    }
$ip="$subnet.12"
if (!($MasterVMX = Get-VMX -Path $masterpath\$Product_tag))
    {
    Write-Host -ForegroundColor White "No Master exists for $Product_tag"
    return
    }

$Basesnap = $MasterVMX | Get-VMXSnapshot | where Snapshot -Match "Base"
if (!$Basesnap) 
    {
    $Content = Get-Content -Path $MasterVMX.config 
    $content = $content -replace "independent_",""
    $content | Set-Content -Path $MasterVMX.config
    Write-Host -ForegroundColor Magenta " ==>Base snap does not exist, creating now"
    $Basesnap = $MasterVMX | New-VMXSnapshot -SnapshotName BASE
    }

If (!($Basesnap))
    {
    Write-Error "Error creating/finding Basesnap"
    exit
    }


Write-Host -ForegroundColor Magenta " ==>Creating Machine $targetname"
$NodeClone = $Basesnap | New-VMXLinkedClone -CloneName $targetname -Path $Builddir
Write-Host -ForegroundColor Magenta " ==>Configuring VM Network for vmnet $vmnet"
$NodeClone | Set-VMXNetworkAdapter -Adapter 0 -AdapterType e1000 -ConnectionType custom -WarningAction SilentlyContinue | Out-Null
$NodeClone | Set-VMXVnet -Adapter 0 -vnet $vmnet -WarningAction SilentlyContinue | Out-Null
$NodeClone | Set-VMXDisplayName -DisplayName $targetname | Out-Null
$Annotation = $NodeClone | Set-VMXAnnotation -Line1 "https://$ip" -Line2 "user:$rootuser" -Line3 "password:$rootpassword" -Line4 "add license from $masterpath" -Line5 "labbuildr by @hyperv_guy" -builddate
$NodeClone | Start-VMX | Out-Null
     do {
        $ToolState = Get-VMXToolsState -config $NodeClone.config
        Write-Verbose "VMware tools are in $($ToolState.State) state"
        sleep 10
        }
    until ($ToolState.state -match "running")
     do {
        Write-Host -ForegroundColor Gray " ==> Waiting for $targetname to come up"
        $Process = Get-VMXProcessesInGuest -config $NodeClone.config -Guestuser $rootuser -Guestpassword $rootpassword
        sleep 10
        }
    until ($process -match "mingetty")
    Write-Host -ForegroundColor Magenta " ==>Configuring Base OS"
    Write-Host -ForegroundColor Gray " ==> Setting Network"
    $NodeClone | Invoke-VMXBash -Scriptblock "yast2 lan edit id=0 ip=$IP netmask=255.255.255.0 prefix=24 verbose" -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "hostname $($NodeClone.CloneName)" -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $Scriptblock = "echo 'default "+$DefaultGateway+" - -' > /etc/sysconfig/network/routes"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock  -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $sed = "sed -i -- 's/NETCONFIG_DNS_STATIC_SEARCHLIST=\`"\`"/NETCONFIG_DNS_STATIC_SEARCHLIST=\`""+$BuildDomain+".local\`"/g' /etc/sysconfig/network/config" 
    $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $sed = "sed -i -- 's/NETCONFIG_DNS_STATIC_SERVERS=\`"\`"/NETCONFIG_DNS_STATIC_SERVERS=\`""+$subnet+".10\`"/g' /etc/sysconfig/network/config"
    $NodeClone | Invoke-VMXBash -Scriptblock $sed -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "/sbin/netconfig -f update" -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
    $Scriptblock = "echo '"+$targetname+"."+$BuildDomain+".local'  > /etc/HOSTNAME"
    $NodeClone | Invoke-VMXBash -Scriptblock $Scriptblock -Guestuser $rootuser -Guestpassword $rootpassword  | Out-Null
    $NodeClone | Invoke-VMXBash -Scriptblock "/etc/init.d/network restart" -Guestuser $rootuser -Guestpassword $rootpassword | Out-Null
Write-Host -ForegroundColor Yellow "
Successfully Deployed $targetname

point your browser to https://$($ip)
Login with $rootuser/$rootpassword and follow the wizard steps
"
}
}
