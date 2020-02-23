if [ "$EUID" -ne 0 ]
  then echo "Missing Permissions\nPlease run `sudo setup.sh` instead"
  exit
fi

echo "Starting installation..."
echo "Please enter the server name (e.g. matrix.example.com)..."
echo "Installing dependencies - this may take a while..."

read servername
cd ~
sudo apt-get install build-essential python3-dev libffi-dev \
  python-pip python-setuptools sqlite3 \
  libssl-dev python-virtualenv libjpeg-dev libxslt1-dev
  
mkdir -p ~/synapse
virtualenv -p python3 ~/synapse/env
source ~/synapse/env/bin/activate
pip install --upgrade pip virtualenv six packaging appdirs
pip install --upgrade setuptools
pip install matrix-synapse
source ~/synapse/env/bin/activate
pip install -U matrix-synapse
cd ~/synapse

python -m synapse.app.homeserver \
  --server-name $servername \
  --config-path homeserver.yaml \
  --generate-config \
  --report-stats=no
  
echo "Setting up TLS..."

sudo apt-get update
sudo apt-get install software-properties-common
sudo add-apt-repository universe
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install certbot python-certbot-nginx

echo "Generating keys"
sudo certbot certonly --nginx -d $servername
echo "Done."

echo "Installing nginx..."
sudo apt-get install nginx
echo "Finished installation..."

echo "
Edit ~/synapse/homeserver.yaml and find the lines below
  - port: 8008
    tls: false
    bind_addresses: ['127.0.0.1']
    type: http
    x_forwarded: true
    
Set bind to ['127.0.0.1'] ONLY

Next, go to /etc/nginx/conf.d/matrix.conf and insert

server {
    listen 80;
	listen [::]:80;
    server_name $servername;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $servername;

    ssl on;
    ssl_certificate /etc/letsencrypt/live/$servername/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$servername/privkey.pem;

    location / {
        proxy_pass http://localhost:8008;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}

server {
    listen 8448 ssl default_server;
    listen [::]:8448 ssl default_server;
    server_name $servername;

    ssl on;
    ssl_certificate /etc/letsencrypt/live/$servername/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$servername/privkey.pem;
    location / {
        proxy_pass http://localhost:8008;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}

Then save...

Next, run:

sudo systemctl restart nginx
sudo systemctl enable nginx

Now start matrix:

cd ~/synapse
source env/bin/activate
synctl start

register_new_matrix_user -c homeserver.yaml http://localhost:8008

Fill in the details...
You should see a success message at the end.

Now go to $servername and check it's running
"
