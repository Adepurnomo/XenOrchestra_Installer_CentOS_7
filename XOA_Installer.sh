#!/bin/bash
##
clear
kuning=$(tput setaf 3)
hijau=$(tput setaf 2)
echo "${hijau}#################################################"
echo "${hijau}        Please run this scripts on SU !          "
sudo su -
echo "${hijau}    Min spec for cluster, backup, continues      "
echo "${hijau}     replication (DC-DR),load balancing etc,     "
echo "${hijau}    for XenServer/CitrixHyprrvisor/XCP-NG        "
echo "${hijau}    Like XCP, use guest tools from citrix xen    "
echo "${hijau}      4vCPU, 16GB RAM, NIC 10G or Bounded        "
echo "${hijau}#################################################"
tuned-adm profile network-throughput
hostnamectl set-hostname XOA
echo "${kuning}------------------------------------------------"
echo "${kuning}Working....                                     "
echo "${kuning}Please wait...                                  "
/bin/yum install epel-release curl -y > /dev/null 2>&1
#yum update -y > /dev/null 2>&1

#add repo node js
sudo mkdir -p /opt/temp
sudo curl -o /opt/temp/spinner.sh https://raw.githubusercontent.com/tlatsas/bash-spinner/master/spinner.sh >> /dev/null 2>&1
sudo chmod a+x /opt/temp/spinner.sh
echo "${kuning}------------------------------------------------"
echo "add repo nodeJS v8.xx...                                 "
curl -s -L https://rpm.nodesource.com/setup_8.x | bash - > /dev/null 2>&1
curl -s -o /etc/yum.repos.d/yarn.repo https://dl.yarnpkg.com/rpm/yarn.repo > /dev/null 2>&1

# Node
echo "${kuning}------------------------------------------------"
echo "install nodeJS....                                       "
echo "Please wait......                                        "
sleep 1
/bin/yum install nodejs -y  > /dev/null 2>&1
# install yarn package
echo "${kuning}------------------------------------------------"
echo "Install yarn package....                                 "
sleep 2
/bin/yum install yarn -y > /dev/null 2>&1

# install lib vhd tools
sleep 1
echo "${kuning}------------------------------------------------"
echo "Install vhd tools...."
/bin/rpm -ivh https://forensics.cert.org/cert-forensics-tools-release-el7.rpm > /dev/null 2>&1
/bin/sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/cert-forensics-tools.repo > /dev/null 2>&1
/bin/yum --enablerepo=forensics install -y libvhdi-tools > /dev/null 2>&1
echo "Install tool 4 xoa..."
echo "${kuning}------------------------------------------------"
sleep 1
/bin/yum install gcc gcc-c++ make openssl-devel redis libpng-devel python36 git nfs-utils -y >> /dev/null 2>&1
echo "Install Open SSL.."
/bin/yum install mod_ssl -y > /dev/null 2>&1

# enable service redis etc 
echo "enable redis server...                                   "
echo "${kuning}------------------------------------------------"
/bin/systemctl enable redis > /dev/null 2>&1
/bin/systemctl start redis > /dev/null 2>&1
/bin/systemctl enable rpcbind > /dev/null 2>&1
/bin/systemctl start rpcbind > /dev/null 2>&1
echo "Tools succes install"
echo "${kuning}------------------------------------------------"
node=$(node -v) 
npm=$(npm -v)
yarn=$(yarn --version)
echo "Node js version $node                                    "
echo "NPM version $npm                                         "
echo "Yarn package version $yarn                               "
sleep 10
echo "${kuning}------------------------------------------------"
echo "clone xoa from source ---_____----_____-----             "
cd /opt/
/usr/bin/git clone https://github.com/vatesfr/xen-orchestra >> /dev/null 2>&1

# allow config restore
sed -i 's/< 5/> 0/g' /opt/xen-orchestra/packages/xo-web/src/xo-app/settings/config/index.js
echo "${kuning}------------------------------------------------"
echo "Build your XOA...                                        "
echo "${kuning}------------------------------------------------"
echo "${kuning}4 look activity first & last XOA, open new screen then"
echo "${kuning}------------------------------------------------"
echo "${kuning}use command 'tail -f /opt/temp/yarn-xoa.log'    "
echo "${kuning}------------------------------------------------"
source "/opt/temp/spinner.sh"
start_spinner 'First yarn 4 xoa..please wait (take several minute..'
sleep 1

cd ~
cd /opt/xen-orchestra
/usr/bin/yarn >> /opt/temp/yarn-xoa.log 
cd /opt/temp
stop_spinner $?
echo "${kuning}------------------------------------------------"
source "/opt/temp/spinner.sh"
start_spinner 'Last yarn 4 xoa..please wait (take several minute...'
sleep 1
cd /opt/xen-orchestra
/usr/bin/yarn build >> /opt/temp/yarn-xoa.log 
cd /opt/temp
stop_spinner $?

# configure xoa
echo "--------------------Configure XOA-----------------------"
sleep 5
cd /opt/xen-orchestra/packages/xo-server
\cp sample.config.toml .xo-server.toml
chmod a+x /opt/xen-orchestra/packages/xo-server/.xo-server.toml
/bin/sed -i "s|#'/' = '/path/to/xo-web/dist/'|'/' = '../xo-web/dist/'|" .xo-server.toml
/bin/sed -i "s|port = 80|#port = 80|" .xo-server.toml
/bin/sed -i "s|# port = 443|port = 443|" .xo-server.toml
# put certificate for xoa.
/bin/sed -i "s|# cert = './certificate.pem'|cert = '/opt/cert/cert-selfsigned.pem'|" .xo-server.toml
/bin/sed -i "s|# key = './key.pem'|key = '/opt/cert/key-selfsigned.pem'|" .xo-server.toml

# create node
clear
echo "Create node ..."
echo "${kuning}------------------------------------------------"
sleep 2
mkdir -p /usr/local/lib/node_modules/
/bin/ln -s /opt/xen-orchestra/packages/xo-server-* /usr/local/lib/node_modules/
/bin/rm -rf /etc/systemd/system/xo-server.service
# Banner
echo "attach banner :v"
echo "${kuning}------------------------------------------------"
sleep 2
cd /root/
/bin/git clone https://github.com/Adepurnomo/banner.git >> /dev/null 2>&1
\cp /root/banner/issue.net /etc
/bin/chmod a+x /etc/issue.net
cd /etc/ssh/ 	
/bin/sed -i "s|#Banner none|Banner /etc/issue.net|" sshd_config
/bin/chmod a+x /etc/ssh/sshd_config
/bin/rm -rf /root/banner
#Create service for xoa
echo "${kuning}        ~write service on systemd~              "
/bin/cat << EOF >> /etc/systemd/system/xo-server.service

# Systemd service for XO-Server.
[Unit]
Description= XO Server
After=network-online.target

[Service]
WorkingDirectory=/opt/xen-orchestra/packages/xo-server/
ExecStart=/usr/bin/node ./bin/xo-server
Restart=on-failure
SyslogIdentifier=xo-server

[Install]
WantedBy=multi-user.target
EOF

echo "${kuning}------------------------------------------------"
echo "Configure self sign ssl for xoa...........               "
echo "${kuning}------------------------------------------------"
sleep 2
mkdir /opt/cert
/bin/chmod 700 /opt/cert
source "/opt/temp/spinner.sh"
start_spinner 'Initializing...........'
sleep 1
cd ~
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /opt/cert/key-selfsigned.pem -out /opt/cert/cert-selfsigned.pem -subj "/C=Id/ST=DKI Jakarta/L=Jakarta/O=Ade Purnomo/OU=IT Department/CN=Port of Tanjung Priok" >> /dev/null 2>&1
cd /opt/temp
stop_spinner $?
source "/opt/temp/spinner.sh"
start_spinner 'Configure self sign ssl for xoa, please wait'
sleep 1
cd ~
openssl dhparam -out /opt/cert/dhparam.pem 2048 >> /dev/null 2>&1
cd /opt/temp
stop_spinner $?
/bin/cat /opt/cert/dhparam.pem | tee -a /opt/cert/cert-selfsigned.pem >> /dev/null 2>&1
echo "${kuning}------------------------------------------------"
echo "white list 80 on firewalld"
/bin/firewall-cmd --zone=public --add-port=80/tcp --permanent 
echo "white list 443 on firewalld"
/bin/firewall-cmd --zone=public --add-port=443/tcp --permanent
/bin/firewall-cmd --reload > /dev/null 2>&1
/bin/systemctl daemon-reload > /dev/null 2>&1
/bin/systemctl enable xo-server.service > /dev/null 2>&1
/bin/systemctl start xo-server > /dev/null 2>&1
rm -rf /opt/temp

sleep 2
echo "${kuning}------------------------------------------------"
echo "${kuning}                     DONE                       " 
echo "${kuning}------------------------------------------------"
host=$(hostname -I)
echo "and then acces https://$host                             "
echo "username : admin@admin.net                               "
echo "password : admin                                         "
echo "${kuning}------------------------------------------------"
echo "    for update your xoa, choose dir xoa installer        "
echo "cd '/opt/xen-orchestra' & run command 'git pull --ff-only'"
echo "              then > 'yarn' > last 'yarn build'          "
echo "                       Enjoy !!                          "
echo "${kuning}------------------------------------------------"
/bin/systemctl restart sshd.service > /dev/null 2>&1
