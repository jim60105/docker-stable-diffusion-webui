# docker-stable-diffusion-webui

[![CodeFactor](https://www.codefactor.io/repository/github/jim60105/docker-stable-diffusion-webui/badge?style=for-the-badge)](https://www.codefactor.io/repository/github/jim60105/docker-stable-diffusion-webui) [![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/jim60105/docker-stable-diffusion-webui/scan.yml?label=IMAGE%20SCAN&style=for-the-badge)](https://github.com/jim60105/docker-stable-diffusion-webui/actions/workflows/scan.yml)

This is the docker image for [AUTOMATIC1111/Stable Diffusion web UI: A web interface for Stable Diffusion, implemented using Gradio library.](https://github.com/AUTOMATIC1111/stable-diffusion-webui) from the community.

Get the Dockerfile at [GitHub](https://github.com/jim60105/docker-stable-diffusion-webui), or pull the image from [ghcr.io](https://ghcr.io/jim60105/docker-stable-diffusion-webui) or [quay.io](https://quay.io/repository/jim60105/docker-stable-diffusion-webui?tab=tags).

## Usage Command

Mount the current directory as `/data` and run docker-stable-diffusion-webui with additional input arguments.  
The downloaded files will be saved to where you run the command.

```bash
docker run -it -v ".:/data" ghcr.io/jim60105/docker-stable-diffusion-webui [options] [url]
```

The `[options]`, `[url]` placeholder should be replaced with the options and arguments for docker-stable-diffusion-webui. Check the [docker-stable-diffusion-webui README](https://github.com/AUTOMATIC1111/stable-diffusion-webui?tab=readme-ov-file#usage) for more information.

You can find all available tags at [ghcr.io](https://github.com/jim60105/docker-stable-diffusion-webui/pkgs/container/docker-stable-diffusion-webui/versions?filters%5Bversion_type%5D=tagged) or [quay.io](https://quay.io/repository/jim60105/docker-stable-diffusion-webui?tab=tags).

### Build Command

> [!IMPORTANT]  
> Clone the Git repository recursively to include submodules:  
> `git clone --recursive https://github.com/jim60105/docker-stable-diffusion-webui.git`

> [!NOTE]  
> If you are using an earlier version of the docker client, it is necessary to [enable the BuildKit mode](https://docs.docker.com/build/buildkit/#getting-started) when building the image. This is because I used the `COPY --link` feature which enhances the build performance and was introduced in Buildx v0.8.  
> With the Docker Engine 23.0 and Docker Desktop 4.19, Buildx has become the default build client. So you won't have to worry about this when using the latest version.

```bash
docker build -f Dockerfile -t docker-stable-diffusion-webui:latest .
```

## LICENSE

> [!NOTE]  
> The main program, [AUTOMATIC1111/stable-diffusion-webui](https://github.com/AUTOMATIC1111/stable-diffusion-webui), is distributed under [AGPL-3.0 license](https://github.com/AUTOMATIC1111/stable-diffusion-webui/blob/master/LICENSE.txt).  
> Please consult their repository for access to the source code and licenses.  
> The following is the license for the Dockerfiles and CI workflows in this repository.

> [!CAUTION]
> An AGPLv3 licensed Dockerfile means that you _**MUST**_ **distribute the source code with the same license**, if you
>
> - Re-distribute the image. (You can simply point to this GitHub repository if you doesn't made any code changes.)
> - Distribute a image that uses code from this repository.
> - Or **distribute a image based on this image**. (`FROM ghcr.io/jim60105/docker-stable-diffusion-webui` in your Dockerfile)
>
> "Distribute" means to make the image available for other people to download, usually by pushing it to a public registry. If you are solely using it for your personal purposes, this has no impact on you.
>
> Please consult the [LICENSE](LICENSE) for more details.

<img src="https://github.com/jim60105/docker-stable-diffusion-webui/assets/16995691/a12d2791-048f-4b8d-87f8-96c88c9ef310" alt="agplv3" width="300" />

[GNU AFFERO GENERAL PUBLIC LICENSE Version 3](/LICENSE)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
