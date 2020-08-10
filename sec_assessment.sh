#!/bin/bash

#--------------------General notes/checks for script--------------------
#Make sure you have a reliable Internet conection before running this script
wget -q --spider https://google.com
if [ $? -ne 0 ];
then
	echo "You are offline."
    	echo "Please make sure that you have a reliable Internet connection before running this script."
    	exit
fi

#Make sure you are running this script as a superuser i.e. as 'root'
if [[ $EUID -ne 0 ]];
then
	echo "Please run this script as root."
	exit
fi

#Set 'umask' to keep newly created files private by default
umask 077
#--------------------General notes/checks for script completed--------------------



#--------------------Get target info--------------------
read -p "Do you know the target URL? Enter 'yes' or 'no': " KNOWN_URL
if [ "$KNOWN_URL" = "yes" ];
then
	read -p "Target URL: " URL
	HOSTNAME=$(echo "$URL" | awk -F/ '{print $3}' | awk '{gsub("www.", "");print}')
        if [[ $HOSTNAME =~ ^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$ ]];
	then
		TARGET=$HOSTNAME
	else
		echo "Please enter a valid target URL."
    		exit
	fi
	ROOT_DOMAIN=$(echo "$URL" | awk -F/ '{print $3}' | awk -F. '{print $(NF-1)"."$NF}')
	read -p "Do you want to perform subdomain enumeration on $ROOT_DOMAIN? Enter 'yes' or 'no': " CORRECT_ROOT_DOMAIN
        if [ "$CORRECT_ROOT_DOMAIN" = "no" ];
        then
                read -p "What domain do you want to perform subdomain enumeration on?: " ROOT_DOMAIN
        fi
else
	echo "Please note that this script will not be able to perform subdomain enumeration." 
	read -p "IP address of your target: " IP
        if [[ $IP =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]];
	then
		TARGET=$IP
	else
		echo "Please enter a valid target IP."
                exit
	fi
fi

#--------------------Nmap--------------------
NMAP_RESULT=Nmap-$TARGET-$(date +"%Y-%m-%d-%T").txt
> $NMAP_RESULT
echo "---------- Port scan without host discovery, scan technique: TCP SYN and service/version detection ----------" | tee -a $NMAP_RESULT
echo "For more information about Nmap, visit https://nmap.org/" >> $NMAP_RESULT
echo -en "\n\n" >> $NMAP_RESULT
nmap -Pn -sS -sV $TARGET >> $NMAP_RESULT
echo -en "\n\n\n"

#--------------------Nikto--------------------
NIKTO_RESULT=Nikto-$TARGET-$(date +"%Y-%m-%d-%T").txt
> $NIKTO_RESULT
echo "---------- Web server assessment using Nikto ----------" | tee -a $NIKTO_RESULT
echo "For more information about Nikto, visit https://tools.kali.org/information-gathering/nikto" >> $NIKTO_RESULT
echo -en "\n\n" >> $NIKTO_RESULT
nikto -host $TARGET >> $NIKTO_RESULT
echo -en "\n\n\n"

#--------------------WhatWeb--------------------
WHATWEB_RESULT=WhatWeb-$TARGET-$(date +"%Y-%m-%d-%T").txt
> $WHATWEB_RESULT
echo "---------- Web technologies detection using WhatWeb with aggression level:4 ----------" | tee -a $WHATWEB_RESULT
echo "For more information about WhatWeb, visit https://www.morningstarsecurity.com/research/whatweb" >> $WHATWEB_RESULT
echo -en "\n\n" >> $WHATWEB_RESULT
whatweb --aggression 4 --verbose --quiet $TARGET >> $WHATWEB_RESULT
echo -en "\n\n\n"

#--------------------Gobuster--------------------
GOBUSTER_RESULT=Gobuster-$TARGET-$(date +"%Y-%m-%d-%T").txt
> $GOBUSTER_RESULT
echo "---------- Directory traversal using Gobuster with raft-medium wordlist and expanded mode (full URLs) ----------" | tee -a $GOBUSTER_RESULT
echo "For more information about Gobuster, visit https://tools.kali.org/web-applications/gobuster" >> $GOBUSTER_RESULT
echo -en "\n\n" >> $GOBUSTER_RESULT
wget -q https://raw.githubusercontent.com/Averroes/raft/master/data/wordlists/raft-medium-directories.txt
#Run Gobuster on target URL if known, else run it on target IP
if [ "$KNOWN_URL" = "yes" ];
then
        gobuster dir -u $URL -w raft-medium-directories.txt -e >> $GOBUSTER_RESULT
else
        gobuster dir -u $TARGET -w raft-medium-directories.txt -e >> $GOBUSTER_RESULT
fi
echo -en "\n\n\n"

#--------------------Sslscan--------------------
SSLSCAN_RESULT=Sslscan-$TARGET-$(date +"%Y-%m-%d-%T").txt
> $SSLSCAN_RESULT
echo "---------- SSL security assessment using sslscan with OCSP response, HTTP connection test and verbose output ----------" | tee -a $SSLSCAN_RESULT
echo "For more information about Sslscan, visit http://manpages.ubuntu.com/manpages/bionic/en/man1/sslscan.1.html" >> $SSLSCAN_RESULT
echo -en "\n\n" >> $SSLSCAN_RESULT
sslscan --ocsp --http --verbose $TARGET >> $SSLSCAN_RESULT
echo -en "\n\n\n"

#--------------------Amass--------------------
#Run Amass only if target URL is known
if [ "$KNOWN_URL" = "yes" ];
then
	AMASS_RESULT=Amass-$ROOT_DOMAIN-$(date +"%Y-%m-%d-%T").txt
	> $AMASS_RESULT
	echo "---------- Subdomain enumerations using amass with IP addresses for discovered names ----------" | tee -a $AMASS_RESULT
	echo "For more information about Amass, visit https://github.com/OWASP/Amass/blob/master/README.md" >> $AMASS_RESULT 
	echo -en "\n\n" >> $AMASS_RESULT
	amass enum -ip -d $ROOT_DOMAIN >> $AMASS_RESULT
fi
echo -en "\n\n\n"

#Copy result files into mounted directory
cp *.txt /home/
