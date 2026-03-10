FROM apache/apisix:3.13.0-debian

USER root

COPY config.yaml /usr/local/apisix/conf/config.yaml

RUN rm -f /usr/local/apisix/conf/config-default.yaml \
 && chown 636:636 /usr/local/apisix/conf/config.yaml \
 && chmod 644 /usr/local/apisix/conf/config.yaml

USER 636

ENTRYPOINT ["apisix", "start", "-c", "/usr/local/apisix/conf/config.yaml"]