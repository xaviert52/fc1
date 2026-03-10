FROM oryd/keto:v0.11.0

# 1. Cambiamos temporalmente a root
USER root

# 2. Creamos directorios
RUN mkdir -p /etc/config

# 3. Copiamos configuraciones
COPY files/keto.yml /etc/config/keto.yml
COPY files/namespaces.ts /etc/config/namespaces.ts

# 4. Asignamos propiedad
RUN chown -R ory:ory /etc/config

# 5. Volvemos al usuario seguro
USER ory

# Exponemos puertos
EXPOSE 4466 4467