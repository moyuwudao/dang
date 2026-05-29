#!/bin/bash
export PATH="/home/admin/.nvm/versions/node/v20.20.2/bin:$PATH"
cd /home/admin/dang/admin
npm run build
rm -rf /var/www/html/admin/*
cp -r out/* /var/www/html/admin/
