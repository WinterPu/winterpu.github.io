---
title: Unreal Engine 虚幻引擎  科普简介
description: Unreal Engine 是什么，能做什么
keywords: 
date: 2024-11-24T23:34:56+08:00
lastmod: 2024-11-24T23:34:56+08:00
categories:
  - Dev
  - UnrealEngine
tags:
  - UE
  - 入门
  - 科普
author_desc: 原文作者
author: WinterPu
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
## 前言

本文目的，是对于这方面完全没有了解的朋友做一个简单的科普介绍。

1. 什么是游戏引擎，再者什么是UE虚幻引擎？
2. 它能干什么，有什么用？


## 什么是游戏引擎

游戏引擎可以简单理解为做游戏的工具（类似一个制作木盒子时的工具包，里面包含了锤子，钉子和木板）。

一款游戏，包含音乐，美术，程序。你需要制作界面UI，还需要制作音乐，你还要写代码，然后将其整合在一起。而游戏引擎，就起到了一个整合的作用。当你双击打开你做的应用，它负责怎么显示界面，什么时候播放音乐。

它在负责整合的同时，一般还会提供一些工具方便开发者开发。比如你要导入一段BGM，有些片段不想要，它一般会提供剪辑的功能。

然后除了开发游戏，慢慢地，它也可以被用在非游戏制作的其他领域上。

B站上也有些视频介绍，可以方便有一个概念。
* 【你了解“游戏引擎”么？【就知道玩游戏43]]

	https://www.bilibili.com/video/BV1ft411v77L/?share_source=copy_web&vd_source=75563d8e3e0fdfc43ab443705020d9db
* 【一口气了解全球游戏产业 | 为什么最近各大科技巨头纷纷入局？】 

	https://www.bilibili.com/video/BV1Qb4y1G7vY/?share_source=copy_web&vd_source=75563d8e3e0fdfc43ab443705020d9db

<!--more-->
## 什么是UE虚幻引擎

Unreal Engine, 它是一个Epic Games开发的游戏引擎。

### 个人心得
之前我一直是从一个程序员的角度去看UE，会觉得它是一个有着很多系统，module 模块组成的大型工具包。会感觉无从下手，学习了很久做个Demo 觉得不够顺畅。

现在我的理解：

对于UE，首先它先是一个3D 软件，然后再是游戏引擎。

为什么一般学美术的玩UE玩得溜，用得顺畅，

所以我觉得先从3D软件的角度入手。建模，打光，材质，渲染，才是引擎的原型。然后再来是各种其他的系统，比如物理系统，声音系统等等。

## UE 虚幻引擎的应用领域
* 制作游戏
* 制作视觉特效
* 制作动画
* 建筑可视化
* 虚拟制片
* 买量视频
* 数字人 / 虚拟直播
* 数字孪生 / 各种模拟
* 数字文旅 / 数字展厅
* ...



## 哪儿些游戏是用UE 虚幻引擎做的
* 黑神话悟空
* 幻兽帕鲁
* 堡垒之夜
* 无主之地3
* 地獄之刃：賽奴雅的獻祭
* 最终幻想7重制版
* ....


## UE 的收费模式
Ref: 
* https://www.unrealengine.com/zh-CN/faq 

2024/11/25 摘：

虚幻引擎免费提供给学生、教育工作者、业余爱好者和大多数年总营收低于100万美元的非游戏公司使用。

- 对于游戏开发商和其他用户，如果要发布在运行时整合了虚幻引擎代码的应用程序（例如游戏）并将其授权给第三方终端用户，当该产品在其生命周期内的总营收超过100万美元时，则需要支付5%的分成费用（可能适用折扣）。在这种情况下，前100万美元的营收仍无需支付分成费用。
- 对于其他公司，如果年总收入超过100万美元，则需要购买虚幻订阅席位。虚幻订阅的费用为每位用户每年1850美元，包含虚幻引擎、Twinmotion和RealityCapture。
- 我们还提供定制许可的选项，其中包含Epic直接服务，专属培训，可协商的分成条款（更低的分成费用）等。欢迎[联系我们](https://www.unrealengine.com/license#contact-us-form)，讨论您的需求。