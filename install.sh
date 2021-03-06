#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
#Check OS
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ];then
    OS=CentOS
    [ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
    [ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
    [ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ];then
    OS=CentOS
    CentOS_RHEL_version=6
elif [ -n "$(grep bian /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Debian' ];then
    OS=Debian
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Deepin /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Deepin' ];then
    OS=Debian
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Ubuntu /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' -o -n "$(grep 'Linux Mint' /etc/issue)" ];then
    OS=Ubuntu
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
    [ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
else
    echo "Does not support this OS, Please contact the author! "
    kill -9 $$
fi


#Install Basic Tools
if [[ ${OS} == Ubuntu ]];then
	apt-get update
	apt-get install python -y
	apt-get install python-pip -y
	apt-get install git unzip wget -y
	apt-get install language-pack-zh-hans -y
    apt-get install build-essential screen curl -y
fi
if [[ ${OS} == CentOS ]];then
	yum install python screen curl -y
	yum install python-setuptools -y && easy_install pip -y
	yum install git unzip wget -y
    yum groupinstall "Development Tools" -y
fi
if [[ ${OS} == Debian ]];then
	apt-get update
	apt-get install python screen curl -y
	apt-get install python-pip -y
	apt-get install git unzip wget -y
    apt-get install build-essential -y
fi

#Install SSR and SSR-Bash
cd /usr/local/
git clone https://github.com/lllvcs/SSR-Bash-Python-dev
cp SSR-Bash-Python-dev/shadowsocksr.zip /usr/local/shadowsocksr.zip
chmod -R 777 /usr/local/SSR-Bash-Python-dev/
unzip shadowsocksr.zip
cd /usr/local/shadowsocksr
chmod -R 777 *
bash initcfg.sh

#Install Libsodium
cd /usr/local/SSR-Bash-Python-dev/
export LIBSODIUM_VER=1.0.11
tar xvf libsodium-$LIBSODIUM_VER.tar.gz
pushd libsodium-$LIBSODIUM_VER
./configure --prefix=/usr && make
make install
popd
ldconfig
cd /usr/local/SSR-Bash-Python-dev/ && rm -rf libsodium-$LIBSODIUM_VER.tar.gz libsodium-$LIBSODIUM_VER

#Start when boot
if [[ ${OS} == Ubuntu || ${OS} == Debian ]];then
    cat >/etc/init.d/ssr-bash-python-dev <<EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          SSR-Bash_python-dev
# Required-Start: $local_fs $remote_fs
# Required-Stop: $local_fs $remote_fs
# Should-Start: $network
# Should-Stop: $network
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description: SSR-Bash-Python-dev
# Description: SSR-Bash-Python-dev
### END INIT INFO
iptables-restore < /etc/iptables.up.rules
bash /usr/local/shadowsocksr/logrun.sh
EOF
    chmod 755 /etc/init.d/ssr-bash-python-dev
    chmod +x /etc/init.d/ssr-bash-python-dev
    cd /etc/init.d
    update-rc.d ssr-bash-python-dev defaults 95
fi

if [[ ${OS} == CentOS ]];then
    echo "
iptables-restore < /etc/iptables.up.rules
bash /usr/local/shadowsocksr/logrun.sh
" > /etc/rc.d/init.d/ssr-bash-python-dev
    chmod +x  /etc/rc.d/init.d/ssr-bash-python-dev
    echo "/etc/rc.d/init.d/ssr-bash-python-dev" >> /etc/rc.d/rc.local
    chmod +x /etc/rc.d/rc.local
fi


#Install SSR-Bash Background
cp /usr/local/SSR-Bash-Python-dev/ssr /usr/local/bin/ssr
chmod +x /usr/local/bin/ssr

#Modify ShadowsocksR API
sed -i "s/sspanelv2/mudbjson/g" /usr/local/shadowsocksr/userapiconfig.py
sed -i "s/UPDATE_TIME = 60/UPDATE_TIME = 10/g" /usr/local/shadowsocksr/userapiconfig.py
sed -i "s/SERVER_PUB_ADDR = '127.0.0.1'/SERVER_PUB_ADDR = '$(wget -qO- -t1 -T2 ipinfo.io/ip)'/" /usr/local/shadowsocksr/userapiconfig.py
#INstall Success
bash /usr/local/SSR-Bash-Python-dev/self-check.sh
echo "安装完成！输入 ssr 即可使用本程序"
