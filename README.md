[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2feamonoreilly%2fStartStopPowerShellFunction%2fmaster%2fazuredeploy.json) 
<a href="http://armviz.io/#/?load=https%3a%2f%2fraw.githubusercontent.com%2feamonoreilly%2fStartStopPowerShellFunction%2fmaster%2fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

# Sample to start / stop VMs on a schedule

Create an Azure function application and deploy functions that starts or stops virtual machines in the specified resource group, subscription, or by tag on a schedule.

## Prerequisites

Before running this sample, you must have the following:

+ Install [Azure Core Tools version 2.x](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)

+ Install the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

### Create a new resource group and function application on Azure

Run the following PowerShell command and specify the value for the function application name in the TemplateParameterObject hashtable.

```powershell
New-AzResourceGroup -Name <resource group name> -Location <location>

New-AzResourceGroupDeployment -ResourceGroupName <resource group name> -TemplateParameterObject @{"functionAppName" = "<your function app name>"} -TemplateUri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-functions-managed-identity/azuredeploy.json" -verbose
```

This should create a new resource group with a function application and a managed service identity enabled. The id of the service principal for the MSI should be returned as an output from the deployment.

Example: principalId    String   cac1fa06-2ad8-437d-99f6-b75edaae2921

### Grant the managed service identity contributor access to the subscription or resource group so it can perform actions

The below command sets the access at the subscription level.

```powershell
$Context = Get-AzContext
New-AzRoleAssignment -ObjectId <principalId> -RoleDefinitionName Contributor -Scope "/subscriptions/$($Context.Subscription)"
```

### Clone repository or download files to local machine

+ Download the repository files or clone to local machine.

+ Change to the PowerShell/StartStopVMOnTimer directory.

### Get the local.settings.json values from the function application created in Azure

```powershell
func azure functionapp fetch-app-settings <function app name>
```

This should create a local.settings.json file in the StartStopVMOnTimer directory beside the host.json with the settings from the Azure function app.

### Test the functions locally

Start the function with the following command

```powershell
func start
```

You can then call a trigger function by performing a post against the function on the admin api. Open up another Powershell console session and run:

```powershell
Invoke-RestMethod "http://localhost:7071/admin/functions/StartVMOnTimer" -Method post -Body '{}' -ContentType "application/json"
```

Modify the values for each of the below variables in run.ps1 as needed.

```powershell
# Specify the VMs that you want to stop. Modify or comment out below based on which VMs to check.
$VMResourceGroupName = "Contoso"
#$VMName = "ContosoVM1"
#$TagName = "AutomaticallyStart"
```

Modify the start and stop time in the function.json file. They are currently set to 8am and 8pm UTC. You can change the timezone by modifying the application setting WEBSITE_TIME_ZONE. You can also pass in a parameter 'timezone' to the above [ARM template](https://raw.githubusercontent.com/eamonoreilly/AzureFunctions/master/PowerShell/ConsumptionAppWithTemplate/azuredeploy.json) that was used to create the function application if you want a different timezone so that daylight savings time will be honored.

```json
{
  "disabled": false,
  "bindings": [
    {
      "name": "Timer",
      "type": "timerTrigger",
      "direction": "in",
      "schedule": "0 0 20 * * *"
    }
  ]
}
```

## Publish the functions to the function application in Azure

```powershell
func azure functionapp publish <function app name>
```