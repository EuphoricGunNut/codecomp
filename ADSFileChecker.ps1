function Get-AlternateDataStream {
Param([string]$Path = "*.*")
$adscount = 0
Get-ChildItem -Path $path -recurse |  ForEach-Object {
    Get-Item $_.FullName -Stream * |Where-Object {$_.stream -ne ':$DATA'} |
     Select-Object @{Name="Path";Expression = {$_.filename}},
Stream,@{Name="Size";Expression={$_.length}} | Select Path,Stream,@{Name="Content";Expression={Get-Content $_.path -stream $_.stream | tee-object .\ads$adscount}} | format-tables -wrap
    $adscount++
     }
     write-host "$adscount File(s) have been extracted to your current directory"
}
function Check-MagicNumber {

Param([string]$Path = "*.*")
Param([string]$FileType = "txt")
#sets up counts and gets a list of all the files in the directories, recursive
$zipcount = 0
$rarcount = 0
$totalmasq = 0

$txtFiles = Get-ChildItem -Path $Path -Include *.$FileType -Recurse

foreach ($file in $txtFiles) {
    #Read Magic Number and convert it to a string
    $fileStream = [System.IO.File]::OpenRead($file.FullName)
    $magicNumber = New-Object Byte[] 4
    $fileStream.Read($magicNumber, 0, 4) | Out-Null
    $fileStream.Close()
    $magicNumberString = [System.BitConverter]::ToString($magicNumber)

    #write-host $magicNumberString
    # Check the magic number and output a message

    if ($magicNumberString -eq '50-4B-05-06' -or $magicNumberString -eq '50-4B-05-08' -or $magicNumberString -eq '50-4B-05-04' ) {
        Write-Output "$($file.FullName) is a .zip file"
        $zipcount++
        $totalmasq++
    } elseif ($magicNumberString -eq '52-61-72-21' ) {
        Write-Output "$($file.FullName) is a .RAR file"
        $rarcount++
        $totalmasq++
    }
}
#Final Counts
write-output "$totalmasq Files are disguising themselves as .$filetype files, $zipcount are Zip Files, $rarcount are RAR files."


}
Get-AlternateDataStream .\ 
Check-MagicNumber .\ 
