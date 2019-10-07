#!/bin/bash
##
clear
hijau=$(tput setaf 2)
echo "${hijau}######################################"
echo "${hijau}Please run this scripts on SU !"
sudo su -
echo "${hijau}Min spec for cluster, backup, continues"
echo "${hijau}replication (DC-DR),load balancing etc"
echo "${hijau}4vCPU, 16GB RAM, NIC 10G or Bounded"
echo "${hijau}######################################"
tuned-adm profile network-throughput
hostnamectl set-hostname XOA
echo "${hijau}..................................."
echo "${hijau}Working...."
echo "${hijau}Please wait.."
/bin/yum install epel-release -y > /dev/null 2>&1
/bin/yum install curl -y  > /dev/null 2>&1
#yum update -y > /dev/null 2>&1
# add repo node js
echo "${hijau}..................................."
echo "add repo nodeJS v8.xx..."
curl -s -L https://rpm.nodesource.com/setup_8.x | bash - > /dev/null 2>&1
curl -s -o /etc/yum.repos.d/yarn.repo https://dl.yarnpkg.com/rpm/yarn.repo > /dev/null 2>&1
# Node
echo "${hijau}..................................."
echo "install nodeJS...."
echo "Please wait......"
sleep 1
/bin/yum install nodejs -y  > /dev/null 2>&1
# install yarn package
echo "${hijau}..................................."
echo "Install yarn package...."
sleep 2
/bin/yum install yarn -y > /dev/null 2>&1
# install lib vhd tools
sleep 1
echo "${hijau}..................................."
echo "Install vhd tools...."
/bin/rpm -ivh https://forensics.cert.org/cert-forensics-tools-release-el7.rpm > /dev/null 2>&1
/bin/sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/cert-forensics-tools.repo > /dev/null 2>&1
/bin/yum --enablerepo=forensics install -y libvhdi-tools > /dev/null 2>&1
# install kebutuhan xoa
echo "Install tool 4 xoa..."
echo "${hijau}..................................."
sleep 1
/bin/yum install gcc gcc-c++ make openssl-devel redis libpng-devel python git nfs-utils -y > /dev/null 2>&1
# install ssl
echo "${hijau}..................................."
echo "Install Open SSL.."
/bin/yum install mod_ssl -y > /dev/null 2>&1
# enable service redis etc 
echo "enable redis server..."
echo "${hijau}..................................."
/bin/systemctl enable redis && /bin/systemctl start redis
/bin/systemctl enable rpcbind && /bin/systemctl start rpcbind 
echo " Tools succes install"
echo "${hijau}..................................."

node=$(node -v) 
npm=$(npm -v)
yarn=$(yarn --version)
echo "Node js version $node"
echo "NPM version $npm"
echo "Yarn package version $yarn"
sleep 10
echo "${hijau}..................................."
echo "clone xoa from source"
echo "${hijau}..................................."
cd /opt/
/usr/bin/git clone https://github.com/vatesfr/xen-orchestra 
# allow config restore
sed -i 's/< 5/> 0/g' /opt/xen-orchestra/packages/xo-web/src/xo-app/settings/config/index.js
echo "${hijau}..................................."
echo "Build your XOA ..."
echo "${hijau}..................................."
cd /opt/xen-orchestra
/usr/bin/yarn
/usr/bin/yarn build
# configure xoa
echo "${hijau}..................................."
echo "--------------Configure xoa----------------"
echo "${hijau}..................................."
sleep 5
cd /opt/xen-orchestra/packages/xo-server
\cp sample.config.toml .xo-server.toml
chmod a+x /opt/xen-orchestra/packages/xo-server/.xo-server.toml
/bin/sed -i "s|#'/' = '/path/to/xo-web/dist/'|'/' = '../xo-web/dist/'|" .xo-server.toml
/bin/sed -i "s|port = 80|#port = 80|" .xo-server.toml
/bin/sed -i "s|# port = 443|port = 443|" .xo-server.toml
# certificate name design auto generate after install xo.
/bin/sed -i "s|# cert = './certificate.pem'|cert = '/opt/cert/cert-selfsigned.pem'|" .xo-server.toml
/bin/sed -i "s|# key = './key.pem'|key = '/opt/cert/key-selfsigned.pem'|" .xo-server.toml
# create node
echo "Create node ..."
echo "${hijau}..................................."
sleep 2
mkdir -p /usr/local/lib/node_modules/
/bin/ln -s /opt/xen-orchestra/packages/xo-server-* /usr/local/lib/node_modules/
/bin/rm -rf /etc/systemd/system/xo-server.service
# Cow BANNER
echo "attach kebo banner :v"
echo "${hijau}..................................."
sleep 2
cd /root/
/bin/git clone https://github.com/Adepurnomo/test.git
\cp /root/test/issue.net /etc
/bin/chmod a+x /etc/issue.net
cd /etc/ssh/ 	
/bin/sed -i "s|#Banner none|Banner /etc/issue.net|" sshd_config
/bin/chmod a+x /etc/ssh/sshd_config
/bin/rm -rf /root/test
#Create service for xoa
echo "${hijau}..................................."
echo "........ write service on systemd ........."
echo "${hijau}..................................."
/bin/cat << EOF >> /etc/systemd/system/xo-server.service
# Systemd service for XO-Server.

[Unit]
Description= XO Server
After=network-online.target

[Service]
WorkingDirectory=/opt/xen-orchestra/packages/xo-server/
ExecStart=/usr/bin/node ./bin/xo-server
Restart=always
SyslogIdentifier=xo-server

[Install]
WantedBy=multi-user.target
EOF

echo "${hijau}..................................."
echo "     Configure self sign ssl for xoa       "
echo "${hijau}..................................."
sleep 2
mkdir /opt/cert
/bin/chmod 700 /opt/cert
echo "Generate self ssl"
echo "Please wait......"
echo "${hijau}..................................."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /opt/cert/key-selfsigned.pem -out /opt/cert/cert-selfsigned.pem -subj "/C=Id/ST=DKI Jakarta/L=Jakarta/O=Ade Purnomo/OU=IT Department/CN=Port of Tanjung Priok"
openssl dhparam -out /opt/cert/dhparam.pem 2048 > /dev/null 2>&1
/bin/cat /opt/cert/dhparam.pem | tee -a /opt/cert/cert-selfsigned.pem

/bin/firewall-cmd --zone=public --add-port=80/tcp --permanent 
/bin/firewall-cmd --zone=public --add-port=443/tcp --permanent
/bin/firewall-cmd --reload

/bin/systemctl daemon-reload
/bin/systemctl enable xo-server.service && /bin/systemctl start xo-server 

sleep 2
echo "+++++++++++++++++++++++++++"
echo "========="DONE"============"
echo "+++++++++++++++++++++++++++"
host=$(hostname -I)
echo "and then acces https://$host"
echo "username : admin@admin.net"
echo "password : admin"
#echo "follow my ig @nextorchestra / @pauziah_collection"
echo "${hijau}------------------------------------------------"
/bin/systemctl restart sshd.service > /dev/null 2>&1

