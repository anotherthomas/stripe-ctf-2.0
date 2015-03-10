apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9;
echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list
apt-get update 
apt-get install -y python-pip lxc-docker bind9 libconfig-auto-perl libunix-syslog-perl libjson-xs-perl libnet-dns-perl
pip install docker-compose
usermod -a -G docker vagrant
cp /vagrant/dns/dns4docker.conf /etc/docker
cp /vagrant/dns/dns4docker.pl /usr/bin/
cp -r /vagrant/dns/* /etc/bind/
cp /vagrant/dns/dns4docker-upstart.conf /etc/init/
service bind restart
