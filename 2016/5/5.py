import hashlib

myinput = "reyedfim"
password = list('--------')
password2 = list('--------')
pos = 0
x = 0
while 1:
    m = hashlib.md5()
    name = "%s%d" % (myinput, x)
    m.update(name)
    kalle = m.hexdigest()
    if kalle[:5] == '00000':
        if pos <= 7:
            password[pos] = kalle[5]
        kallenum = int(kalle[5], 16)
        if kallenum in range(0,8):
            if password2[kallenum] == "-":
                password2[kallenum] = kalle[6]
        if '-' not in password2:
            break
        pos = pos + 1
    x = x + 1

print("Password: " + "".join(password))
print("Password2: " + "".join(password2))
