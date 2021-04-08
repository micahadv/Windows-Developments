#DC Server Config


#Check and Set PC name before script
$confirmation = Read-Host "Before the script can be run, The server name must be set. Is the computer name $env:computername correct? [y/n]"
while($confirmation -ne "y")
{
    if ($confirmation -eq 'n') {$client = Read-Host "Please enter client Name (one word, this will be used to name the server clientname-DC01)"
    Rename-Computer -NewName "$client-DC01" -Force 
    Read-Host "Computer has been renamed to "$client-DC01""
    $confirmation = Read-Host "Reboot Computer to apply name? [y/n]"
    if ($confirmation -eq 'y') {Restart-Computer}
    {
    if ($confirmation -eq 'n') {exit}
    }
    }
}

#Variables For setup
$domain = Read-Host "Please enter Domain Name (including .local / .com)"
$netbiosName = Read-Host "Please enter NETBIOS Name (ALL CAP DOMAIN Name without .local /.com"

#grabs the ipv4 information for the xfreerdp line info (Below Commented out due to External IP Line)
#$ipV4 = Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address



#force confirmation before proceeding
$confirmation = Read-Host "Domain name $domain & Netbios name $netbiosName Set, Is this Correct? [y/n]"
while($confirmation -ne "y")
{
    if ($confirmation -eq 'n') {exit}
}

#Set Time Zone
Set-TimeZone -Name "Eastern Standard Time"


#Masiero Tech -local Admin account
Add-Type -AssemblyName System.Web
$password = [System.Web.Security.Membership]::GeneratePassword(12,2)
$SecurePass = $password | ConvertTo-SecureString -AsPlainText -Force
New-LocalUser "masiero" -Password $SecurePass -FullName "Masiero Tech" -Description "Admin account for Masiero Tech"
Add-LocalGroupMember -Group "Administrators" -Member "masiero"
Read-Host "Masiero Account created. Password: $password"



#install features
$featureLogPath = “c:\Logs\ADDS\ADDS.txt”
New-Item $featureLogPath -ItemType file -Force
$addsTools = “RSAT-AD-Tools”
Add-WindowsFeature $addsTools -LogPath $featureLogPath
Get-WindowsFeature | Where installed >> $featureLogPath



#Install AD DS, DNS and GPMC
$featureLogPath = “c:\Logs\ADDS\ADDS.txt”
start-job -Name addFeature -ScriptBlock {
Add-WindowsFeature -Name “ad-domain-services” -IncludeAllSubFeature -IncludeManagementTools
Add-WindowsFeature -Name “dns” -IncludeAllSubFeature -IncludeManagementTools
Add-WindowsFeature -Name “gpmc” -IncludeAllSubFeature -IncludeManagementTools }
Wait-Job -Name addFeature
Get-WindowsFeature | Where installed >>$featureLogPath


# Create New Forest, add Domain Controller
$params = @{
'-DatabasePath'= 'C:\Windows\NTDS';
'-DomainMode' = 'Default';
'-DomainName' = $domain;
'-DomainNetbiosName' = $netbiosName;
'-ForestMode' = 'Default';
'-InstallDns' = $true;
'-LogPath' = 'C:\Windows\NTDS';
'-NoRebootOnCompletion' = $true;
'-SysvolPath' = 'C:\Windows\SYSVOL';
'-Force' = $true;}
Import-Module ADDSDeployment
Install-ADDSForest @params -CreateDnsDelegation:$false -SafeModeAdministratorPassword $SecurePass


#choco install - Chrome install
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install googlechrome puppet-bolt -y

#ScreenConnect -Donwload and Install
wget "http://sc.masiero.us:8040/Bin/Masiero-Remote_Support.ClientSetup.msi?h=sc.masiero.us&p=8041&k=BgIAAACkAABSU0ExAAgAABEAAADBLgb6W%2Bwno2NIfSXd7NtxMrr2edPbVrtA5%2B64KRECP9xSvLj1afGVhMJX93zWs9sMQbDKIzWvdNZHdaJQF4wU4CBk3Orgt%2BppbweaQWAxyaNyRHGGzz8os6kxSydCzQaUajpRv8ELU6nN7vtPqqP0cpuTGCHCgN7K7qte9JzhAooewTBwR1ZVKOvIMS9eVGdLBooNLEU3wtk3960%2Bc%2F1kh%2BZPSrSMDhn5JLPRIHqesfxmLkHpIyngvWGOmCOQzMiwn%2Bi4hT0rLlEQQvl29xsawUcRYH3pcYmhBazLPxeU59m6UXpOce5Gqx%2BBoLzGPVpZQSIi3xfxMw5xrvkcig%2BU&e=Access&y=Guest&t=&c=&c=&c=&c=windows&c=&c=&c=&c=" -Outfile C:\sc.msi
msiexec /i C:\sc.msi

#Create Scheduled Reboot Task for Mon/Thur @ 2:15am
schtasks /create /tn “MTG Scheduled Reboot” /tr “shutdown /r /t 0” /sc weekly /D MON,THU /st 02:15 /ru “System” /RL HIGHEST


#Grab External IP address
$ExtIP = Invoke-RestMethod -uri https://ipinfo.io/json | select-object -ExpandProperty ip


#final readout
Read-Host "CONGRATULATIONS! The server has been setup and is ready to go. click any key to grab the updated xfreerdp information and reboot"
Read-Host "xfreerdp /u:masiero /p:$password /d:$domain /v:$ExtIP /w:1300 /h:750"


#force confirmation before Rebooting
$confirmation = Read-Host "The server has been setup and is ready to be rebooted, Reboot now? [y/n]"
while($confirmation -ne "y")
{
    if ($confirmation -eq 'n') {exit}
}

#reboot server
Restart-Computer

