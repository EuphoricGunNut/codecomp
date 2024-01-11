# Define the input text files and the output text file
$ipInputFile = "C:\users\DCI Student\Desktop\iocips.txt"
$domainInputFile = "C:\users\DCI Student\Desktop\iocdomains.txt"
$outputFile = "C:\users\DCI Student\Desktop\combined_rules.txt"
$sid = 1000000  # Starting SID number

# Initialize an array to store the output lines
$outputLines = @()

# Read and process IP addresses from the input file
$ipLines = Get-Content -Path $ipInputFile
foreach ($ipLine in $ipLines) {
    # Replace "<insert>" with the current IP address
    $ipOutputLine = 'alert ip any any <> {0} any (msg:"Found {0}"; sid:{1};)' -f $ipLine, $sid
    
    # Add the formatted IP rule to the output array
    $outputLines += $ipOutputLine
    
    # Increment the SID number for the next rule
    $sid++
}

# Read and process domain names from the input file
$domainLines = Get-Content -Path $domainInputFile
foreach ($domainLine in $domainLines) {
    # Create a PCRE pattern for the domain name
    $pcrePattern = "/$domainLine/i"  # Use case-insensitive matching by adding "i" at the end
    
    # Replace "<insert>" with the PCRE pattern for the domain
    $domainOutputLine = 'alert ip any any -> any any (msg:"Found {0}"; pcre:"{1}"; sid:{2};)' -f $domainLine, $pcrePattern, $sid
    
    # Add the formatted domain rule to the output array
    $outputLines += $domainOutputLine
    
    # Increment the SID number for the next rule
    $sid++
}

# Write the combined output lines to the output text file
$outputLines | Out-File -FilePath $outputFile

# Display a message indicating the operation is complete
Write-Host "Output has been written to $outputFile."