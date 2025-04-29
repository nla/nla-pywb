
ARG docker_registry=nla-registry-quay-quay.apps.dev-containers.nla.gov.au/
FROM ${docker_registry}nla/ubi9-minimal

FROM container-registry.nla.gov.au/nla/ubi9-minimal
RUN microdnf install -y python3.11-pip && microdnf clean all
RUN pip3.11 --no-cache-dir install --index-url https://dev.nla.gov.au/nexus/repository/pypi-proxy/simple pywb==2.9.0b0 gunicorn
RUN adduser pywb && mkdir /data
USER pywb
WORKDIR /data

EXPOSE 8080
VOLUME /data

CMD gunicorn -w 16 pywb.apps.wayback -b 0.0.0.0:8080