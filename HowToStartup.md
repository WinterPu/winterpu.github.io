# How To Startup

这份文档说明当前仓库在本地如何预览和构建博客。

## 推荐方式

当前内容里有一部分图片源文件放在 `content/**/.assets/**`。
为了保证本地预览时这些图片能正常访问，启动 `hugo` 之前先同步一次资源。

Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync-content-assets.ps1
hugo server --environment development --port 1414
```

Git Bash / WSL:

```bash
bash scripts/sync-content-assets.sh
hugo server --environment development --port 1414
```

启动后访问：

```text
http://localhost:1414/
```

## 仓库启动脚本

如果你想少输一点命令，可以直接用仓库根目录的启动脚本。

Git Bash / WSL:

```bash
sh startup.sh
```

Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\startup.ps1
```

这两个脚本都会先同步资源，再启动 `hugo server --port 1414`。

## 本地构建

如果你要在本地检查最终生成结果，建议先同步资源，再执行完整构建。

Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync-content-assets.ps1
hugo --cleanDestinationDir
```

Git Bash / WSL:

```bash
bash scripts/sync-content-assets.sh
hugo --cleanDestinationDir
```

构建结果输出到 `public/`。

## 说明

- 图片源目录统一使用 `content/**/.assets/**`，文章内引用统一使用相对路径 `./.assets/...`。
- 图片最终发布路径以文章 front matter 里的 `url` 为准，而不是以 markdown 所在目录层级为准，所以多级目录文章也可以正常发布图片。
- 裸跑 `hugo server` 或 `hugo --cleanDestinationDir` 仍然可以执行，但不会先同步 `content/**/.assets/**` 里的资源。
- 如果文章里用了 `./.assets/...` 图片引用，建议使用上面的“先同步再构建”命令。