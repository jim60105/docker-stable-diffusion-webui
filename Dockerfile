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
FROM python:3.10-slim as base

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

ENV PIP_USER="true"

# Install runtime/buildtime dependencies
RUN --mount=type=cache,id=apt-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=aptlists-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends \
    # Install Pillow dependencies explicitly
    # https://pillow.readthedocs.io/en/stable/installation/building-from-source.html
    libjpeg62-turbo-dev libwebp-dev zlib1g-dev \
    libgl1 libglib2.0-0 libgoogle-perftools-dev \
    git libglfw3-dev libgles2-mesa-dev pkg-config libcairo2 build-essential \
    dumb-init

########################################
# Build stage
########################################
FROM base as prepare_build_empty

# An empty directory for final stage
RUN install -d /root/.local

FROM base as prepare_build

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /source

# Install under /root/.local
ARG PIP_NO_WARN_SCRIPT_LOCATION=0
ARG PIP_ROOT_USER_ACTION="ignore"
ARG PIP_NO_COMPILE="true"
ARG PIP_DISABLE_PIP_VERSION_CHECK="true"

# Install big packages
# hadolint ignore=SC2102
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    pip install -U --force-reinstall pip setuptools wheel && \
    pip install -U --extra-index-url https://download.pytorch.org/whl/cu121 --extra-index-url https://pypi.nvidia.com \
    # `torch` (3.6G) and the underlying package `triton` (276M), `torchvision` is small but install together
    torch==2.1.2 torchvision==0.16.2 \
    # `xformers` (471M)
    xformers==0.0.23.post1

# Install requirements
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    --mount=source=stable-diffusion-webui/requirements_versions.txt,target=requirements.txt \
    pip install -r requirements.txt clip-anytorch

# Replace pillow with pillow-simd (Only for x86)
ARG TARGETPLATFORM
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
    # # WebUI actually installed it back whenever it launches
    # pip uninstall -y pillow && \
    CC="cc -mavx2" pip install -U --force-reinstall pillow-simd; \
    fi

# Cleanup
RUN find "/root/.local" -name '*.pyc' -print0 | xargs -0 rm -f || true ; \
    find "/root/.local" -type d -name '__pycache__' -print0 | xargs -0 rm -rf || true ;

# Select the build stage by the build argument
FROM prepare_build${SKIP_REQUIREMENTS_INSTALL:+_empty} as build

########################################
# Final stage
########################################
FROM base as final

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

# ffmpeg
COPY --link --from=mwader/static-ffmpeg:7.0-1 /ffmpeg /usr/local/bin/
COPY --link --from=mwader/static-ffmpeg:7.0-1 /ffprobe /usr/local/bin/

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

# Copy licenses (OpenShift Policy)
COPY --link --chown=$UID:0 --chmod=775 LICENSE /licenses/Dockerfile.LICENSE
COPY --link --chown=$UID:0 --chmod=775 stable-diffusion-webui/LICENSE.txt /licenses/stable-diffusion-webui.LICENSE.txt
COPY --link --chown=$UID:0 --chmod=775 stable-diffusion-webui/html/licenses.html /licenses/stable-diffusion-webui-borrowed-code.LICENSE.html

# Make the entrypoint
#!The delimiter "EOF" is quoted to prevent the here-document from being expanded.
# https://www.gnu.org/software/bash/manual/html_node/Redirections.html#Here-Documents
COPY --link --chown=$UID:0 --chmod=775 <<"EOF" /entrypoint.sh
#!/bin/sh

# Copy scripts to /app/scripts
cp -rfs /data/scripts/. /app/scripts/

# Install requirements if no torch
if [ -z "$(pip show torch 2>/dev/null | grep Name)" ]; then \
    echo "Installing requirements... (This will only run once and might take some time)"
    # These versions are fixed in code
    # https://github.com/AUTOMATIC1111/stable-diffusion-webui/blob/1c0a0c4c26f78c32095ebc7f8af82f5c04fca8c0/modules/errors.py#L110
    pip install -U --force-reinstall pip setuptools wheel && \
    pip install -U \
        --extra-index-url https://download.pytorch.org/whl/cu121 \
        --extra-index-url https://pypi.nvidia.com \
        -r requirements_versions.txt \
        torch==2.1.2 torchvision==0.16.2 xformers==0.0.23.post1 && \
    pip cache purge

    # Replace pillow with pillow-simd (Only for x86_64)
    # https://github.com/uploadcare/pillow-simd#why-simd
    if [ $(uname -m) = "x86_64" ]; then \
        # # WebUI actually installed it back whenever it launches
        # pip uninstall -y pillow && \
        CC="cc -mavx2" pip install -U --force-reinstall pillow-simd
    fi
fi

echo "Starting WebUI with arguments: $@"
python3 /app/launch.py --listen --port 7860 --data-dir /data "$@"
EOF

# Copy dependencies and code
ARG UID
ARG SKIP_REQUIREMENTS_INSTALL
COPY --link --chown=$UID:0 --chmod=775 --from=build /root/.local /home/$UID/.local
COPY --link --chown=$UID:0 --chmod=775 stable-diffusion-webui /app

ENV PATH="/app:/home/$UID/.local/bin:$PATH"
ENV PYTHONPATH="/app:/home/$UID/.local/lib/python3.10/site-packages:$PYTHONPATH"
ENV LD_PRELOAD=libtcmalloc.so

WORKDIR /app

VOLUME [ "/data", "/tmp" ]

EXPOSE 7860

USER $UID

STOPSIGNAL SIGINT

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
