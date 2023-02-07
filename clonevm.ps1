$allrg="rg-hk01-eas-u-sharedsvc01-vm02"
# Create a group list of all resource group
# $allrg="rg-hk01-eas-u-busapps01-vm03", "rg-hk01-eas-u-busapps01-vm04","rg-hk01-eas-u-busapps01-vm05","rg-hk01-eas-u-busapps01-vm07","rg-hk01-eas-u-busapps01-vm08", "rg-hk01-eas-u-digital01-dg01","rg-hk01-eas-u-digital01-vm01","rg-hk01-eas-u-digital01-vm02","rg-hk01-eas-u-digital01-vm03","rg-hk01-eas-u-infrasvc01-vm01","rg-hk01-eas-u-setk-resource01","rg-hk01-eas-u-sharedsvc01-vm01","rg-hk01-eas-u-sharedsvc01-vm02"
# Create total 13 lists to store VM name for each resource group..
$vmrg1="HKAZEULAP0121"
$vmrg2="HKAZEULAP0125","HKAZEULAP0126","HKAZEULAP0127","HKAZEULAP0128"
$vmrg3="HKAZEUWAP0003","HKAZEUWAP0004"
$vmrg4="HKAZEULAP0153","HKAZEULWB0005"
$vmrg5="HKAZEUWAP0122","HKAZEUWAP0123","HKAZEUWAP0124"
$vmrg6="HKAZEULAP0018 ","HKAZEULAP0019"
$vmrg7="HKAZEULAP0003","HKAZEULAP0004","HKAZEULAP0005","HKAZEULAP0006","HKAZEULAP0007","HKAZEULAP0008"
$vmrg8="HKAZEULAP0009","HKAZEULAP0010","HKAZEULAP0011","HKAZEULAP0012","HKAZEULAP0013","HKAZEULAP0014","HKAZEULAP0015","HKAZEULAP0016"
$vmrg9="HKAZEULAP0163","HKAZEULAP0103","HKAZEUWAP0102","HKAZEUWAP0108","HKAZEUWAP0109"
$vmrg10="HKAZEULWB0001","HKAZEULWB0002","HKAZEULWB0003","HKAZEULWB0004"
$vmrg11="HKAZEUWAP0147"
$vmrg12="HKAZEULSS0001","HKAZEULSS0002","HKAZEULSS0003","HKAZEULSS0004"
$vmrg13="HKAZEULAP0155","HKAZEULAP0156"
$allvm="$vmrg1","$vmrg2","$vmrg3","$vmrg4","$vmrg5","$vmrg6","$vmrg7","$vmrg8","$vmrg9","$vmrg10","$vmrg11","$vmrg12","$vmrg13"
$n=0

# Below are for testing only
$vm_rgone="HKAZEULAP0155"
# $vm_rgtwo="VM-AIA-Test", "OtherVMs"
$targetrg="rg-hk01-eas-r-infrasvc01-network01"

# Update to today date, VNET and subnet
$snapshotmetadata="-Snapshot-TFO20230207"
$diskmetadata="-OSDisk-TFO20230207"
$vmmetadata="-VM-TFO20230207"
$vnet="vnet-hk01-eas-r-infrasvc01"
$subnet="subnet-r-drsrv01-app-isolated-10.204.10.0-24"
# Below are for testing only
# $vm="HKAZEULAPXXXX-test"

# Below are for testing only
# az group create -n $targetrg -l eastasia 
# az network vnet create -n $vnet -g $targetrg --subnet-name default 


foreach ($rg in $allrg) {
    #foreach ($vm in $allvm[$n]){
    foreach ($vm in $vm_rgone){
        # Get the VM information and configure VM variables
        $vmdata=$(az vm show -n HKAZEULAP0155 -g rg-hk01-eas-u-sharedsvc01-vm02 -o tsv --query "[storageProfile.osDisk.managedDisk.id, tags.CostCenter, tags.BusinessApplication,tags.ServerOwner, hardwareProfile.vmSize, licenseType]") 
        $diskdata=$(az disk show --ids $vmdata[0] -o tsv --query "[diskSizeGb, sku.name, osType, supportedCapabilities.architecture, hyperVGeneration]")
        $disksnapshotname="$vm$snapshotmetadata"
        $diskname="$vm$diskmetadata"
        $vmname="$vm$vmmetadata"
        $tag_costcenter=$vmdata[1]
        $tag_businessapplication=$vmdata[2]
        $tag_serverowner=$vmdata[3]

        # Create snapshot from the VM disk
        Write-Host "Create snapshot from the VM disk"
        az snapshot create -g $targetrg -n $disksnapshotname --location eastasia --source $vmdata[0] --tags CostCenter=$tag_costcenter BusinessApplication=$tag_businessapplication ServerOwner=$tag_serverowner
        $snapshotid=$(az snapshot show -n $disksnapshotname -g $targetrg -o tsv --query [id]) 

        # Create disk from the snapshot
        Write-Host "Create disk from the snapshot"
        az disk create -g $targetrg -n $diskname --location eastasia --source $snapshotid --size-gb $diskdata[0] --sku $diskdata[1] --os-type $diskdata[2] --architecture $diskdata[3] --hyper-v-generation $diskdata[4] --tags CostCenter=$tag_costcenter BusinessApplication=$tag_businessapplication ServerOwner=$tag_serverowner
        $diskid=$(az disk show -g $targetrg -n $diskname -o tsv --query [id])

        # Create VM from the disk
        Write-Host "Create VM from the disk"
        az vm create --name $vmname -g $targetrg --attach-os-disk $diskid --public-ip-address '""' --nsg '""' --nsg-rule NONE --os-type $diskdata[2]  --size $vmdata[4] --vnet-name $vnet --subnet $subnet --tags CostCenter=$tag_costcenter BusinessApplication=$tag_businessapplication ServerOwner=$tag_serverowner
    }
    $n+=1
}