function Get-AlternateDataStream {
Param([string]$Path = "*.*")
$adscount = 0
Get-ChildItem -Path $path -recurse |  ForEach-Object {
    Get-Item $_.FullName -Stream * |Where-Object {$_.stream -ne ':$DATA'} |
     Select-Object @{Name="Path";Expression = {$_.filename}},
Stream,@{Name="Size";Expression={$_.length}} | Select Path,Stream,@{Name="Content";Expression={Get-Content $_.path -stream $_.stream}} | format-tables -wrap
    $adscount++
     }
     write-host "$adscount File(s) have been extracted to your current directory"
}
function Scan-Network {
$TCPPorts = ('443','1434','5985','3389')
#$UDPPorts = ('53','88')

#User Prompt for network
$network = read-host -Prompt "Specify a network (x.x.x)"
	#ping sweep for whole subnet
    for ($i = 7; $i -lt 13; $i++)  
        {
        $ping = Test-Connection "$network.$i" -Quiet -Count 1 
        if ($ping) { 
        write-host "$network.$i is up!"
		#if a response is given record it in a log, then move on to doing port scanning
        $IPToTest = "$network.$i" 
		$IPToTest | out-file -append .\IPs.txt
           foreach ($port in $TCPPorts) {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcpconnection = $tcp.ConnectAsync($IPToTest,$port)
            $wait = $tcpconnection.AsyncWaitHandle.WaitOne(1000,$False)
            if ($wait) {
				#success message
                Write-Host "TCP Port $port is Open on $IPToTest"
                $tcpconnection.Dispose()
				#if the scanned host has the PSSession Port open, store it in another file to use for further enumeration
                if ($port -eq '5985'){
                $IPToTest | out-file -append .\PSEnumIps.txt
                    }
                } 
				#sanity checking code
				#else { 
				# Write-Host "TCP Port $port is Closed on $IPToTest"
				# }   
            $tcp.Dispose()
            }
			
			#Can test if a server has functioning DNS, mostly unused as of now
			
            #$dns = nslookup www.google.com $IPToTest 2>$null
            #if ($dns -match "Name:\s+(.+)$") {
            #$hostname = $matches[1]
            #Write-Output "System at $IPToTest Has a functioning DNS server and resolves www.google.com to $hostname"
            #$resolvableCount++
			}
        }
	}
function Enumerate-Machine{
    
	#uncomment $livecred for production script, for testing declare this variable in console first
    #$livecred = Get-Credential
	
	
	#list of IPs to test comes from port scan
    $IPstoTest = get-content .\PSEnumIps.txt
	#simple if statement to check your psremoting settings
    $networkProfile = Get-NetConnectionProfile
    if ($networkProfile.NetworkCategory -eq 'Public') {
    Set-NetConnectionProfile -NetworkCategory Private 
    }
    Enable-PSRemoting
	#doing the enumeration
    foreach ($IPto in $IPstoTest) {
		#adding target to trustedhosts so that you can actually connect to it
        set-item WSman:\localhost\client\trustedhosts -Value "$IPto" -force
        write-output "Getting Event Logs for $IPto"
        invoke-command -computername $IPto -Credential $livecred -ScriptBlock {
            Get-EventLog -LogName System |Select-Object -Property Source, EventID, InstanceId, Message 
            Get-EventLog -LogName Security |Select-Object -Property Source, EventID, InstanceId, Message
            Get-EventLog -LogName Application |Select-Object -Property Source, EventID, InstanceId, Message
            } | out-file ".\Results\SysLogs$IPto"
        write-output "Scanning for IOCs On $IPto" 
		#getting network connections
		"IOCS for $IPto"| out-file -append ".\NetOutput.txt"
        invoke-command -computername $IPto -Credential $livecred -ScriptBlock {
            netstat -an
            (get-nettcpconnection -state synsent -erroraction silentlycontinue).remoteaddress|unique 
            get-content C:\Windows\System32\drivers\etc\hosts
            get-childitem "C:\Windows\System32\dns" -filter *.dns | get-content 
			arp -a 
            }  | out-file -append .\NetOutput.txt
             "IOCS for $IPto" | out-file -append ".\FileOutput.txt"
		#getting File System output for possible IOCS
        invoke-command -computername $IPto -Credential $livecred -ScriptBlock {
           get-childitem $env:SystemDrive\ -recurse	| Select-Object FullName,ComputerName
            }  | out-file -append .\FileOutput.txt 
            "IOCS for $IPto" | out-file -append ".\RegistryOutput.txt"
		#getting registry runkeys for matching
        invoke-command -computername $IPto -Credential $livecred -ScriptBlock {
            get-ItemProperty HKLM:\SOFTWARE\microsoft\windows\currentversion\run	 -erroraction SilentlyContinue	| Format-list -verbose
	        get-ItemProperty HKLM:\SOFTWARE\microsoft\windows\currentversion\runonce -erroraction SilentlyContinue	| Format-list -verbose
	        get-ItemProperty HKCU:\SOFTWARE\microsoft\windows\currentversion\run	 -erroraction SilentlyContinue	| Format-list -verbose
	        get-ItemProperty HKCU:\SOFTWARE\microsoft\windows\currentversion\runonce -erroraction SilentlyContinue	| Format-list -verbose
            get-scheduledtask | % { [pscustomobject]@{
	    	    Name=$_.TaskName
		        Command=$_.Actions.Execute
    		        }
               	}
            Get-LocalUser
			Get-LocalGroup
            }  | out-file -append .\RegistryOutput.txt  
    }
}
function grep-f {
	param(
     [Parameter()]
     [string]$InputFile,

     [Parameter()]
     [string]$SearchFile
 )
	$Patterns = Get-Content $inputfile   
    foreach ($pattern in $Patterns) {
        Get-Content $SearchFile | select-string -pattern $pattern
        }
	
}
function Compare-OutPuts {
	#Getting the files to filter from, leave blank for no filter, uncomment to get user input
	$IPinputfile = ".\ipiocs.txt" #read-host -prompt "Please input your file for IP IOCS"
	$Fileinputfile =".\files.txt" #read-host -prompt "Please input your file for File IOCS"
	$Reginputfile = ".\reg.txt" # read-host -prompt "Please input your file for Registry IOCS"
		#Files to filter against, created by the PsRemoteEnum function
	$IPsearchFile = ".\NetOutput.txt"
	$FilesearchFile = ".\FileOutput.txt"
	$RegsearchFile = ".\RegistryOutput.txt"
		#grep -f against all of the files
	Write-Host "Scanning IP IOCs"    
		grep-f $IPinputfile $IPsearchFile
	write-host "Scanning File IOCs" 
		grep-f $Fileinputfile $FilesearchFile
	write-host "Scanning Registry IOCs"
		grep-f $Reginputfile $RegsearchFile
}
#setting up a folder to put temp files for comparing 
remove-item -Recurse .\remenum -erroraction SilentlyContinue
mkdir .\remenum -ErrorAction SilentlyContinue
	cd .\remenum
	mkdir .\Results -ErrorAction SilentlyContinue
#give some messages to ensure the user the scripts are working and call the functions
	write-Host "Starting Script, Starting Network Scanner"
		Scan-Network
	write-host "Network Scan Complete, Starting Machine Enumeration"
		Enumerate-Machine
	write-host "Eumeration Complete, Comparing to filters provided"
		Compare-OutPuts | tee-object .\Results\FoundIOCs.txt
	write-host "Script Complete, Results are located in the Results Folder"
