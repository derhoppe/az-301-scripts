$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

#Prüfung ob es sich um einen Samstag oder Sonntag handelt. Wenn ja, dann werden die Vms nicht hochgefahren
$weekday = (Get-Date).DayOfWeek

if($weekday -ne "Saturday" -And $weekday -ne "Sunday"){
    #In dieser Liste bitte die zu startenden VMs nach dem Schema "VMname|RessourcenGruppenName" anlegen
    #Die VMs werden dann auf den Status "deallocated" geprüft und hochgefahren
    $vmsToStart = @("VMNAME|RGNAME","VMNAME2|RGNAME2")

    foreach ($vm in $vmsToStart){
        $processinfos = $vm.Split('|')
        $VMDetail = Get-AzureRmVM -ResourceGroupName $processinfos[1] -Name $processinfos[0] -Status
        $RGN = $VMDetail.ResourceGroupName  
        foreach ($VMStatus in $VMDetail.Statuses)
        { 
            $VMStatusDetail = $VMStatus.DisplayStatus
        }
        if($VMStatusDetail -eq "VM deallocated") {
            Start-AzureRmVM -ResourceGroupName $processinfos[1] -Name $processinfos[0]
        }
    }
}

