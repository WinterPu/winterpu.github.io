---
title: Flux 入门
description: 
keywords: 
date: 2024-11-28T21:06:29+08:00
lastmod: 2024-11-28T21:06:29+08:00
categories:
  - AI
tags:
  - AI
  - AIGC
author_desc: 原文作者
author: WinterPu
link: 
imgs_desc: 图片链接，用在open graph和twitter卡片上
imgs: 
expand_desc: 是否在首页展开内容，true 为展开
expand: false
comment_desc: 是否在当前页面关闭评论功能,，true 为开启
comment:
  enable: true
toc_desc: 是否关闭文章目录功能，true 为开启
toc: true
url_desc: 绝对访问路径
url: 
weight_desc: 开启文章置顶，数字越小越靠前
weight: 
math_desc: 开启数学公式渲染，可选值： mathjax, katex
math: 
mermaid_desc: 开启各种图渲染，如流程图、时序图、类图等, true 为开启
mermaid: false
link_desc: "[link] 原文链接，Post's origin link URL"
extlink_desc: "[extlink] 外部链接地址, 访问时直接跳转"
---
｜ 非下载一键整合包，自己简单部署的流程

<!--more-->

## Flux 版本

- Pro 截止目前只能调用 api
- dev 画质比schnell 好，schnell 跑更快
	- FP16 看 up主说需要90系列显卡。
		- dev-fp16 默认状态画一张图时间参考
			- 用CUDA: 4060 笔记本显卡训练花了： 5min
	
- gguf 就是模型拆的更小


## 第一步 ComfyUI
https://github.com/comfyanonymous/ComfyUI

安装依赖后，python main.py

## 第二步 基础配置

### 1. 基础模型
flux1-dev.safetensors

BlackForest 的： dev or schnell
[black-forest-labs/FLUX.1-dev · Hugging Face](https://huggingface.co/black-forest-labs/FLUX.1-dev/)

 fp8 的 都在别的仓库

- **Dev/Schnell/GGUF 放置路径：ComfyUI/modles/unet/FLUX**
	- 丢FLUX 的话，应该选择的时候会需要再纠正一下路径，图方便可以直接丢在unet 下面
- Org 路径，Org 是被视为普通基础模型来被调用：**ComfyUI/modles/checkpoints**

### 2. Clip 模型
clip_l.safetensors
t5xxl_fp16.safetensors

作用：粗浅的理解是 文字与图像的关联，理解两者之间的关系
[comfyanonymous/flux_text_encoders at main](https://huggingface.co/comfyanonymous/flux_text_encoders/tree/main)

看显存选择是 t5xxl_fp16 还是 t5xxl_fp8, 一个即可

**路径：ComfyUI/modles/clip**

### 3. VAE 模型
ae.safetensors

作用：生成模型，一堆数据中学习并生成产物图片
[black-forest-labs/FLUX.1-dev at main](https://huggingface.co/black-forest-labs/FLUX.1-dev/tree/main)

**路径：ComfyUI/modles/unet/VAE**



## 使用

我是将这张图丢入ComfyUI 主界面，就出来了Flux 标准工作流，刚刚的模型指定正确，然后就可以使用了。
![Flux_Example](https://comfyanonymous.github.io/ComfyUI_examples/flux/flux_dev_example.png)
