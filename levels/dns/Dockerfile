FROM ubuntu:14.04 

RUN apt-get update; apt-get install -y bind9 libconfig-auto-perl libjson-xs-perl libnet-dns-perl libunix-syslog-perl
COPY dns4docker.pl /opt/
COPY db.ctf named.conf.local /etc/bind/

EXPOSE 53

CMD /usr/sbin/named -f 
