FROM python:2.7-onbuild

EXPOSE 5000
WORKDIR /usr/src/app
CMD ./initialize_db.py ${PASSWORD_LEVEL8}; HOST=0.0.0.0 python wafflecopter.py

