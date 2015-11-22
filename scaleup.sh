docker -H 10.62.41.134:2376 run -d -p 3000:3000 --restart=always --entrypoint=/usr/bin/node genchilu/helloweb /opt/helloweb/app.js
bash /git/hademo/updateConsul.sh
