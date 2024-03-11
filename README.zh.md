# docker-stable-diffusion-webui

<section align="center">
  <img src="https://github.com/jim60105/docker-stable-diffusion-webui/assets/16995691/de246026-c7b5-474e-bade-89905aa5b010"/>
  <p>
    <span>中文</span> |
    <a href="https://github.com/jim60105/docker-stable-diffusion-webui/blob/master/README.md">
      English
    </a>
  </p>
</section>

![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/jim60105/docker-stable-diffusion-webui/docker_publish.yml?label=DOCKER%20BUILD&style=for-the-badge) ![GitHub last commit (branch)](https://img.shields.io/github/last-commit/jim60105/docker-stable-diffusion-webui/master?label=DATE&style=for-the-badge)

又一個來自社群的 [AUTOMATIC1111/Stable Diffusion web UI](https://github.com/AUTOMATIC1111/stable-diffusion-webui) Docker 映像。

這個映像的主要設計理念是保持 ***小巧而簡單***，並符合 Dockerfile 最佳實踐。成功地將大小控制在約 **10 GB** 左右，相比其他現有的儲存庫節省了大約 **1/3** 的容量。

這個尺寸使我能夠在 GitHub free runner 上 [CI 建置](https://github.com/jim60105/docker-stable-diffusion-webui/actions/workflows/docker_publish.yml) docker 映像。你可以從 ghcr 上拉取我[預先建置的映像](https://ghcr.io/jim60105/stable-diffusion-webui)，而不必自己在本地建置以節省時間！

請由 [GitHub](https://github.com/jim60105/docker-stable-diffusion-webui) 取得 Dockerfile 或者從 [ghcr.io](https://ghcr.io/jim60105/stable-diffusion-webui) 拉取映像。

## 🚀 準備好讓你的 Docker 支援 GPU

### Windows

只要完成安裝 [**Docker Desktop**](https://www.docker.com/products/docker-desktop/)、[**CUDA Toolkit**](https://developer.nvidia.com/cuda-downloads)、[**NVIDIA Windows Driver**](https://www.nvidia.com.tw/Download/index.aspx)，並確保 Docker 是使用 [**WSL2**](https://docs.docker.com/desktop/wsl/#turn-on-docker-desktop-wsl-2) 運行，那麼你就準備好了。

以下官方文件提供參考  
[https://docs.nvidia.com/cuda/wsl-user-guide/index.html#nvidia-compute-software-support-on-wsl-2](https://docs.nvidia.com/cuda/wsl-user-guide/index.html#nvidia-compute-software-support-on-wsl-2)
[https://docs.docker.com/desktop/wsl/use-wsl/#gpu-support](https://docs.docker.com/desktop/wsl/use-wsl/#gpu-support)

### Linux, OSX

請安裝 NVIDIA GPU 驅動程式  
[https://docs.nvidia.com/datacenter/tesla/tesla-installation-notes/index.html](https://docs.nvidia.com/datacenter/tesla/tesla-installation-notes/index.html)

並按照此指南安裝 NVIDIA Container Toolkit  
[https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

## 🖥️ 如何使用這個專案

1. 將儲存庫 clone 到本地並導航到該目錄。

   ```bash
   git clone https://github.com/jim60105/docker-stable-diffusion-webui.git
   cd docker-stable-diffusion-webui
   ```

2. 啟動服務並等待載入。

   ```bash
   docker compose up -d
   ```

3. 在 [http://localhost:7860](http://localhost:7860) 訪問 Web UI。
   (瀏覽器不會自動啟動！)

模型和設置將被儲存在目錄 `./data`  
在預設情況下，輸出的圖片將儲存在 `./data/outputs`

## 🛠️ 建置指南

> [!IMPORTANT]  
> Git clone 儲存庫時使用 ***--recursive*** 來包含子模組：  
> `git clone --recursive https://github.com/jim60105/docker-stable-diffusion-webui.git`

取消註解 [`docker-compose.yml` 中的 `# build: .`](https://github.com/jim60105/docker-stable-diffusion-webui/blob/bc23c16b99034147c74ab901ae7f605d5d9fc21c/docker-compose.yml#L7)，然後使用以下指令建置映像。

```bash
docker compose up -d --build
```

> [!NOTE]
> 若你使用舊版的 Docker 客戶端，建議在建置映像時[啟用 BuildKit 模式](https://docs.docker.com/build/buildkit/#getting-started)。這是因為我使用了 `COPY --link` 功能，該功能在 Buildx v0.8 中被導入並可增強建置效能。  
> 隨著 Docker Engine 23.0 和 Docker Desktop 4.19 的推出，Buildx 已成為預設的建置客戶端。因此，在使用最新版本時不必擔心這個問題喔！

## 🔄 從現有的設定檔遷移

1. 編輯你現有的 `config.json`，將所有路徑修改為相對路徑(不是以 / 或 C: 開頭的路徑)，舉例來說：

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

2. 將 `config.json` 放置在 `data` 目錄下。
3. 將模型和其他現有資料放入 `data` 目錄下相應的資料夾中。
4. ***若這些文件來自於 Linux 系統(你之前使用 WSL 或 Linux)，請修正 `data` 資料夾中所有文件的權限。***

   ```sh
   chown -R 1001:0 ./data && chmod -R 775 ./data
   ```

> [!NOTE]  
> 這個指令修改了 `data` 目錄的擁有者群組為 ***0(root group)***，並授予了 ***群組寫入權限***。這符合 OpenShift 最佳實踐的 ***支援以任意 uid 運行***。

> [!WARNING]  
> 這個映像遵循最佳實踐，***使用非 root 用戶運行*** 並 ***限制非必要路徑的寫入權限***。除非進行了適當的修改，否則你可能無法將文件儲存在 `/data` 路徑之外。

## 📝 LICENSE

<img src="https://github.com/jim60105/docker-stable-diffusion-webui/assets/16995691/a12d2791-048f-4b8d-87f8-96c88c9ef310" alt="agplv3" width="300" />

[GNU AFFERO GENERAL PUBLIC LICENSE Version 3](/LICENSE)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program. If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).

> [!NOTE]  
> 主要程式 [AUTOMATIC1111/stable-diffusion-webui](https://github.com/AUTOMATIC1111/stable-diffusion-webui) 是根據 [AGPL-3.0 授權](https://github.com/AUTOMATIC1111/stable-diffusion-webui/blob/master/LICENSE.txt) 發佈的。
> 請查閱他們的儲存庫以獲取源程式碼和許可證。
> 以下是此儲存庫中 Dockerfiles 和 CI workflow 的許可證。

> [!CAUTION]  
> AGPLv3 授權的 Dockerfile 代表你 ***必須*** **以同樣的許可證發佈程式**，若是你：
>
> - 重新發佈映像檔(若你沒有進行任何程式碼更改，則可以簡單地指向此 GitHub 儲存庫)
> - 發佈使用了此儲存庫程式碼的映像。
> - 或者發佈基於此映像的映像(在你的 Dockerfile 中使用 `FROM ghcr.io/jim60105/stable-diffusion-webui`)
>
> "發佈"意味著使該映像可供其他人下載，通常是將其推送到公開倉庫。 若僅用於個人目的，這部份不會對你產生影響。
>
> 有關詳細信息，請參閱 [LICENSE](LICENSE)。

[![CodeFactor](https://www.codefactor.io/repository/github/jim60105/docker-stable-diffusion-webui/badge)](https://www.codefactor.io/repository/github/jim60105/docker-stable-diffusion-webui) [![DeepSource](https://app.deepsource.com/gh/jim60105/docker-stable-diffusion-webui.svg/?label=active+issues&show_trend=false&token=1VuQPvmy4vSxN83egASazDLW)](https://app.deepsource.com/gh/jim60105/docker-stable-diffusion-webui/)
