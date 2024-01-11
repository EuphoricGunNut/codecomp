

User Names:
Remote 1: Administrator/DC3P@ssw0rd
Remote 2: Administrator/DC3P@ssw0rd
GRR(Server): student/DC3P@ssw0rd
GRR(WebApp): admin/password
 
Remote 1: IP 172.16.12.5
Remote 2: IP 172.16.12.3
$TargetIP = 172.16.12.3
$LiveCred = Get-Credential
$parameters = @{
  computer-name		= $TargetIP
  Credential        = $LiveCred
  Authentication    = 'Basic'
  ScriptBlock       = {  }
}
1 IPs
Computer 1 172.16.12.3
Computer 2 172.16.12.5
			Question 2: Hostnames
Computer 1 EC2AMAZ-4IBBGLH
Computer 2 EC2AMAZ-4IBBGLH
			Question 3: Operating Systems
Computer 1 Windows Server 2019 Datacenter version 1809
Computer 2 Windows Server 2019 Datacenter version 1809
			Question 4: Free Space
Computer 1 12086394880
Computer 2 11506728960
			Question 5: Installed Programs
Computer 1 PuTTY, Microsoft Visual C++ runtimes, Amazon SSM, AWS Bootstrap, AWS PV Drivers
Computer 2 PuTTY, Microsoft Visual C++ runtimes, Amazon SSM, AWS Bootstrap, AWS PV Drivers, GRR 