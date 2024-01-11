function netScanner {
$TCPPorts = ('443','1434','5985','3389')
#$UDPPorts = ('53','88')
$network = read-host -Prompt "Specify a network (x.x.x)"
    for ($i = 1; $i -lt 255; $i++)  
        {
        $ping = Test-Connection "$network.$i" -Quiet -Count 1 
        if ($ping) { 
        write-host "$network.$i is up!" 
        $IPToTest = "$network.$i" 
		write-host $IPToTest > ./IPs.txt
           foreach ($port in $TCPPorts) {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcpconnection = $tcp.ConnectAsync($IPToTest,$port)
            $wait = $tcpconnection.AsyncWaitHandle.WaitOne(1000,$False)
            if ($wait) {
                Write-Host "TCP Port $port is Open on $IPToTest"
                $tcpconnection.Dispose()
                } 
				#else { 
				# Write-Host "TCP Port $port is Closed on $IPToTest"
				# }   
            $tcp.Dispose()
            }
            #$dns = nslookup www.google.com $IPToTest 2>$null
                
            #if ($dns -match "Name:\s+(.+)$") {
            #$hostname = $matches[1]
            #Write-Output "System at $IPToTest Has a functioning DNS server and resolves www.google.com to $hostname"
            #$resolvableCount++
			}
        }
	}