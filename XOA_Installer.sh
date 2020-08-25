#!/bin/bash
##
clear
if [[ $EUID -ne 0 ]]; then
   echo "----------------------------------------------------------"
   echo "            Please run this scripts on SU !               "
   echo "----------------------------------------------------------"
   exit 1
fi
clear
echo "${hijau}                     INSTALLER                        "
echo "${hijau}<--------------------------------------------------->"
sleep 10
echo "${hijau}<====================================================>"
echo "${hijau}|      Min spec for cluster, backup, continues       |"
echo "${hijau}|       replication (DC-DR),load balancing etc,      |"
echo "${hijau}|      for XenServer/CitrixHypervisor/XCP-NG         |"
echo "${hijau}|     Like XCP, use guest tools from citrix xen      |"
echo "${hijau}|        4vCPU, 16GB RAM, NIC 10G or Bounded         |"
echo "${hijau}<====================================================>"
tuned-adm profile network-throughput
hostnamectl set-hostname XOA
echo "${hijau} --------------------------------------------------- "
echo "${hijau}|                     Working....                   |"
echo "${hijau}|                  Please wait...                   |"
/bin/yum install epel-release curl -y > /dev/null 2>&1
#yum update -y > /dev/null 2>&1

#add repo node js
echo "${hijau} --------------------------------------------------- "
echo "${hijau}|               add repo nodeJS v8.xx...            |"
echo "${hijau}|                                                   |"
curl -s -L https://rpm.nodesource.com/setup_8.x | bash - > /dev/null 2>&1
curl -s -o /etc/yum.repos.d/yarn.repo https://dl.yarnpkg.com/rpm/yarn.repo > /dev/null 2>&1

# Node
echo "${hijau} --------------------------------------------------- "
echo "${hijau}|                Install nodeJS...                  |"
echo "${hijau}|                  Please wait...                   |"
sleep 1
/bin/yum install nodejs -y  > /dev/null 2>&1
# install yarn package
echo "${hijau} --------------------------------------------------- "
echo "${hijau}|              Install yarn package....             |"
echo "${hijau}|                                                   |"
sleep 2
/bin/yum install yarn -y > /dev/null 2>&1

# install lib vhd tools
sleep 1
echo "${hijau} --------------------------------------------------- "
echo "${hijau}|                Install vhd tools...               |"
echo "${hijau}|                                                   |"
/bin/rpm -ivh https://forensics.cert.org/cert-forensics-tools-release-el7.rpm > /dev/null 2>&1
/bin/sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/cert-forensics-tools.repo > /dev/null 2>&1
/bin/yum --enablerepo=forensics install -y libvhdi-tools > /dev/null 2>&1
echo "${hijau}|               Install tools 4 xoa...              |"
echo "${hijau} --------------------------------------------------- "
sleep 1
/bin/yum install gcc gcc-c++ make openssl-devel redis libpng-devel python36 git nfs-utils -y >> /dev/null 2>&1
echo "${hijau}|                 Install Open SSL..                |"
/bin/yum install mod_ssl -y > /dev/null 2>&1

# enable service redis etc 
echo "${hijau}|                Enable redis server                |"
echo "${hijau}|                                                   |"
echo "${hijau} --------------------------------------------------- "
/bin/systemctl enable redis > /dev/null 2>&1
/bin/systemctl start redis > /dev/null 2>&1
/bin/systemctl enable rpcbind > /dev/null 2>&1
/bin/systemctl start rpcbind > /dev/null 2>&1
echo "${hijau}|               Tools succes install                |"
echo "${hijau}|                                                   |"
echo "${hijau} --------------------------------------------------- "
node=$(node -v) 
npm=$(npm -v)
yarn=$(yarn --version)
echo "${hijau}|            Node js version $node                  |"
echo "${hijau}|              NPM version $npm                     |"
echo "${hijau}|          Yarn package version $yarn               |"
sleep 10
echo "${hijau} --------------------------------------------------- "
echo "${hijau}|             Clone xoa from source...              |"
echo "${hijau}|                                                   |"
cd /opt/
/usr/bin/git clone https://github.com/vatesfr/xen-orchestra >> /dev/null 2>&1

# allow config restore
sed -i 's/< 5/> 0/g' /opt/xen-orchestra/packages/xo-web/src/xo-app/settings/config/index.js
echo "${hijau} --------------------------------------------------- "
echo "${hijau}|                ..Build your XOA..                 |"
echo "${hijau}|                                                   |"
echo "${hijau} --------------------------------------------------- "
echo "${hijau}|         4 look activity first & last XOA          |"
echo "${hijau}|                                                   |"
echo "${hijau} --------------------------------------------------- "
echo "${hijau}|open new screen, & 'tail -f /opt/temp/yarn-xoa.log |"
echo "${hijau}|                                                   |"
echo "${hijau} --------------------------------------------------- "
echo "${hijau}|First yarn 4 xoa please wait... "
sleep 1

cd ~
cd /opt/xen-orchestra
/usr/bin/yarn >> /opt/temp/yarn-xoa.log 
echo "${hijau}|Last yarn 4 xoa please wait..."

cd /opt/xen-orchestra
/usr/bin/yarn build >> /opt/temp/yarn-xoa.log 
cd /opt/temp
stop_spinner $?

# configure xoa
echo "${hijau}<------------------Configure XOA-------------------->"
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
echo "${hijau}|                   Create node ...                 |"
echo "${hijau}|                                                   |"
echo "${hijau} --------------------------------------------------- "
sleep 2
mkdir -p /usr/local/lib/node_modules/
/bin/ln -s /opt/xen-orchestra/packages/xo-server-* /usr/local/lib/node_modules/
/bin/rm -rf /etc/systemd/system/xo-server.service
# Banner
echo "${hijau}|                 Attach banner ..                  |"
echo "${hijau}|                                                   |"
echo "${hijau} --------------------------------------------------- "
sleep 2
cd /root/
/bin/git clone https://github.com/Adepurnomo/banner.git >> /dev/null 2>&1
\cp /root/banner/issue.net /etc
/bin/chmod a+x /etc/issue.net
cd /etc/ssh/ 	
/bin/sed -i "s|#Banner none|Banner /etc/issue.net|" sshd_config
/bin/chmod a+x /etc/ssh/sshd_config
/bin/rm -rf /root/banner

echo "${hijau}|            ~write service on systemd~             |"
/bin/cat << EOF >> /etc/systemd/system/xo-server.service
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

echo "${hijau} --------------------------------------------------- "
echo "${hijau}|        ..Configure self sign ssl for xoa..        |"
echo "${hijau}|                                                   |"
echo "${hijau} --------------------------------------------------- "
sleep 2
mkdir /opt/cert
/bin/chmod 700 /opt/cert
cd ~
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /opt/cert/key-selfsigned.pem -out /opt/cert/cert-selfsigned.pem -subj "/C=Id/ST=DKI Jakarta/L=Jakarta/O=Ade Purnomo/OU=IT Department/CN=Port of Tanjung Priok" >> /dev/null 2>&1
echo "${hijau}|Configure self sign ssl for xoa, please wait... "
sleep 1
cd ~
openssl dhparam -out /opt/cert/dhparam.pem 2048 >> /dev/null 2>&1
cd /opt/temp
stop_spinner $?
/bin/cat /opt/cert/dhparam.pem | tee -a /opt/cert/cert-selfsigned.pem >> /dev/null 2>&1
echo "${hijau}<--------------------------------------------------->"
echo "${hijau}               white list 80 on firewalld            "
/bin/firewall-cmd --zone=public --add-port=80/tcp --permanent 
echo "${hijau}               white list 443 on firewalld           "
/bin/firewall-cmd --zone=public --add-port=443/tcp --permanent
echo "${hijau}              white list 19999 on firewalld          "
/bin/firewall-cmd --zone=public --add-port=19999/tcp --permanent
echo "${hijau}<--------------------------------------------------->"
/bin/firewall-cmd --reload > /dev/null 2>&1
/bin/systemctl daemon-reload > /dev/null 2>&1
/bin/systemctl enable xo-server.service > /dev/null 2>&1
/bin/systemctl start xo-server > /dev/null 2>&1

echo "${hijau} --------------------------------------------------- "
echo "${hijau}|                Netdata Installer                  |" 
echo "${hijau}|               -------------------                 |"
echo "${hijau}|                                                   |"
echo "${hijau} --------------------------------------------------- "

yum install Judy-devel autoconf autoconf-archive autogen automake gcc libmnl-devel libuuid-devel libuv-devel lz4-devel nmap-ncat openssl-devel zlib-devel git -y >> /dev/null 2>&1
cd /opt
git clone https://github.com/netdata/netdata.git > /dev/null 2>&1
#put 0 to 1 (skip) question for installer netdata
sed -i 's/TWAIT} -eq 0 /TWAIT} -eq 1 /g' /opt/netdata/netdata-installer.sh
chmod a+x /opt/netdata/netdata-installer.sh
echo "${hijau}|Installing netdata, please wait... "
sleep 1
cd /opt/netdata/
./netdata-installer.sh > /dev/null 2>&1 

cd ~
servis=$(systemctl status netdata | grep running)
echo "${hijau} --------------------------------------------------- "
echo "${hijau}|                   Netdata status. .               |"
echo "${hijau}|${hijau}$servis                                    |"
sleep 10

echo "${hijau} --------------------------------------------------- "
echo "${hijau}|                       DONE                        |" 
echo "${hijau} --------------------------------------------------- "
host=$(hostname -I)
echo "${hijau}|and then acces XOA https://$host                   |"
echo "${hijau}|username : admin@admin.net                         |"
echo "${hijau}|password : admin                                   |"
echo "${hijau} --------------------------------------------------- "
echo "${hijau}|4 acces Netdata http://$host:19999                 | "
echo "${hijau} --------------------------------------------------- "
echo "${hijau}|                    Enjoy !!                       |"
echo "${hijau} --------------------------------------------------- "
/bin/systemctl restart sshd.service > /dev/null 2>&1
