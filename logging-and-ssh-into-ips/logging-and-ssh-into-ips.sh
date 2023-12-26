# ./msfconsole -r documentation/msfconsole_rc_ruby_example.rc

docker build -f Dockerfile -t kalilinux/kali-bleeding-edge-metasploit-framework:latest .

IP="${1}"
echo "trying IP=${IP}"
echo "--------------------------------"

set -o xtrace

docker run \
  --volume ./:/exploits \
  --volume ./.msf3:/root/.msf3 \
  --net host \
  --rm  \
  -t \
  kalilinux/kali-bleeding-edge-metasploit-framework:latest \
  /bin/bash -c "
echo "pwd=$(pwd)";
set -o xtrace;
sed -i 's/RHOSTS 10.0.2.6/RHOSTS ${IP}/g' /root/.msf3/msfconsole.rc;
cat /root/.msf3/msfconsole.rc;
msfconsole --real-readline /root/.msf3/msfconsole.rc;
"
