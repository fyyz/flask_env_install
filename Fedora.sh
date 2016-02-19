#!/bin/bash

echo
echo "#####################################################"
echo "#                                                   #"
echo "#      update system and install some software      #"
echo "#                                                   #"
echo "#####################################################"
echo

dnf install nginx uwsgi uwsgi-plugin-python3 mariadb-server python3-pip vim git -y
pip3 install --upgrade pip
pip3 install virtualenv
systemctl enable nginx
systemctl enable uwsgi
systemctl enable mariadb

firewall-cmd --add-service=http --permanent
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

echo
echo "#####################################################"
echo "#                                                   #"
echo "#             install flask environment             #"
echo "#                                                   #"
echo "#####################################################"
echo

mkdir -p /var/web/default.site
cd /var/web/default.site
virtualenv .venv
source .venv/bin/activate
pip3 install flask
deactivate

echo
echo "#####################################################"
echo "#                                                   #"
echo "#              edit some config files               #"
echo "#                                                   #"
echo "#####################################################"
echo

cat > /etc/nginx/conf.d/default.site.conf << EOF
server
{
        listen                  80;
        server_name             default.site;
        root                    /var/web/default.site;

        location /
        {
                include         uwsgi_params;
                uwsgi_pass      127.0.0.1:8000;
        }
}
EOF

cat > /etc/uwsgi.d/default.site.ini << EOF
[uwsgi]

socket = :8000
processes = 2

chdir = /var/web/default.site
home = /var/web/default.site/.venv
wsgi-file = /var/web/default.site/manager.py
callable = app
plugins = python3

master = true
vacuum = true
EOF

chown uwsgi:uwsgi /etc/uwsgi.d/*

cat > /var/web/default.site/manager.py << EOF
#!/usr/bin/env python3

from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
        return "<span style='color:red'>Flask is running...</span>\n"
EOF

reboot
