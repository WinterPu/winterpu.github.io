---
title: Unreal 音频系统演进简述
description: Unreal 音频系统演进简述
keywords: Unreal, AudioSystem,AudioMixer,Roadmap
date: 2024-12-9T21:00:01+08:00
lastmod: 2024-12-9T21:00:01+08:00
categories:
  - Dev
  - UnrealEngine
tags:
  - UE
  - Audio
  - Roadmap
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


## Reference

- https://dev.epicgames.com/documentation/zh-cn/unreal-engine/audio-in-unreal-engine-5
- https://www.youtube.com/watch?v=QwMAKXBTAC8&type=snipo

# 前言

很多时候做UE的项目可能都会用类似Wwise 的中间件，所以可能对于UE本身音频系统关注不多。

笔者由于工作关系需要接触UE的音频系统，本文通过简述一下音频系统的发展史，顺便对一些初接触不知道是干什么的概念做一下简析。

<!--more-->

# 1. 原来UE4旧的音频系统

核心：虚幻引擎原有音频功能的核心是Sound Cues、Sound Classes和Sound Mixes。

- Sound Cues
    - 简单理解为音源，带点单个音源的参数控制
- Sound Classes：
    - 简单理解是用来分类的：比如背景音乐 和 角色音效
    - 然后针对每个分类都带有一些对应的属性
- Sound Mixes
    - 混音，声音混合

# 2. UE4 旧的Audio Engine  →  UE4 新的Audio Engine

## UE4旧版Audio Engine

![image.png](/post/dev/unreal_engine/unreal音频系统演进简述/image.png)

- Project Modules: 跟业务走的逻辑
- Engine Modules： 比如 Sound Cues 之类的
- Platform Modules: 不同平台不同的一些底层Module

这里对于UE的开发者，多一个平台PlatformModules 又要多维护一份

那么新的AudioEngine 是怎么解决的呢

## UE4新版 Audio Engine 的特性

添加了 AudioMixer 这一层
**Audio Mixer** 是虚幻引擎的的全功能、多平台的音频渲染器。这款强大的音频引擎在《堡垒之夜》中首次使用，随后被添加到虚幻引擎4.24中。

![image.png](/post/dev/unreal_engine/unreal音频系统演进简述/image%201.png)

- 新的AudioEngine 会多一层 AudioMixerModule
- 缩减了 PlatformModules ,所以会很 Thin
    - 就是 get your rendered audio buffer to the hardware
    - 所以添加一个Platform Modules 速度会更快
    

## 怎么切换的

 UseAudioMixer 是是 从 UE4 旧版本 到 UE4 新版本

![image.png](/post/dev/unreal_engine/unreal音频系统演进简述/image%202.png)

所以 UseAudioMixer  在 UE 427 还用于控制是否加载AudioMixerModule

以前UE4的配置

```cpp

[Audio]
AudioDeviceModuleName=IOSAudio
;Uncomment below and comment out above line to enable new audio mixer
;AudioDeviceModuleName=AudioMixerAudioUnit

; Defining below allows switching to audio mixer using -audiomixer commandline
AudioMixerModuleName=AudioMixerAudioUnit

```

![image.png](/post/dev/unreal_engine/unreal音频系统演进简述/image%203.png)

```cpp
	if (bUsingAudioMixer && AudioMixerModuleName.Len() > 0)
	{
		AudioDeviceModule = FModuleManager::LoadModulePtr<IAudioDeviceModule>(*AudioMixerModuleName);
		if (AudioDeviceModule)
		{
			static IConsoleVariable* IsUsingAudioMixerCvar = IConsoleManager::Get().FindConsoleVariable(TEXT("au.IsUsingAudioMixer"));
			check(IsUsingAudioMixerCvar);
			IsUsingAudioMixerCvar->Set(1, ECVF_SetByConstructor);
		}
		else
		{
			bUsingAudioMixer = false;
		}
	}
```

### 关于UseAudioMixer

UE5中应该已经没用处了，详细该怎么设置参考Config ini

```cpp
[Audio]

; Defining below allows switching to audio mixer using -audiomixer commandline
AudioMixerModuleName=AudioMixerAudioUnit
```

![image.png](/post/dev/unreal_engine/unreal音频系统演进简述/image%204.png)

UE5.4

```cpp
bool FAudioDeviceManager::LoadDefaultAudioDeviceModule()
{
	check(!AudioDeviceModule);

	bool bForceNonRealtimeRenderer = FParse::Param(FCommandLine::Get(), TEXT("DeterministicAudio"));

	// If not using command line switch to use audio mixer, check the game platform engine ini file (e.g. WindowsEngine.ini) which enables it for player
	GConfig->GetString(TEXT("Audio"), TEXT("AudioMixerModuleName"), AudioMixerModuleName, GEngineIni);

	if (bForceNonRealtimeRenderer)
	{
		AudioDeviceModule = FModuleManager::LoadModulePtr<IAudioDeviceModule>(TEXT("NonRealtimeAudioRenderer"));
		return AudioDeviceModule != nullptr;
	}

	if (AudioMixerModuleName.Len() > 0)
	{
		AudioDeviceModule = FModuleManager::LoadModulePtr<IAudioDeviceModule>(*AudioMixerModuleName);
	}

	return AudioDeviceModule != nullptr;
}

```

# 3. UE4 → UE5

UE5 新版本添加的部分新音频 Features

## MetaSound

MetaSound 设计思路简单来说就是：Audio Shader，

实现的其实就是一个 Audio DSP（Digital Signal Processor ） Flow

也就是通过类似材质系统实现效果的方式拖拖拉拉来 **生成** / **处理** 一段音频

**注意事项**

1. 目前Metasound 约等于 Metasound Source 【也就是目前它只是一种类似SoundCue 一样的一种音源，不过它可以通过程序来生成，处理修改】
    1. 或许之后Metasound 有别的含义甚至代表整个系统
2. Metasound C++ 能用么？
    
    【当前】Metasound 是native 没有像蓝图的 bytecode， 所以对于C++ 使用 它只是理论上可行，但是不推荐。
    

## AudioLink

简单来说就是把

UE的比如使用MetaSound，SoundCue 中的音频数据 ⇒ 导入到 类似：Wwise 等 第三方的音频系统中去

对于AudioLink 实现可以参考Wwise

[Audiokinetic](https://www.audiokinetic.com/zh/blog/adventures-with-audiolink/)