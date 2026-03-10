FROM oryd/kratos:v1.2.0

# 1. Cambiamos temporalmente a root para manipular el sistema de archivos
USER root

# 2. Creamos directorios
RUN mkdir -p /etc/config/hooks

# 3. Copiamos configuraciones
COPY files/kratos.yaml /etc/config/kratos.yaml
COPY files/identity.schema.json /etc/config/identity.schema.json
COPY files/hooks/ /etc/config/hooks/

# 4. Aseguramos que el usuario 'ory' sea el dueño de la configuración
RUN chown -R ory:ory /etc/config

# 5. Volvemos al usuario seguro por defecto para la ejecución
USER ory

# Exponemos puertos
EXPOSE 4433 4434