# syntax=docker/dockerfile:1
ARG UID=1001
ARG VERSION=EDGE
ARG RELEASE=0

ARG CACHE_HOME=/.cache
ARG TORCH_HOME=${CACHE_HOME}/torch
ARG HF_HOME=${CACHE_HOME}/huggingface

FROM python:3.10-slim as build

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /app

# Install under /root/.local
ENV PIP_USER="true"
ARG PIP_NO_WARN_SCRIPT_LOCATION=0
ARG PIP_ROOT_USER_ACTION="ignore"

# Install build dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends git curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install PyTorch
# hadolint ignore=SC2102
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    pip install -U --extra-index-url https://download.pytorch.org/whl/cu121 --extra-index-url https://pypi.nvidia.com \
    torch==2.1.2 torchvision==0.16.2 \
    xformers==0.0.23.post1 \
    pip setuptools wheel

# Install requirements
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    --mount=source=stable-diffusion-webui/requirements.txt,target=requirements.txt \
    pip install -r requirements.txt

# Replace pillow with pillow-simd (Only for x86)
ARG TARGETPLATFORM
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
    apt-get update && apt-get install -y --no-install-recommends zlib1g-dev libjpeg62-turbo-dev build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip uninstall -y pillow && \
    CC="cc -mavx2" pip install -U --force-reinstall pillow-simd; \
    fi

FROM python:3.10-slim as final

ARG UID
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

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

# ffmpeg
COPY --link --from=mwader/static-ffmpeg:6.1.1 /ffmpeg /usr/local/bin/
COPY --link --from=mwader/static-ffmpeg:6.1.1 /ffprobe /usr/local/bin/

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends libgl1 libglib2.0-0 libjpeg62 libgoogle-perftools-dev \
    git libglfw3-dev libgles2-mesa-dev pkg-config libcairo2 build-essential  \
    dumb-init && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Fix missing libnvinfer7
RUN ln -s /usr/lib/x86_64-linux-gnu/libnvinfer.so /usr/lib/x86_64-linux-gnu/libnvinfer.so.7 && \
    ln -s /usr/lib/x86_64-linux-gnu/libnvinfer_plugin.so /usr/lib/x86_64-linux-gnu/libnvinfer_plugin.so.7

# Create user
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
    install -d -m 775 -o $UID -g 0 /app/repositories

# Copy licenses (OpenShift Policy)
COPY --link --chmod=775 LICENSE /licenses/Dockerfile.LICENSE
COPY --link --chmod=775 stable-diffusion-webui/LICENSE.txt /licenses/stable-diffusion-webui.LICENSE.txt
COPY --link --chmod=775 stable-diffusion-webui/html/licenses.html /licenses/stable-diffusion-webui-borrowed-code.LICENSE.html

# Copy dependencies and code (and support arbitrary uid for OpenShift best practice)
COPY --link --chown=$UID:0 --chmod=775 --from=build /root/.local /home/$UID/.local
COPY --link --chown=$UID:0 --chmod=775 stable-diffusion-webui /app

ENV PATH="/home/$UID/.local/bin:$PATH"
ENV PYTHONPATH="${PYTHONPATH}:/home/$UID/.local/lib/python3.10/site-packages:/app"
ENV LD_PRELOAD=libtcmalloc.so

WORKDIR /data

VOLUME [ "/data" ]

EXPOSE 7860

USER $UID

STOPSIGNAL SIGINT

# Use dumb-init as PID 1 to handle signals properly
ENTRYPOINT [ "dumb-init", "--", "/bin/sh", "-c", "cp -rfs /data/scripts/ /app/scripts/ && python3 /app/launch.py --listen --port 7860 --data-dir /data --gradio-allowed-path /app \"$@\"" ]
