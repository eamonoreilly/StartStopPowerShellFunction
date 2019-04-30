# Input bindings are passed in via param block.
param($Timer)

# Specify the VMs that you want to stop. Modify or comment out below based on which VMs to check.
$VMResourceGroupName = "Contoso"
#$VMName = "ContosoVM1"
#$TagName = "AutomaticallyStop"

# Stop on error
$ErrorActionPreference = 'stop'

# Check if managed identity has been enabled and granted access to a subscription, resource group, or resource
$AzContext = Get-AzContext -ErrorAction SilentlyContinue
if (-not $AzContext.Subscription.Id)
{
     Throw ("Managed identity is not enabled for this app or it has not been granted access to any Azure resources. Please see https://docs.microsoft.com/en-us/azure/app-service/overview-managed-identity for additional details.")
}

try 
{
    # Get a single vm, vms in a resource group, or all vms in the subscription
    if  ($null -ne $VMResourceGroupName -and $null -ne $VMName)
    {
        Write-Information ("Getting VM in resource group " + $VMResourceGroupName + " and VMName " + $VMName)
        $VMs = Get-AzVM -ResourceGroupName $VMResourceGroupName -Name $VMName
    }
    elseif ($null -ne $VMResourceGroupName)
    {
        Write-Information("Getting all VMs in resource group " + $VMResourceGroupName)
        $VMs = Get-AzVM -ResourceGroupName $VMResourceGroupName
    }
    else
    {
        Write-Information ("Getting all VMs in the subscription")
        $VMs = Get-AzVM
    }

    # Check if VM has the specified tag on it and filter to those.
    If ($null -ne $TagName)
    {
        $VMs = $VMs | Where-Object {$_.Tags.Keys -eq $TagName}
    }

    # Stop the VM if it is running
    $ProcessedVMs = @()

    foreach ($VirtualMachine in $VMs)
    {
        $VM = Get-AzVM -ResourceGroupName $VirtualMachine.ResourceGroupName -Name $VirtualMachine.Name -Status
        if ($VM.Statuses.Code[1] -eq 'PowerState/running')
        {
            Write-Information ("Stopping VM " + $VirtualMachine.Id)
            $ProcessedVMs += $VirtualMachine.Id
            Stop-AzVM -Id $VirtualMachine.Id -Force -AsJob | Write-Information
        }
    }
    # Sleep here a few seconds to make sure that the command gets processed before the script ends
    if ($ProcessedVMs.Count -gt 0)
    {
        Start-Sleep 10
    } 
}
catch
{
    throw $_.Exception.Message
}
