ARG VERSION=2.10.0b1
ARG pypi_index=https://dev.nla.gov.au/nexus/repository/pypi-proxy/simple
ARG docker_registry=container-registry.prod.nla.gov.au/

# --------------------------
# Stage 1: fetch/unpack Ruffle
# --------------------------
FROM ${docker_registry}redhat/ubi9/ubi-minimal AS ruffle
ARG RUFFLE_VERSION=nightly-2025-11-04
ARG RUFFLE_URL=https://github.com/ruffle-rs/ruffle/releases/download/${RUFFLE_VERSION}/${RUFFLE_VERSION}-web-selfhosted.zip

RUN microdnf install -y --nodocs --setopt=install_weak_deps=0 \
      curl unzip ca-certificates \
    && microdnf clean all

RUN set -eux; \
    mkdir -p /out; \
    curl -fsSL -o /tmp/ruffle.zip "${RUFFLE_URL}"; \
    unzip -q /tmp/ruffle.zip -d /out; \
    rm -f /tmp/ruffle.zip


# --------------------------
# Stage 2: runtime image
# --------------------------
FROM ${docker_registry}redhat/ubi9/ubi-minimal

ARG VERSION
ARG pypi_index

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYWB_CONFIG_FILE=/etc/pywb/config.yaml

RUN microdnf install -y --nodocs --setopt=install_weak_deps=0 \
      python3.11 python3.11-pip shadow-utils ca-certificates \
    && microdnf clean all

RUN python3.11 -m pip install --index-url "${pypi_index}" \
      "pywb==${VERSION}" gunicorn

RUN useradd -m -u 10001 -s /sbin/nologin pywb
RUN mkdir -p /app/pywb /etc/pywb

COPY pywb_proxyfix.py /app/pywb/pywb_proxyfix.py
COPY awa/templates/ /app/pywb/templates/
COPY awa/static/ /app/pywb/static/
COPY rules-extra.yaml /tmp/rules-extra.yaml
COPY --from=ruffle /out /app/pywb/static/ruffle

# Build rules.yaml
RUN set -eux; \
    PYWB_RULES="$(python3.11 -c "import pywb, os; print(os.path.join(os.path.dirname(pywb.__file__), 'rules.yaml'))")"; \
    sed "/^rules:/ r /tmp/rules-extra.yaml" "$PYWB_RULES" > /app/pywb/rules.yaml; \
    rm -f /tmp/rules-extra.yaml

USER pywb
WORKDIR /app/pywb
EXPOSE 8080
CMD gunicorn -w 9 --limit-request-line 9000 --preload pywb_proxyfix -b 0.0.0.0:8080
