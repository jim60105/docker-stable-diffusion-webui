# docker-stable-diffusion-webui

<section align="center">
  <img src="https://github.com/jim60105/docker-stable-diffusion-webui/assets/16995691/de246026-c7b5-474e-bade-89905aa5b010"/>
  <p>
    <a href="https://github.com/jim60105/docker-stable-diffusion-webui/blob/master/README.zh.md">
        中文
    </a>
    <span>| English</span>
  </p>
</section>

[![CodeFactor](https://www.codefactor.io/repository/github/jim60105/docker-stable-diffusion-webui/badge)](https://www.codefactor.io/repository/github/jim60105/docker-stable-diffusion-webui) [![DeepSource](https://app.deepsource.com/gh/jim60105/docker-stable-diffusion-webui.svg/?label=active+issues&show_trend=false&token=1VuQPvmy4vSxN83egASazDLW)](https://app.deepsource.com/gh/jim60105/docker-stable-diffusion-webui/) ![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/jim60105/docker-stable-diffusion-webui/docker_publish.yml?label=DOCKER%20BUILD)

Yet another docker image for [AUTOMATIC1111/Stable Diffusion web UI: A web interface for Stable Diffusion, implemented using Gradio library.](https://github.com/AUTOMATIC1111/stable-diffusion-webui) from the community.

The main goal of designing this image is to keep it ***small and follow best practices***. Successfully controlled the size to around **10GB**, saving approximately **1/3** of the capacity compared to other existing solutions.

This makes it possible for me to consistently automate building images by using the [CI workflow](https://github.com/jim60105/docker-stable-diffusion-webui/actions/workflows/docker_publish.yml) on GitHub free runner. You can pull the [pre-built images](https://ghcr.io/jim60105/stable-diffusion-webui) from ghcr, saving time instead of constructing them yourself!

Get the Dockerfile at [GitHub](https://github.com/jim60105/docker-stable-diffusion-webui), or pull the image from [ghcr.io](https://ghcr.io/jim60105/stable-diffusion-webui).

## 🚀 Get your Docker ready for GPU support

### Windows

Once you have installed [**Docker Desktop**](https://www.docker.com/products/docker-desktop/), [**CUDA Toolkit**](https://developer.nvidia.com/cuda-downloads), [**NVIDIA Windows Driver**](https://www.nvidia.com.tw/Download/index.aspx), and ensured that your Docker is running with [**WSL2**](https://docs.docker.com/desktop/wsl/#turn-on-docker-desktop-wsl-2), you are ready to go.

Here is the official documentation for further reference.  
<https://docs.nvidia.com/cuda/wsl-user-guide/index.html#nvidia-compute-software-support-on-wsl-2>
<https://docs.docker.com/desktop/wsl/use-wsl/#gpu-support>

### Linux, OSX

Install an NVIDIA GPU Driver if you do not already have one installed.  
<https://docs.nvidia.com/datacenter/tesla/tesla-installation-notes/index.html>

Install the NVIDIA Container Toolkit with this guide.  
<https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html>

## 🖥️ Run the project

1. Clone the repository to your local machine and navigate to the directory.

    ```bash
    git clone https://github.com/jim60105/docker-stable-diffusion-webui.git
    cd docker-stable-diffusion-webui
    ```

2. Compose up the service and wait for startup loading.

    ```bash
    docker compose up -d
    ```

3. Access the web UI at [http://localhost:7860](http://localhost:7860).  
    (Browser won't be started automatically!)

Models and settings will be stored at directory `./data`.  
Output images will be stored at directory `./data/output` for default.

## 🔀 Switch between different versions/branches

### Docker Image Tags

The docker image tag corresponds to the non-RC version number from `v1.6.1` and its `dev` branch in [AUTOMATIC1111/stable-diffusion-webui](https://github.com/AUTOMATIC1111/stable-diffusion-webui). The `dev` image rebuilds weekly to keep up with the latest changes.

| Image tag    | Code version                                                                                                                |
|--------------|-----------------------------------------------------------------------------------------------------------------------------|
| dev (latest) | [AUTOMATIC1111/stable-diffusion-webui dev branch](https://github.com/AUTOMATIC1111/stable-diffusion-webui/tree/dev)         |
| v1.6.1       | [AUTOMATIC1111/stable-diffusion-webui v1.6.1 tag](https://github.com/AUTOMATIC1111/stable-diffusion-webui/tree/v1.6.1)      |
| v1.7.0       | [AUTOMATIC1111/stable-diffusion-webui v1.7.0 tag](https://github.com/AUTOMATIC1111/stable-diffusion-webui/tree/v1.7.0)      |
| v1.8.0       | [AUTOMATIC1111/stable-diffusion-webui v1.8.0 tag](https://github.com/AUTOMATIC1111/stable-diffusion-webui/tree/v1.8.0)      |
| v1.9.3       | [AUTOMATIC1111/stable-diffusion-webui v1.9.3 tag](https://github.com/AUTOMATIC1111/stable-diffusion-webui/tree/v1.9.3)      |

You can check all available tags at [ghcr.io](https://github.com/jim60105/docker-stable-diffusion-webui/pkgs/container/stable-diffusion-webui).

### Specify the image in the docker-compose.yml

Change the tag after `ghcr.io/jim60105/stable-diffusion-webui` in the [`image` field of `docker-compose.yml`](https://github.com/jim60105/docker-stable-diffusion-webui/blob/75e84ec718572b793a8cf20f198a2ddd066a7bc2/docker-compose.yml#L4) to your desired version.

For example, if you want to use the `v1.8.0` version, you should modify it to:

```yml
image: ghcr.io/jim60105/stable-diffusion-webui:v1.8.0
```

Then restart the service using the following command:

```bash
docker compose down && docker compose up -d
```

### Use the forge version

There's a special version `forge` which is based on the `main` branch of [lllyasviel/stable-diffusion-webui-forge](https://github.com/lllyasviel/stable-diffusion-webui-forge). The `forge` image rebuilds weekly to keep up with the latest changes.

| Image tag | Code version                                                                                                                |
|-----------|-----------------------------------------------------------------------------------------------------------------------------|
| forge     | [lllyasviel/stable-diffusion-webui-forge main branch](https://github.com/lllyasviel/stable-diffusion-webui-forge/tree/main) |

You can use it with the `docker-compose.forge.yml` file.

```bash
docker compose -f docker-compose.forge.yml up -d
```

> [!NOTE]  
> Notice that they used the same port `7860`, so you can't run them at the same time.  
> Please stop the running service before starting another one.  
> ![image](https://github.com/jim60105/docker-stable-diffusion-webui/assets/16995691/f7aecb66-5416-4806-90d8-b6c6be6c1bad)

### `runtime-deps` images

> [!NOTE]  
> You can build it locally with Docker build arguments: `SKIP_REQUIREMENTS_INSTALL=true`

Some recent versions have `runtime-deps` images that you can use, like `v1.8.0-runtime-deps`, `v1.9.3-runtime-deps`, and `forge-runtime-deps`.

These images does not include pre-installed pip requirements.  
Instead, the requirements will be installed during the image first launch.

The initial startup process may take some time, but this leads to a smaller image size of **1.3GB**!

Consider using them if they fit your needs.

> [!TIP]  
> This image can be used in a tricky way: to preserve and reuse the `/home/1001/.local` directory through a volume.  
> It's like sharing the same environment across different Python applications.  
> I wouldn't recommend this approach for regular users... you must be fully aware of what you're doing.  
> As for power users, please refer to [this commit](https://github.com/jim60105/docker-stable-diffusion-webui/commit/c46ddadee56c0afe0fc71cf1157ad4a6f3eefe65) for more information.  
> Thanks to the community for coming up with this amazing idea!😆

## 🛠️ Build instructions

> [!IMPORTANT]  
> Clone the Git repository ***recursively*** to include submodules:  
> `git clone --recursive https://github.com/jim60105/docker-stable-diffusion-webui.git`

```bash
docker compose up -d --build
```

> [!NOTE]  
> If you are using an earlier version of the docker client, it is necessary to [enable the BuildKit mode](https://docs.docker.com/build/buildkit/#getting-started) when building the image. This is because I used the `COPY --link` feature which enhances the build performance and was introduced in Buildx v0.8.  
> With the Docker Engine 23.0 and Docker Desktop 4.19, Buildx has become the default build client. So you won't have to worry about this when using the latest version.

## 🔄 Migrate from existing settings

1. Edit your existing `config.json` and modify all paths to be under `/data`, for example:

    ```json
    {
        "outdir_samples": "",
        "outdir_txt2img_samples": "/data/output/txt2img-images",
        "outdir_img2img_samples": "/data/output/img2img-images",
        "outdir_extras_samples": "/data/output/extras-images",
        "outdir_grids": "",
        "outdir_txt2img_grids": "/data/output/txt2img-grids",
        "outdir_img2img_grids": "/data/output/img2img-grids",
        "outdir_save": "/data/log/images",
        "outdir_init_images": "/data/output/init-images",
    }
    ```

2. Place `config.json` under the `data` directory.
3. Put the models and other existing data into corresponding folders under `data`.
4. ***Please correct the permissions of all the files in the `data` folder***:

    ```sh
    docker run -v ".:/app" -it busybox sh -c "chown -R 1001:0 /app/data && chmod -R 775 /app/data"
    ```

> [!NOTE]  
> This instruction uses busybox to change the owner group of the `data` directory to ***0 (root group)*** and grants ***write permission to the group***. This aligns with OpenShift best practices by ***supporting arbitrary uid***.

> [!WARNING]  
> This image follows best practices by ***using non-root user*** and ***restricting write permissions to non-essential folders***. You may not be able to store files outside the `/data` path unless appropriate modifications have been made.

## 📝 LICENSE

> [!NOTE]  
> The main program, [AUTOMATIC1111/stable-diffusion-webui](https://github.com/AUTOMATIC1111/stable-diffusion-webui), is distributed under [AGPL-3.0 license](https://github.com/AUTOMATIC1111/stable-diffusion-webui/blob/master/LICENSE.txt).  
> Please consult their repository for access to the source code and licenses.  
> The following is the license for the Dockerfiles and CI workflows in this repository.

<img src="https://github.com/jim60105/docker-stable-diffusion-webui/assets/16995691/a12d2791-048f-4b8d-87f8-96c88c9ef310" alt="agplv3" width="300" />

[GNU AFFERO GENERAL PUBLIC LICENSE Version 3](/LICENSE)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

> [!CAUTION]  
> An AGPLv3 licensed Dockerfile means that you ***MUST*** **distribute the source code with the same license**, if you
>
> - Re-distribute the image. (You can simply point to this GitHub repository if you doesn't made any code changes.)
> - Distribute a image that uses code from this repository.
> - Or **distribute a image based on this image**. (`FROM ghcr.io/jim60105/stable-diffusion-webui` in your Dockerfile)
>
> "Distribute" means to make the image available for other people to download, usually by pushing it to a public registry. If you are solely using it for your personal purposes, this has no impact on you.
>
> Please consult the [LICENSE](LICENSE) for more details.
