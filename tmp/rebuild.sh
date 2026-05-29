#!/bin/bash
export PATH="/home/admin/.nvm/versions/node/v20.20.2/bin:$PATH"
cd /opt/changji-cloud/api
npm run build
pm2 restart changji-api
