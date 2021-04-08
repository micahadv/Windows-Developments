#PS TS Deploy

#Variables
$TS = 10.0.1.11
$clientname = Read-Host "Please enter Client name (will be used for server rename *clientname*-TS01)"
$domain = Read-Host "Please enter Domain Name (including .local / .com)"


#force confirmation before proceeding
$confirmation = Read-Host "The current server name is: $env:computername. Ok to rename to $clientname-TS01 and Join $domain ? [y/n]"
while($confirmation -ne "y") 
{
    if ($confirmation -eq 'y') {Add-Computer -DomainName $domain -ComputerName $env:computername -newname $clientname-TS01}
    if ($confirmation -eq 'n') {$confirmation = Read-Host "Continue with script with current '$env:computername'? [y/n]"
        if ($confirmation -eq 'n') {exit}
        if ($confirmation -eq 'y')  {
        #proceed
        }
    }
}


#Set Time Zone
Set-TimeZone -Name "Eastern Standard Time"



#FQDN name
$sysinfo = Get-WmiObject -Class Win32_ComputerSystem
$server = “{0}.{1}” -f $sysinfo.Name, $sysinfo.Domain





#Join Domain -> this is a command to be run remotely against the PC. To bake into DC script? 
#Add-Computer -ComputerName $TS -LocalCredential "$TS\Administrator" -DomainName "$domain" -Credential Domain\masiero -Restart -Force -Verbose


#DNS Suffix
Set-DnsClientGlobalSetting -SuffixSearchList @("$domain")


#Add RDP Roles
Import-Module RemoteDesktop

New-SessionDeployment –ConnectionBroker $server –WebAccessServer $server –SessionHost $server

Add-RDServer -Server $server -Role RDS-LICENSING -ConnectionBroker $server

Set-RDLicenseConfiguration -LicenseServer $server -Mode PerUser -ConnectionBroker $server


#choco install - Chrome install
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install googlechrome puppet-bolt -y

#ScreenConnect -Donwload and Install
wget "http://sc.masiero.us:8040/Bin/Masiero-Remote_Support.ClientSetup.msi?h=sc.masiero.us&p=8041&k=BgIAAACkAABSU0ExAAgAABEAAADBLgb6W%2Bwno2NIfSXd7NtxMrr2edPbVrtA5%2B64KRECP9xSvLj1afGVhMJX93zWs9sMQbDKIzWvdNZHdaJQF4wU4CBk3Orgt%2BppbweaQWAxyaNyRHGGzz8os6kxSydCzQaUajpRv8ELU6nN7vtPqqP0cpuTGCHCgN7K7qte9JzhAooewTBwR1ZVKOvIMS9eVGdLBooNLEU3wtk3960%2Bc%2F1kh%2BZPSrSMDhn5JLPRIHqesfxmLkHpIyngvWGOmCOQzMiwn%2Bi4hT0rLlEQQvl29xsawUcRYH3pcYmhBazLPxeU59m6UXpOce5Gqx%2BBoLzGPVpZQSIi3xfxMw5xrvkcig%2BU&e=Access&y=Guest&t=&c=&c=&c=&c=windows&c=&c=&c=&c=" -Outfile C:\sc.msi
msiexec /i C:\sc.msi

#Create Scheduled Reboot Task for Mon/Thur @ 2:15am
schtasks /create /tn “MTG Scheduled Reboot” /tr “shutdown /r /t 0” /sc weekly /D MON,THU /st 02:15 /ru “System” /RL HIGHEST


#Xfree


