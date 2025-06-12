# v1.03 - 1/29/25

# Redeploys the IX appliance to fix a certificate issue which was causing the bulk migration in module 2 to fail

$appliance = "HOL-1-IX-I1"
$hcxServer = "hcx-connect-01.vcf.sddc.lab"
$user = "administrator@vsphere.local"
$password = "VMware123!"

$maxConfigAttempts = 2
$n = 0
Do {
	Try {
		$config = Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -ParticipateInCeip $false -ProxyPolicy NoProxy -Scope User -Confirm:$false | Out-Null
		$configured = $true
	}
	Catch {
		$configured = $false
		Start-Sleep -Seconds 5
	}
	$n++
}
Until ($configured -or $n -ge $maxConfigAttempts)

$maxConnectAttempts = 20
$n = 0
Do {
	Try {
		$connect = Connect-HCXServer $hcxServer -user $user -Password $password -ErrorAction Stop | Out-Null
		$connected = $true
	}
	Catch {
		$connected = $false
		$connectError = "Failed to connect after $n attempts: $($_.Exception.Message)"
		Start-Sleep -Seconds 30
	}
	$n++
}
Until ($connected -or $n -ge $maxConnectAttempts)

If (-not $connected) {
	return $connectError
}

Try {
	$destinationSite = Get-HCXSite -Type VC -ErrorAction Stop
	$hcxJob = Get-HCXAppliance -Name $appliance | New-HCXAppliance -Redeploy -DestinationSite $destinationSite -ErrorAction Stop	
}
Catch {
	return "Failed to re-deploy $appliance : $($_.Exception.Message)"
}

$maxJobWait = 15
$n = 0
Do {
	Start-Sleep -Seconds 60
	$jobStatus = Get-HCXJob -Id $hcxJob.Id -ErrorAction SilentlyContinue
	#Write-Output "Percent Complete: $($jobStatus.PercentComplete)"
	$n++
}
Until ($jobStatus.IsDone -or $n -ge $maxJobWait)

#jobState should be "SUCCESS"
Return $jobStatus.State
