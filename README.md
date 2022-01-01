
# Wrangle

<div align="center">
<img src="https://raw.githubusercontent.com/wendyliga/wrangler/main/assets/wrangle.png">
</div>
<br>
<p align="center">
    <a href="https://github.com/wendyliga/wrangler/actions/workflows/ci.yml">
        <img src="https://github.com/wendyliga/wrangler/actions/workflows/ci.yml/badge.svg" alt="CI" />
    </a>
    <a href="https://hub.docker.com/r/wendyliga/wrangler">
        <img src="https://img.shields.io/github/workflow/status/wendyliga/wrangler/Docker.svg?label=Docker&logo=docker&cacheSeconds=600"/>
    </a>
    <a href="https://github.com/wendyliga/wrangler/releases">
        <img src="https://img.shields.io/github/v/release/wendyliga/wrangler" alt="Latest Release" />
    </a>
    <a href="https://github.com/wendyliga/wrangler/blob/main/LICENSE">
        <img src="https://img.shields.io/github/license/wendyliga/wrangler.svg?label=License&logo=mit&cacheSeconds=2592000" />
    </a>
    <a href="https://twitter.com/wendyliga">
        <img src="https://img.shields.io/badge/contact-@wendyliga-blue.svg?style=flat" alt="Twitter: @wendyliga" />
    </a>
</p>

# Requirement
- [ArchiSteamFarm](https://github.com/JustArchiNET/ArchiSteamFarm) v5.1.2.4 or newer
- [ASF-Achievement-Manager](https://github.com/Ryzhehvost/ASF-Achievement-Manager) v0.2.0.0 or newer

# Installation
![wrangler](https://raw.githubusercontent.com/wendyliga/wrangler/main/assets/preview2.png)

## Windows
- Download `wrangler-win10_x86-64.zip` from latest [Release](https://github.com/wendyliga/wrangler/releases)
- extract it
- open command prompt or power shell (cd to directory if neccessary) and run

```powershell
.\wrangler.exe --help
```
## MacOS & Linux
- Download `wrangler` from latest [Release](https://github.com/wendyliga/wrangler/releases)
- execute it on terminal

```bash
# cd ~/Download
./wrangler --help
```

more parameter
```
USAGE: wrangler [<string> ...] [--ipc-server <http://127.0.0.1>] [--ipc-password <password>] [--ipc-port <1242>] [--execution-interval <24>] [--claim-free-game]

ARGUMENTS:
  <string>                ASF bot names

OPTIONS:
  --ipc-server <http://127.0.0.1>   IP where ASF is hosted(with http protocol) (default: http://127.0.0.1)
                                    only supply this if you run your ASF on a server or docker.Learn more
                                    https://github.com/JustArchiNET/ArchiSteamFarm/wiki/IPC
  --ipc-password <password>         Password for IPC
                                    ASF by default doesn't use any password for IPC, but if you do, you need to supply it here.Learn more
                                    https://github.com/JustArchiNET/ArchiSteamFarm/wiki/IPC#authentication
  --ipc-port <1242>                 Port for IPC (default: 1242)
                                    ASF use 1242 by default, if you use custom port forwarding on your server or docker, you need to supply it here
  --execution-interval <24>         How often to execute the task (default: 24)
                                    how often to check the check and complete all achievement. if you don't want to check it periodically, set it to 0
  --claim-free-game                 Use this flag to automatically claim free game from 
                                    https://gist.githubusercontent.com/C4illin/ e8c5cf365d816f2640242bf01d8d3675/raw/9c64ec3e1c614856e444e69a7b9d4a70dfc6a76f/Steam%2520Codes
  --complete-all-achievement       Use this flag to automatically complete all achievement
  --version                         Show the version.
  -h, --help                        Show help information.
```

you can also use `config.json` by placing it beside `wrangler`, or use environment like docker below.

## Docker
![docker](https://raw.githubusercontent.com/wendyliga/wrangler/main/assets/preview.png)
### Tags
`latest`
---
The current most updated stable version of wrangler.The objective of this tag is to provide a sane default Docker container that is capable of running self-updating of `wrangler`

`edge`
---
This tag is based on every changes on `main` branch. This image is for development purposes.

`version` <A.B.C>
---
This tag is based on release version.

### Usage
`config.json`
---
- you can take a look at json example on this repo named `config.example.json`. 
- rename it to `config.json`
- pass it to docker with volume
```
docker run --rm --name wrangler --network host --pull always \
    -v '/users/jhon/config.json:/app/config.json' \
    wendyliga/wrangler:latest
```
* you can always use `-d` to detach docker run from your terminal

`environment`
---
```
docker run --rm --name wrangler --network host --pull always \
    -e 'BOT_NAMES=BOT_1,BOT_2' \
    -e 'IPC_SERVER=http://127.0.0.1' \
    -e 'IPC_PORT=1242' \
    -e 'IPC_PASSWORD=admin' \
    -e 'INTERVAL_IN_HOUR=24' \
    -e 'CLAIM_FREE_GAME=true' \
    -e 'COMPLETE_ALL_ACHIEVEMENT=true' \
    wendyliga/wrangler:latest
```
* you can always use `-d` to detach docker run from your terminal
* `IPC_PASSWORD` is optional, only if you use one

`docker-compose`
---
on your `docker-compose.yml`
```yml
version: "3.9"
services:
    wrangler:
        container_name: wrangler
        image: wendyliga/wrangler:latest
        restart: always
        network: host
        volumes:
            # uncomment this if you want to supply config.json
            #
            # - '/users/jhon/config.json:/app/config.json'
        environment:
            # uncomment this if you want to use environment
            #
            # BOT_NAMES: 'BOT_1,BOT_2'
            # IPC_SERVER: 'http://127.0.0.1' # optional, default http://127.0.0.1
            # IPC_PORT: '1242' # optional, default 1242
            # IPC_PASSWORD: 'admin' # optional, if you use one
            # INTERVAL_IN_HOUR: '24' 
            # CLAIM_FREE_GAME: 'true'
            # COMPLETE_ALL_ACHIEVEMENT: 'true'
```

# DISCLAIMER
This app is provided on AS-IS basis, without any guarantee at all. Author is not responsible for any harm, direct or indirect, that may be caused by using this plugin. You use this plugin at your own risk.

the author can't guarantee free vac ban from steam.

# LICENSE

```
MIT License

Copyright (c) 2021 Wendy Liga

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
