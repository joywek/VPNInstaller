IP=`ifconfig | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk '{print $2}' | tr -d "addr:"`
echo $IP

yum install -y openswan ppp xl2tpd

echo -n "checking ipsec ... "
if [ $(which ipsec) ]; then
	echo "OK"
else
	echo "not found"
	exit
fi

echo -n "checking xl2tpd ... "
if [ $(which xl2tpd) ]; then
	echo "OK"
else
	echo "not found"
	exit
fi

echo "creating /etc/ipsec.conf ... "
sed "s/#IP#/$IP/g" ipsec.conf > /etc/ipsec.conf

echo "Enter the PSK: "
read PSK
echo -n "creating /etc/ipsec.secrets ... "
echo "$IP %any  0.0.0.0: PSK \"$PSK\"" > /etc/ipsec.secrets

echo "redirecting ... "
for each in /proc/sys/net/ipv4/conf/*
do
	echo 0 > $each/accept_redirects
	echo 0 > $each/send_redirects
done

echo "configuring system ... "
if [ `grep -c net.ipv4.ip_forward sysctl.conf` > 0 ]; then
	sed -ie "s/^[[:space:]]*#*[[:space:]]*\(net.ipv4.ip_forward[[:space:]]*=[[:space:]]\)[[:alnum:]]/\11/g" /etc/sysctl.conf
else
	echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
fi
if [ `grep -c net.ipv4.conf.default.rp_filter sysctl.conf` > 0 ]; then
	sed -ie "s/^[[:space:]]*#*[[:space:]]*\(net.ipv4.conf.default.rp_filter[[:space:]]*=[[:space:]]\)[[:alnum:]]/\10/g" /etc/sysctl.conf
else
	echo "net.ipv4.conf.default.rp_filter = 0" >> /etc/sysctl.conf
fi
if [ `grep -c net.ipv4.conf.default.accept_source_route sysctl.conf` > 0 ]; then
	sed -ie "s/^[[:space:]]*#*[[:space:]]*\(net.ipv4.conf.default.accept_source_route[[:space:]]*=[[:space:]]\)[[:alnum:]]/\10/g" /etc/sysctl.conf
else
	echo "net.ipv4.conf.default.accept_source_route = 0" >> /etc/sysctl.conf
fi
if [ `grep -c net.ipv4.conf.all.send_redirects sysctl.conf` > 0 ]; then
	sed -ie "s/^[[:space:]]*#*[[:space:]]*\(net.ipv4.conf.all.send_redirects[[:space:]]*=[[:space:]]\)[[:alnum:]]/\10/g" /etc/sysctl.conf
else
	echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf
fi
if [ `grep -c net.ipv4.conf.default.send_redirects sysctl.conf` > 0 ]; then
	sed -ie "s/^[[:space:]]*#*[[:space:]]*\(net.ipv4.conf.default.send_redirects[[:space:]]*=[[:space:]]\)[[:alnum:]]/\10/g" /etc/sysctl.conf
else
	echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf
fi
if [ `grep -c net.ipv4.icmp_ignore_bogus_error_responses sysctl.conf` > 0 ]; then
	sed -ie "s/^[[:space:]]*#*[[:space:]]*\(net.ipv4.icmp_ignore_bogus_error_responses[[:space:]]*=[[:space:]]\)[[:alnum:]]/\11/g" /etc/sysctl.conf
else
	echo "net.ipv4.icmp_ignore_bogus_error_responses = 1" >> /etc/sysctl.conf
fi
sysctl -p

echo "starting ipsec service ... "
ipsec setup

echo "creating /etc/xl2tpd/xl2tpd.conf ... "
cp xl2tpd.conf /etc/xl2tpd/xl2tpd.conf

echo "creating /etc/ppp/options.xl2tpd ... "
cp options.xl2tpd /etc/ppp/options.xl2tpd

echo "configuring package forward ... "
iptables --table nat --append POSTROUTING --jump MASQUERADE

echo "starting xl2tpd service ... "
xl2tpd

