FROM python:2.7-onbuild

EXPOSE 5000
WORKDIR /usr/src/app
CMD ./initialize_db.py ${LEVEL8_PASSWORD}; HOST=0.0.0.0 python wafflecopter.py

