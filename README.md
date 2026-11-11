# dsh-termux

在 Android 手机的 Termux 里，用 proot Debian 容器跑 DeepSeek Harness（`dsh web`）的一套脚本。

手机上的 DSH 跑在 Debian 容器里，Termux 只是宿主：起停、日志、浏览器打开都在 Termux 侧完成，`dsh` 本体在容器的 `/usr/bin/dsh`。

## 为什么不能直接装在 Termux

`dsh` 是纯 JS，但依赖里有一组按平台分发的原生包：`node-pty`、`sharp`、`koffi`、`sherpa-onnx-node`、`node-addon-require-builtin`。它们只发 `linux-*-gnu`（glibc）与 darwin/win32 变体，没有 android 变体。Termux 原生环境是 Android/Bionic，`process.platform` 为 `android`，其中 `node-addon-require-builtin` 在找不到匹配平台包时会 fail closed，直接拒绝继续。

放进 proot Debian 后是 glibc + `process.platform=linux`，上面这些包都能按 `linux-arm64-gnu` 正常解析，不需要编译。

## 前提

- Termux（建议 F-Droid 版）
- `proot-distro`（`pkg install proot-distro`）
- Debian 13 (trixie) rootfs
- 手机浏览器

## 安装

把仓库放到手机上（`git clone` 或直接拷目录），在 Termux 里执行：

```sh
bash install.sh
```

`install.sh` 会做四件事：

1. `proot-distro install debian`（已装则跳过）
2. 在 Debian 内确认 Node.js（Debian 13 自带 22.x，满足 0.2.1-rc.2）
3. `npm i -g @deepseek-ai/dsh@0.2.1-rc.2`
4. 把 `scripts/` 下的脚本装到 `~/`

可选环境变量：

| 变量 | 默认 | 作用 |
| --- | --- | --- |
| `DSH_VERSION` | `0.2.1-rc.2` | 安装的 dsh 版本 |
| `DSH_DISTRO` | `debian` | proot-distro 发行版名 |
| `DSH_REGISTRY` | 空 | npm registry，手机网络慢时填 `https://registry.npmmirror.com` |
| `DEEPSEEK_API_KEY` | 空 | 有值时写入容器的 `.credentials.yaml` |

## 用法

```sh
~/dsh-start.sh     # 起 dsh web，等 token 出现后自动打开默认浏览器
~/dsh-restart.sh   # 停掉旧实例并重起（杀命令行匹配的进程 + 按 3080 端口兜底）
```

日志：

- `~/dsh-web.log`：dsh web 的输出，含本次的 token URL
- `~/dsh-start.log`：启动脚本的输出
- `~/dsh-open.log`：3081 中转的输出

浏览器打开的是 `http://127.0.0.1:3081/`，由中转服务 302 到带 token 的 `http://127.0.0.1:3080/?token=...`。之所以绕一层，是因为把带 query 的 URL 直接交给 `termux-open-url` / `am` 时，部分环境会把 query 丢掉，落地的页面只剩「authentication required」。

## API key

写入容器的 `$DSH_HOME/.credentials.yaml`，默认是 `/root/.dsh/.credentials.yaml`：

```yaml
version: 1
refs:
  DEEPSEEK_API_KEY: sk-...
```

权限必须是 `600`，组或其他位可读时 credentials 服务会拒绝启动。web profile 挂了 credentials 服务，此时环境变量不生效，key 必须走这个文件（或在 Web UI 的 Models 页面保存）。

## 文件

- `install.sh`：一键安装入口
- `scripts/dsh-web.sh`：在 Debian 里起 `dsh web --no-open`
- `scripts/dsh-open-302.js`：3081 到 3080 的 302 中转，token 从 `dsh-web.log` 读
- `scripts/dsh-start.sh`：启动 + 等待 token + 打开浏览器
- `scripts/dsh-restart.sh`：停旧进程 + 重起

细节与实测记录见 [docs/notes.md](docs/notes.md)。

## 已知问题

- 手机直连 `registry.npmjs.org` 很慢（单个 tarball 50 至 110 秒），整个安装可能十分钟以上；用 `DSH_REGISTRY=https://registry.npmmirror.com` 会快不少。
- `0.2.2-rc.1` 起 `engines.node` 要求 `>=24.9.0`，Debian 13 apt 的 Node 是 22.x，所以这套默认锁 `0.2.1-rc.2`。要用新版得自己在容器里装 Node 24+。
- Web UI 的「选择工作区目录」弹窗在窄屏上会超出右边界，横屏或直接在路径栏填路径。
- Android 会回收后台进程，长期挂着建议 `termux-wake-lock` 并给 Termux 加电池优化白名单。

## 许可

MIT。DeepSeek Harness 本身是 DeepSeek 的项目，本仓库只包含安装与启动脚本，不是官方发行。
