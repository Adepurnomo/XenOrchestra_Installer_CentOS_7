#!/bin/bash
##
merah=$(tput setaf 1)
hijau=$(tput setaf 2)
kuning=$(tput setaf 3)
echo "${hijau}######################################"
echo "${hijau}Please run this scripts on SU"
echo "######################################"
hostnamectl set-hostname XOA
echo "${hijau}==================================="
echo "${hijau}Working...."
echo "${hijau}Please wait.."
echo "${hijau}==================================="
yum install epel-release -y > /dev/null 2>&1
#yum update -y > /dev/null 2>&1
# install ssl
echo "${hijau}==================================="
echo "Install Open SSL.."
echo "${hijau}==================================="
yum install mod_ssl -y > /dev/null 2>&1
# add repo node js
echo "${merah}==================================="
echo "add repo nodeJS v8.xx..."
echo "${merah}==================================="
curl -s -L https://rpm.nodesource.com/setup_8.x | bash - > /dev/null 2>&1
curl -s -o /etc/yum.repos.d/yarn.repo https://dl.yarnpkg.com/rpm/yarn.repo > /dev/null 2>&1
# Node
echo "${merah}==================================="
echo "install nodeJS...."
echo "Please wait......"
echo "${merah}==================================="
sleep 1
yum install nodejs -y  > /dev/null 2>&1
# install yarn package
echo "${hijau}==================================="
echo "Install yarn package...."
echo "${hijau}==================================="
sleep 2
yum install yarn -y > /dev/null 2>&1
# install lib vhd tools
sleep 1
echo "${merah}==================================="
echo "Install vhd tools...."
echo "${merah}==================================="
rpm -ivh https://forensics.cert.org/cert-forensics-tools-release-el7.rpm > /dev/null 2>&1
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/cert-forensics-tools.repo > /dev/null 2>&1
yum --enablerepo=forensics install -y libvhdi-tools > /dev/null 2>&1
# install kebutuhan xoa
echo "${hijau}==================================="
echo "Install tool 4 xoa..."
echo "${hijau}==================================="
sleep 1
yum install gcc gcc-c++ make openssl-devel redis libpng-devel python git nfs-utils -y > /dev/null 2>&1
# enable service redis  dll 
echo "${kuning}==================================="
echo "enable redis server..."
echo "${hijau}==================================="
/bin/systemctl enable redis && /bin/systemctl start redis
/bin/systemctl enable rpcbind && /bin/systemctl start rpcbind 
echo "${kuning}==================================="
echo " clone xoa engine from source"
echo "${kuning}==================================="
sleep 1
cd /opt/
/usr/bin/git clone https://github.com/vatesfr/xen-orchestra 
# allow config restoreee
sed -i 's/< 5/> 0/g' /opt/xen-orchestra/packages/xo-web/src/xo-app/settings/config/index.js
echo "${kuning}==================================="
echo "Build your XOA ..."
echo "${hijau}==================================="
sleep 10
echo "${kuning}==================================="
echo "3 ..."
echo "${hijau}==================================="
echo "${kuning}==================================="
echo "2 ..."
echo "${hijau}==================================="
echo "${kuning}==================================="
echo "1 ..."
echo "${hijau}==================================="
cd /opt/xen-orchestra
/usr/bin/yarn
/usr/bin/yarn build
# configure xoa
echo "${hijau}==================================="
echo "----------AUTO configure xoa----------"
echo "${kuning}==================================="
sleep 5
cd /opt/xen-orchestra/packages/xo-server
\cp sample.config.toml .xo-server.toml
chmod a+x /opt/xen-orchestra/packages/xo-server/.xo-server.toml
sed -i "s|#'/' = '/path/to/xo-web/dist/'|'/' = '../xo-web/dist/'|" .xo-server.toml
sed -i "s|port = 80|#port = 80|" .xo-server.toml
sed -i "s|# port = 443|port = 443|" .xo-server.toml
# certificate name design auto generate after install xo.
sed -i "s|# cert = './certificate.pem'|cert = '/root/cert/cert-selfsigned.pem'|" .xo-server.toml
sed -i "s|# key = './key.pem'|key = '/root/cert/key-selfsigned.pem'|" .xo-server.toml
# create node
echo "${kuning}==================================="
echo "Create node ..."
echo "${hijau}==================================="
sleep 5
mkdir -p /usr/local/lib/node_modules/
ln -s /opt/xen-orchestra/packages/xo-server-* /usr/local/lib/node_modules/
rm -rf /etc/systemd/system/xo-server.service
# Cow BANNER
echo "${hijau}==================================="
echo "attach kebo banner :v"
echo "${hijau}==================================="
sleep 3
cd /root/
git clone https://github.com/Adepurnomo/test.git
\cp /root/test/issue.net /etc
chmod a+x /etc/issue.net
cd /etc/ssh/ 	
sed -i "s|#Banner none|Banner /etc/issue.net|" sshd_config
chmod a+x etc/ssh/sshd_config
rm -rf /root/test
#bikin service daemon xoa
echo "${kuning}==================================="
echo "Create XOA daemon service on systemd ....."
echo "${hijau}==================================="
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

echo "${kuning}==================================="
echo "... SELFSIGN-SSL Auto configure for XOA ..."
echo "${hijau}==================================="
sleep 5
mkdir /root/cert
chmod 700 /root/cert
echo "${kuning}==================================="
echo "Generate self ssl"
echo "${kuning}==================================="
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /root/cert/key-selfsigned.pem -out /root/cert/cert-selfsigned.pem -subj "/C=Id/ST=DKI Jakarta/L=Jakarta/O=Ade Purnomo/OU=IT Department/CN=Port of Tanjung Priok"
openssl dhparam -out /root/cert/dhparam.pem 2048
cat /root/cert/dhparam.pem | tee -a /etc/ssl/certs/cert-selfsigned.pem
echo "+++++++++++++++++++++++++++"
echo "========="DONE"============"
echo "+++++++++++++++++++++++++++"
systemctl daemon-reload
systemctl enable xo-server.service
service xo-server start
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --reload

#service firewalld stop
#systemctl disable firewalld.service

service xo-server restart 
service xo-server status
node -v 
npm -v
yarn --version
sleep 2
echo "${hijau}==================================="
echo "done"
echo "${hijau}==================================="
echo "${kuning}==================================="
echo "and then acces https://ip or hostname your server, from your browser"
echo "username : admin@admin.net"
echo "password : admin"
#echo "follow my ig @nextorchestra / @pauziah_collection"
echo "${kuning}================================================="
service sshd restart
echo "--------------------------------------------------------------"

