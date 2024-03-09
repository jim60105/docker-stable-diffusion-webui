# docker-stable-diffusion-webui

[![CodeFactor](https://www.codefactor.io/repository/github/jim60105/docker-stable-diffusion-webui/badge?style=for-the-badge)](https://www.codefactor.io/repository/github/jim60105/docker-stable-diffusion-webui) ![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/jim60105/docker-stable-diffusion-webui/docker_publish.yml?label=DOCKER%20BUILD&style=for-the-badge) ![GitHub last commit (branch)](https://img.shields.io/github/last-commit/jim60105/docker-stable-diffusion-webui/master?label=DATE&style=for-the-badge)

<section align="center">
  <p>
    <a href="https://github.com/jim60105/docker-stable-diffusion-webui/blob/master/README.zh.md">
        Chinese
    </a>
    <span>| English</span>
  </p>
</section>

Yet another docker image for [AUTOMATIC1111/Stable Diffusion web UI: A web interface for Stable Diffusion, implemented using Gradio library.](https://github.com/AUTOMATIC1111/stable-diffusion-webui) from the community.

The main objective behind the design of this image is to keep it ***small and simple*** and conforms to Dockerfile best practices. Successfully controlled the size to around **10GB**, saving approximately **1/3** of the capacity compared to other existing repos.

This makes it possible for me to build images seamlessly using the [CI workflow](https://github.com/jim60105/docker-stable-diffusion-webui/actions/workflows/docker_publish.yml) on GitHub free runner. You can pull the [pre-built images](https://ghcr.io/jim60105/stable-diffusion-webui) from ghcr, saving time instead of constructing them yourself!

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

## 🖥️ How to use this project

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
Output images will be stored at directory `./data/outputs` for default.

## 🛠️ Build instructions

> [!IMPORTANT]  
> Clone the Git repository ***recursively*** to include submodules:  
> `git clone --recursive https://github.com/jim60105/docker-stable-diffusion-webui.git`

Uncomment [the `# build: .` line in `docker-compose.yml`](https://github.com/jim60105/docker-stable-diffusion-webui/blob/bc23c16b99034147c74ab901ae7f605d5d9fc21c/docker-compose.yml#L7) and build the image with the following command.

```bash
docker compose up -d --build
```

> [!NOTE]  
> If you are using an earlier version of the docker client, it is necessary to [enable the BuildKit mode](https://docs.docker.com/build/buildkit/#getting-started) when building the image. This is because I used the `COPY --link` feature which enhances the build performance and was introduced in Buildx v0.8.  
> With the Docker Engine 23.0 and Docker Desktop 4.19, Buildx has become the default build client. So you won't have to worry about this when using the latest version.

## 🔄 Migrate from existing settings

1. Edit your existing `config.json` and modify all paths to be the relative path (not a path starting with / or C:), for example:

    ```json
    {
        "outdir_samples": "",
        "outdir_txt2img_samples": "outputs/txt2img-images",
        "outdir_img2img_samples": "outputs/img2img-images",
        "outdir_extras_samples": "outputs/extras-images",
        "outdir_grids": "",
        "outdir_txt2img_grids": "outputs/txt2img-grids",
        "outdir_img2img_grids": "outputs/img2img-grids",
        "outdir_save": "log/images",
        "outdir_init_images": "outputs/init-images",
    }
    ```

2. Place `config.json` under the `data` directory.
3. Put the models and other existing data into corresponding folders under `data`.
4. ***Please correct the permissions of all the files in the `data` folder*** if these files come from a Linux file system (you previously used WSL or a Linux machine):

    ```sh
    chown -R 1001:0 ./data && chmod -R 775 ./data
    ```

> [!NOTE]  
> This instruction modifies the owner group of the `data` directory to ***0 (root group)*** and grants ***write permission to the group***. This aligns with OpenShift best practices by ***supporting arbitrary uid***.

> [!WARNING]  
> This image follows best practices by ***using non-root user*** and ***restricting write permissions to non-essential folders***. You may not be able to store files outside the `/data` path unless appropriate modifications have been made.

## 📝 LICENSE

<img src="https://github.com/jim60105/docker-stable-diffusion-webui/assets/16995691/a12d2791-048f-4b8d-87f8-96c88c9ef310" alt="agplv3" width="300" />

[GNU AFFERO GENERAL PUBLIC LICENSE Version 3](/LICENSE)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

> [!NOTE]  
> The main program, [AUTOMATIC1111/stable-diffusion-webui](https://github.com/AUTOMATIC1111/stable-diffusion-webui), is distributed under [AGPL-3.0 license](https://github.com/AUTOMATIC1111/stable-diffusion-webui/blob/master/LICENSE.txt).  
> Please consult their repository for access to the source code and licenses.  
> The following is the license for the Dockerfiles and CI workflows in this repository.

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
