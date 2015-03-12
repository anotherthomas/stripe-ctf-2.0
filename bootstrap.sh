apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9;
echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list
apt-get update 
apt-get install -y python-pip lxc-docker bind9 libconfig-auto-perl libunix-syslog-perl libjson-xs-perl libnet-dns-perl
pip install docker-compose
usermod -a -G docker vagrant
cat > /etc/resolv.conf <<EOF
nameserver 127.0.0.1
search ctf.tng.retreat
EOF
cp /vagrant/dns/dns4docker.pl /usr/bin/
cp -r /vagrant/dns/* /etc/bind/
cp /vagrant/dns/dns4docker-upstart.conf /etc/init/
cp /vagrant/ctf-levels.conf /etc/init
cp -r /vagrant/levels /opt
start dns4docker-upstart
start ctf-levels
service bind9 restart
