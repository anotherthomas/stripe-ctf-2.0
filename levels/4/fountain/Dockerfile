FROM python:2.7

RUN apt-get update; apt-get install -y wget tar git build-essential

RUN cd tmp; wget http://phantomjs.googlecode.com/files/phantomjs-1.6.1-linux-x86_64-dynamic.tar.bz2 -O - | tar -xj; ln -s $(pwd)/phantomjs-1.6.1-linux-x86_64-dynamic/bin/phantomjs /usr/local/bin; git clone git://github.com/n1k0/casperjs.git; cd casperjs; git checkout tags/1.0.0-RC1; ln -sf `pwd`/bin/casperjs /usr/local/bin/casperjs; mkdir /tmp/public_html;

COPY browser.coffee /tmp/
CMD cd tmp; echo ${PASSWORD_LEVEL5} > /tmp/public_html/password.txt; while /bin/true; do casperjs browser.coffee http://level4:4567/; sleep 30; done
