#!/usr/bin/env python2
import uuid

for i in range(1,8):
    print ("PASSWORD_LEVEL{}={}".format(i, uuid.uuid4()))
print("PASSWORD_FINAL=123443210987")


