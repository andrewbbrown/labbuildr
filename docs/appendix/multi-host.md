# multi-host configurations
labbuildr allows for multi-host configurations. to be able to connect virtual machines on different hosts via network,   
the use of vlan´s is required. 

a standard, distributed labs use 802.1Q VLANS.  
I recommend TPLink or Netgear SoHo switches ( EG, TP-Link TL-SG108, Netgear GS-108GE, TP-Link Archer C7 w. OpenWRTR )  
Therefore, some requirements ion the hosts must be met:  
* For Windows Hosts, it is best using Intel ANS Drivers with VLAN SUpport ( Attention, on Windows 10 only Anniversary Update currently ! )   
* For Linux, use default VLAN SUpport ( Ubuntu witr Netrwork Manager )   
![image](https://cloud.githubusercontent.com/assets/8255007/25733949/823da6ee-315e-11e7-90dd-79f6a9f8fd10.png)
* For OSX, Default VLAN COnfig.  


Internet Connection is done Via OpenWRT ( Physically or VM )


# Example 1
In This Example, i create a VLAN VLAN3 , and the Virtual machine should use VMnet3.
The Subnet to be used is 10.10.3.0
OpenWRT runs as a VM on Host1

## On All Hosts
use the vmware-netcfg tool to configure a bridged vmnet3 pointing to vlan3
this requires that autobridging is enable for vmnet0
![image](https://cloud.githubusercontent.com/assets/8255007/25733995/03f31fca-315f-11e7-9b71-118559e13098.png)



## on Host1
```Powershell
Set-LABsubnet -subnet 10.10.3.0
Set-LABDNS -DNS1 10.10.3.10 -DNS2 10.10.3.4 
Set-LABvmnet vmnet3
Set-LabDefaultGateway 10.0.3.4
```



## Switch Config Example TP-Link 


![image](https://cloud.githubusercontent.com/assets/8255007/25733925/4c579300-315e-11e7-943d-d98a4c65cba2.png)
