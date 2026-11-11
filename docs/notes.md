# 实测记录

2026-11-11，设备 24129RT7CC（Android 16，arm64-v8a，16 GB RAM），Termux + proot-distro。

## 环境

- Termux 原生：Node v26.13.0（git 版），`command -v dsh` 为空
- 容器：Debian 13 (trixie)，aarch64，Node v22.23.4，npm 10.9.9
- proot-distro rootfs 实际路径：`/data/data/com.termux/files/usr/var/lib/proot-distro/containers/debian/rootfs`（不是 `installed-rootfs`）
- 安装位置：rootfs 内 `/usr/lib/node_modules/@deepseek-ai/dsh`，入口 `/usr/bin/dsh`（软链到 `lib/bin.js`）

## 安装

`npm i -g @deepseek-ai/dsh@0.2.1-rc.2`，约十分钟。

- 直连 `registry.npmjs.org` 时单个 tarball 50 到 110 秒；`registry.npmmirror.com` 约快 4.5 倍（实测同一文件 100 KB/s 对 22 KB/s）。
- 平台包按 `linux-arm64-gnu` 解析，全部有预编译：`node-pty` 的 `prebuilds/linux-arm64/pty.node`、`@img/sharp-linux-arm64`、`@koromix/koffi-linux-arm64`、`sherpa-onnx-linux-arm64`、`node-addon-require-builtin-linux-arm64-gnu`。没有任何一步需要 node-gyp。
- `node-addon-require-builtin` 没有 android 变体，README 写明缺平台包时 fail closed，不编译本地二进制。这是必须放进 Debian 的直接原因。
- npm 上 `0.2.2-rc.1` 的 `engines.node` 是 `>=24.9.0`；`0.2.1-rc.2` 没有 `engines` 字段。Debian 13 的 Node 22.x 够用。

## 启动

`dsh web --no-open --host 127.0.0.1 --port 3080`，从进程启动到打印 token URL 约 40 至 60 秒，期间日志为空，属正常。

`--host` 只接受具体接口地址，通配地址会被拒绝。

DSH 的 home 默认是 `~/.dsh`（不是 `.dsh-home`），首次启动自动创建。

## 浏览器打开

`dsh-web-app` 插件用 npm 的 `open` 包，Linux 上走 `xdg-open`；proot 里 `xdg-open` 无法到达 Android 浏览器。所以保持 `--no-open`，由 Termux 侧用 `termux-open-url` 打开。

`termux-open-url` 最终执行 `am start -a android.intent.action.VIEW -d <url>`。实测把带 `?token=` 的 URL 交给它时，Intent 的 `dat` 只剩 `http://127.0.0.1:3080/`，query 丢失，浏览器因此显示 `dsh web authentication required`。改用 3081 的 302 中转后，浏览器打开裸地址、由服务端给出完整 Location，认证通过并加载完整界面。

注意：从 `adb shell run-as` 里直接执行 `/system/bin/am` 会因 SELinux 报异常，这是测试环境的限制；用户终端里 `termux-open-url` 正常。

## API key

- 文件：`$DSH_HOME/.credentials.yaml`，手机上是 `/root/.dsh/.credentials.yaml`
- 格式：`version: 1` 加 `refs`，`DEEPSEEK_API_KEY` 作键
- 权限必须 `0600`，组或其他位可读时 credentials-local 拒绝启动
- 优先级：该文件 > 继承环境变量 > cwd/.env > `$DSH_HOME/.env`；web profile 有 credentials 服务时环境变量不生效
- 验证：`curl https://api.deepseek.com/models -H "Authorization: Bearer <key>"` 返回 200，模型列表含 `deepseek-flash`

## 其它

- Web UI 的「选择工作区目录」弹窗比手机屏幕宽，右侧「打开」按钮被截，可横屏或直接在路径栏填 `/root/`。
- Android 回收 Termux 后台进程是长期运行的主要风险：需要 `termux-wake-lock` 与电池优化白名单。
- 每次重启 dsh web 都会换 token，脚本从 `dsh-web.log` 读最新的，不需要手工抄。
