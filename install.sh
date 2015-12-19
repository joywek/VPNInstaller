
IP=`ifconfig | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk '{print $2}' | tr -d "addr:"`
echo $IP

echo -n "creating /etc/ipsec.conf ... "
sed "s/#IP#/$IP/g" ipsec.conf >  /etc/ipsec.conf
echo "OK"

echo -n "Enter the PSK: "
read PSK
echo "creating /etc/ipsec.secrets ... "
echo "$IP %any  0.0.0.0: PSK \"$PSK\"" > /etc/ipsec.secrets
echo "OK"

echo -n "redirecting ... "
for each in /proc/sys/net/ipv4/conf/*
do
	echo 0 > $each/accept_redirects
	echo 0 > $each/send_redirects
done
echo "OK"



