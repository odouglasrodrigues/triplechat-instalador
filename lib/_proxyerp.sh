#!/bin/bash
#
# functions for setting up app proxyerp

#######################################
# sets environment variable for proxyerp.
# Arguments:
#   None
#######################################
proxyerp_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (proxyerp)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # ensure idempotency
  api_url=$(echo "${api_url/https:\/\/}")
  api_url=${api_url%%/*}
  api_url=https://$api_url

sudo su - deploy << EOF
  cat <<[-]EOF > /home/deploy/${instancia_add}/proxyerp/.env

API_URL=${api_url}

PORT=${proxyerp_port}


[-]EOF
EOF

  sleep 2
}

#######################################
# installs node.js dependencies
# Arguments:
#   None
#######################################
proxyerp_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do proxyerp...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/proxyerp
  npm install --force
EOF

  sleep 2
}



#######################################
# updates frontend code
# Arguments:
#   None
#######################################
proxyerp_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o proxyerp...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${empresa_atualizar}
  pm2 stop ${empresa_atualizar}-proxyerp
  git pull
  cd /home/deploy/${empresa_atualizar}/proxyerp
  npm install
  pm2 start ${empresa_atualizar}-proxyerp
  pm2 save 
EOF

  sleep 2
}

#######################################
# starts proxyerp using pm2 in 
# production mode.
# Arguments:
#   None
#######################################
proxyerp_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando pm2 (proxyerp)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/proxyerp
  pm2 start src/server.js --name ${instancia_add}-proxyerp
EOF

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
proxyerp_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (proxyerp)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  proxyerp_hostname=$(echo "${proxyerp_url/https:\/\/}")

sudo su - root << EOF
cat > /etc/nginx/sites-available/${instancia_add}-proxyerp << 'END'
server {
  server_name $proxyerp_hostname;
  location / {
    proxy_pass http://127.0.0.1:${proxyerp_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -s /etc/nginx/sites-available/${instancia_add}-proxyerp /etc/nginx/sites-enabled
EOF

  sleep 2
}

proxyerp_certbot_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  proxyerp_domain=$(echo "${proxyerp_url/https:\/\/}")

  sudo su - root <<EOF
  certbot -m $deploy_email \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $proxyerp_domain

EOF

  sleep 2
}