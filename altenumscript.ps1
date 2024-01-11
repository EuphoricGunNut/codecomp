# Define the lists of computers, registry entries, file entries, and IP addresses
$computerAddresses = '10.10.10.56', '10.10.10.83', '10.10.10.107'
$regEntries = Get-Content '~\Desktop\reg.txt'  # Read registry entries from a file
$fileEntries = Get-Content '~\Desktop\files.txt' # Read file paths from a file
$ipList = Get-Content '~\Desktop\ips.txt'  # Read IP addresses from a file

# Define a script block to execute on each remote computer
$scriptBlock = {
    Param ($computer, $regEntries, $fileEntries, $ipList)
    Try {
        # Output which computer is being connected to
        Write-Output "`r`n----------Connecting to ${computer}----------" 

        Write-Output "----------Checking Registry Values----------"
        #Format the data into key and value pairs
        foreach ($entry in $regEntries) {
            # Split each entry to get registry path and value
            $splitEntry = $entry -split '"'
            $regPath = $splitEntry[0].Trim()
            $regValue = $splitEntry[1].Trim()

            # Check if the registry value exists
            if ((Get-ItemProperty -Path "Registry::$regPath" -Name $regValue -ErrorAction SilentlyContinue) -ne $null) {
                Write-Output "Found: $entry"
            }
        }
        
        # Check if specified files exist 
        Write-Output "----------Checking Files and Retrieving Contents----------"
        $fileInfoTable = @{}

        foreach ($fileEntry in $fileEntries) {
            # Expand environment variables in the file path
            $expandedPath = [Environment]::ExpandEnvironmentVariables($fileEntry)
                       
            # Check if the file exists and add to file info table if it does
            if (Test-Path $expandedPath) {
                $fileInfoTable[$expandedPath] = $fileContents
                Write-Output "Found file: $expandedPath"
            } 
        }
        
        # Check current TCP connections against the provided IP list
        Write-Output "----------Checking TCP Connections----------"
        $tcpConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Established'}
        
        # Filter the connections that match the IP addresses in the list
        $matchingConnections = $tcpConnections | Where-Object { $using:ipList -contains $_.RemoteAddress}

        # Output the matching TCP connections
        foreach ($conn in $matchingConnections) {
            Write-Output "Matching TCP connection found: $($conn.RemoteAddress) on port $($conn.RemotePort)"
        }

    } Catch {
        # Handle any errors that occur during processing
        Write-Output "Error in processing ${computer}: $_"
    }
}

# Execute the script block on each computer in the list
$results = foreach ($computer in $computerAddresses) {
    Try {
        Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock -ArgumentList $computer, $regEntries, $fileEntries -ErrorAction SilentlyContinue
    } Catch {
        # Handle any errors that occur during the remote command execution
        Write-Output "Failed to connect to or execute commands on ${computer}: $_"
    }
}

# Save the results of the script to a file
$results | Out-File 'C:\Users\DCI Student\Desktop\scans.txt'