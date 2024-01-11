function main {
$443count = 0 
$1434count = 0 
$53count = 0
$88count = 0
$resolvableCount = 0
$udpcount = 0  
$network = ("192.168.13")
$TCPPorts = ('443','1434')
$UDPPorts = ('53','88')

    for ($i = 15; $i -lt 255; $i++)  
        {
        $ping = Test-Connection $network.$i -Quiet -Count 1 
        if ($ping) { 
        write-host "$network.$i is up!"
        $IPToTest = "$network.$i"
           foreach ($port in $TCPPorts) {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcpconnection = $tcp.ConnectAsync($IPToTest,$port)
            $wait = $tcpconnection.AsyncWaitHandle.WaitOne(1000,$False)
            if ($wait) {
                Write-Host "TCP Port $port is Open on $IPToTest"
                    if ($port = '443'){
                    $443count++
                    }elseif ($port = '1434'){
                    $1434count++
                    }
                $tcpconnection.Dispose()
                } #else { 
               # Write-Host "TCP Port $port is Closed on $IPToTest"
               # }   
            $tcp.Dispose()
            }
            $dns = nslookup www.google.com $IPToTest 2>$null
                
            if ($dns -match "Name:\s+(.+)$") {
            $hostname = $matches[1]
            Write-Output "System at $IPToTest Has a functioning DNS server and resolves www.google.com to $hostname"
            $resolvableCount++
            } #else {
            #write-host "System does not have a functioning DNS Server"
            #}
            $udpclient = New-Object System.net.sockets.udpclient
            try{
                $udpClient.Connect($IPToTest, 88)
                $udpClient.Send([byte[]](0x00, 0x01), 2)
                $response = $udpclient.receive([ref]$IPToTest, [ref]$port)
                if $response {
                    write-host "$IPToTest Has port 88 open"
                    $udpcount++
                }

                }
            
        }
    }
Write-Host "Port 443 open: $443count"
Write-Host "Port 1434 open: $1434count"
Write-Host "DNS Servers Running: $resolvableCount"
}
main 