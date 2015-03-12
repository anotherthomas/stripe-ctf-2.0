#!/usr/bin/env python2
import uuid

for i in range(1,8):
    print ("export PASSWORD_LEVEL{}={}".format(i, uuid.uuid4()))
print("export PASSWORD_FINAL=123443210987")


