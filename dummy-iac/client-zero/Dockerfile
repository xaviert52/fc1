FROM nginx:alpine

# 1. Limpiar defaults
RUN rm -rf /usr/share/nginx/html/*
RUN rm /etc/nginx/conf.d/default.conf

# 2. Copiar nuestra configuración robusta
COPY default.conf /etc/nginx/conf.d/default.conf

# 3. Copiar el Dashboard
COPY index.html /usr/share/nginx/html/index.html