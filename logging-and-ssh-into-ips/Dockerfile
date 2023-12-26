FROM docker.io/kalilinux/kali-bleeding-edge

RUN apt update -y
RUN apt upgrade -y
RUN apt install -y iproute2 nmap metasploit-framework zsh openssh-client
RUN apt install -y sed wordlists
RUN gunzip /usr/share/wordlists/rockyou.txt.gz
WORKDIR /exploits
