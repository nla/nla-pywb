ARG VERSION=2.9.0-b0
#ARG pypi_index=https://dev.nla.gov.au/nexus/repository/pypi-proxy/simple
ARG docker_registry=container-registry.prod.nla.gov.au/
FROM ${docker_registry}redhat/ubi10/ubi-minimal

USER root
RUN microdnf install -y python3-pip shadow-utils git-core && microdnf clean all
RUN pip install --upgrade pip && pip --no-cache-dir install gunicorn git+https://github.com/webrecorder/pywb.git@9de84beead449b1ad61c756e9c031b9e6cc645e6
RUN useradd -m pywb && mkdir /data

USER pywb
WORKDIR /data
EXPOSE 8080
VOLUME /data

CMD gunicorn -w 16 --limit-request-line 9000 --preload pywb.apps.wayback -b 0.0.0.0:8080
