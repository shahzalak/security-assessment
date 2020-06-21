#Dockerfile for performing security assessment on target host using Nmap, Nikto, Whatweb, Dirb, Gobuster and SSLscan

#Patent (base) image: Kali
FROM kalilinux/kali-rolling

#Install Nmap, Nikto, Whatweb, Gobuster, SSLscan, Amass and other dependencies 
RUN apt-get update && apt-get install -y \
	wget \
	nmap \
	nikto \
	whatweb \
	gobuster \
	sslscan \
	amass

#Copy sec_assessment.sh script into filesystem of container
COPY sec_assessment.sh /root

#Change permission of sec_assessment.sh script
RUN chmod +x /root/sec_assessment.sh
