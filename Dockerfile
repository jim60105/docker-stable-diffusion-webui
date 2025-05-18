# syntax=docker/dockerfile:1
ARG UID=1001
ARG VERSION=EDGE
ARG RELEASE=0

ARG CACHE_HOME=/.cache
ARG TORCH_HOME=${CACHE_HOME}/torch
ARG HF_HOME=${CACHE_HOME}/huggingface

# Skip requirements installation for final stage and will install them in the first startup.
# This reduce the image size to 1.27G but increase the first startup time.
ARG SKIP_REQUIREMENTS_INSTALL=

########################################
# Base stage
########################################
FROM docker.io/library/python:3.11-slim-bookworm AS base

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

# Install runtime/buildtime dependencies
RUN --mount=type=cache,id=apt-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=aptlists-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends \
    # Install Pillow dependencies explicitly
    # https://pillow.readthedocs.io/en/stable/installation/building-from-source.html
    libjpeg62-turbo-dev libwebp-dev zlib1g-dev \
    libgl1 libglib2.0-0 libgoogle-perftools-dev \
    git libglfw3-dev libgles2-mesa-dev pkg-config libcairo2 build-essential

# Install UV
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV UV_LINK_MODE=copy
ENV UV_PYTHON_DOWNLOADS=0
ENV UV_TORCH_BACKEND=cu128

########################################
# Build stage
########################################
FROM base AS prepare_build_empty

# An empty directory for final stage
RUN install -d /venv

FROM base AS prepare_build

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /source

ENV UV_PROJECT_ENVIRONMENT=/venv
ENV VIRTUAL_ENV=/venv

RUN --mount=type=cache,id=uv-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    uv venv --system-site-packages /venv && \
    uv pip install -U --force-reinstall setuptools==69.5.1 wheel

# Install big packages
# hadolint ignore=SC2102
RUN --mount=type=cache,id=uv-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    uv pip install \
    setuptools==69.5.1 \
    torch==2.7.0 torchvision \
    xformers==0.0.30 \
    numpy==1.26.2 \
    pillow==9.5.0

# Install requirements
RUN --mount=type=cache,id=uv-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/uv \
    --mount=source=stable-diffusion-webui/requirements_versions.txt,target=requirements.txt \
    uv pip install -r requirements.txt clip-anytorch hf_xet

# Select the build stage by the build argument
FROM prepare_build${SKIP_REQUIREMENTS_INSTALL:+_empty} AS build

########################################
# Final stage
########################################
FROM base AS final

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Fix missing libnvinfer7
RUN ln -s /usr/lib/x86_64-linux-gnu/libnvinfer.so /usr/lib/x86_64-linux-gnu/libnvinfer.so.7 && \
    ln -s /usr/lib/x86_64-linux-gnu/libnvinfer_plugin.so /usr/lib/x86_64-linux-gnu/libnvinfer_plugin.so.7

# Create user
ARG UID
RUN groupadd -g $UID $UID && \
    useradd -l -u $UID -g $UID -m -s /bin/sh -N $UID

ARG CACHE_HOME
ARG TORCH_HOME
ARG HF_HOME
ENV XDG_CACHE_HOME=${CACHE_HOME}
ENV TORCH_HOME=${TORCH_HOME}
ENV HF_HOME=${HF_HOME}

# Create directories with correct permissions
RUN install -d -m 775 -o $UID -g 0 ${CACHE_HOME} && \
    install -d -m 775 -o $UID -g 0 /licenses && \
    install -d -m 775 -o $UID -g 0 /data && \
    install -d -m 775 -o $UID -g 0 /data/scripts && \
    install -d -m 775 -o $UID -g 0 /app && \
    install -d -m 775 -o $UID -g 0 /app/repositories && \
    # For arbitrary uid support
    install -d -m 775 -o $UID -g 0 /.local && \
    install -d -m 775 -o $UID -g 0 /.config && \
    chown -R $UID:0 /home/$UID && chmod -R g=u /home/$UID

# curl for healthcheck
COPY --link --from=ghcr.io/tarampampam/curl:8.7.1 /bin/curl /usr/local/bin/

# ffmpeg
COPY --link --from=ghcr.io/jim60105/static-ffmpeg-upx:7.1.1 /ffmpeg /usr/local/bin/
COPY --link --from=ghcr.io/jim60105/static-ffmpeg-upx:7.1.1 /ffprobe /usr/local/bin/

# dumb-init
COPY --link --from=ghcr.io/jim60105/static-ffmpeg-upx:7.1.1 /dumb-init /usr/bin/

# Copy licenses (OpenShift Policy)
COPY --link --chown=$UID:0 --chmod=775 LICENSE /licenses/Dockerfile.LICENSE
COPY --link --chown=$UID:0 --chmod=775 stable-diffusion-webui/LICENSE.txt /licenses/stable-diffusion-webui.LICENSE.txt
COPY --link --chown=$UID:0 --chmod=775 stable-diffusion-webui/html/licenses.html /licenses/stable-diffusion-webui-borrowed-code.LICENSE.html

# Setup uv
ENV UV_PROJECT_ENVIRONMENT=/home/$UID/.local
ENV VIRTUAL_ENV=/home/$UID/.local
ENV UV_NO_CACHE=1
RUN uv venv --system-site-packages /home/$UID/.local

# Copy entrypoint
COPY --link --chown=$UID:0 --chmod=775 entrypoint.sh /entrypoint.sh

# Copy dependencies and code
COPY --link --chown=$UID:0 --chmod=775 --from=build /venv /home/$UID/.local
COPY --link --chown=$UID:0 --chmod=775 stable-diffusion-webui /app

ENV PATH="/app:/home/$UID/.local/bin${PATH:+:${PATH}}"
ENV PYTHONPATH="/app:/home/$UID/.local/lib/python3.11/site-packages"
ENV LD_PRELOAD=libtcmalloc.so

ENV GIT_CONFIG_COUNT=1
ENV GIT_CONFIG_KEY_0="safe.directory"
ENV GIT_CONFIG_VALUE_0="*"

WORKDIR /app

VOLUME [ "/data", "/tmp" ]

EXPOSE 7860

USER $UID

STOPSIGNAL SIGINT

HEALTHCHECK --interval=30s --timeout=2s --start-period=30s \
    CMD [ "curl", "--fail", "http://localhost:7860/" ]

# Use dumb-init as PID 1 to handle signals properly
ENTRYPOINT [ "dumb-init", "--", "/entrypoint.sh" ]

CMD [ "--xformers", "--api", "--allow-code" ]

ARG VERSION
ARG RELEASE
LABEL name="jim60105/docker-stable-diffusion-webui" \
    # Author for stable-diffusion-webui
    vendor="AUTOMATIC1111" \
    # Dockerfile maintainer
    maintainer="jim60105" \
    # Dockerfile source repository
    url="https://github.com/jim60105/docker-stable-diffusion-webui" \
    version=${VERSION} \
    # This should be a number, incremented with each change
    release=${RELEASE} \
    io.k8s.display-name="stable-diffusion-webui" \
    summary="Stable Diffusion web UI: A web interface for Stable Diffusion, implemented using Gradio library." \
    description="Stable Diffusion web UI: A web interface for Stable Diffusion, implemented using Gradio library. This is the docker image for AUTOMATIC1111's stable-diffusion-webui. For more information about this tool, please visit the following website: https://github.com/AUTOMATIC1111/stable-diffusion-webui."
