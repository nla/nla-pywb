# Build with: podman build . -t pywb
ARG VERSION=2.10.0b1
ARG pypi_index=https://dev.nla.gov.au/nexus/repository/pypi-proxy/simple
ARG docker_registry=container-registry.prod.nla.gov.au/
FROM ${docker_registry}redhat/ubi9/ubi-minimal

ARG VERSION
ARG pypi_index

USER root
RUN microdnf install -y python3.11-pip shadow-utils unzip && microdnf clean all
RUN pip3.11 --no-cache-dir install --index-url ${pypi_index} pywb==${VERSION} gunicorn
RUN useradd -m pywb && mkdir /data && chown pywb:pywb /data

# Install Ruffle to a temporary location first to keep the download cached
RUN mkdir -p /tmp/ruffle && \
    curl -sSfLo /tmp/ruffle.zip https://github.com/ruffle-rs/ruffle/releases/download/nightly-2025-11-04/ruffle-nightly-2025_11_04-web-selfhosted.zip && \
    unzip -d /tmp/ruffle /tmp/ruffle.zip && \
    rm /tmp/ruffle.zip

COPY --chown=pywb:pywb awa /data/awa
COPY --chown=pywb:pywb pywb_proxyfix.py /data/awa/pywb_proxyfix.py
COPY rules-extra.yaml /tmp/rules-extra.yaml

# Move Ruffle into the static directory and setup rules.yaml
RUN mkdir -p /data/awa/static/ruffle && \
    cp -r /tmp/ruffle/* /data/awa/static/ruffle/ && \
    chown -R pywb:pywb /data/awa/static/ruffle && \
    rm -rf /tmp/ruffle && \
    PYWB_RULES=$(python3.11 -c "import pywb; import os; print(os.path.join(os.path.dirname(pywb.__file__), 'rules.yaml'))") && \
    sed "/^rules:/ r /tmp/rules-extra.yaml" "$PYWB_RULES" > /data/awa/rules.yaml && \
    chown pywb:pywb /data/awa/rules.yaml && \
    rm /tmp/rules-extra.yaml

USER pywb
WORKDIR /data/awa
EXPOSE 8080

CMD gunicorn -w 9 --limit-request-line 9000 --preload pywb_proxyfix -b 0.0.0.0:8080
