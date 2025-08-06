ARG VERSION=2.9.0-b0
ARG pypi_index=https://dev.nla.gov.au/nexus/repository/pypi-proxy/simple
ARG docker_registry=container-registry.nla.gov.au/
FROM ${docker_registry}nla/ubi8-minimal-mirrored

USER root
RUN microdnf install -y python3.11-pip shadow-utils && microdnf clean all
RUN pip3.11 --no-cache-dir install --index-url ${pypi_index} pywb==${VERSION} gunicorn
RUN useradd -m pywb && mkdir /data

USER pywb
WORKDIR /data
EXPOSE 8080
VOLUME /data

CMD gunicorn -w 16 --limit-request-line 9000 --preload pywb.apps.wayback -b 0.0.0.0:8080
