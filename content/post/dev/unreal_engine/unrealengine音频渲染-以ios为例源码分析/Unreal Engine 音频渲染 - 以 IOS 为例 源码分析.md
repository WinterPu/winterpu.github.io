---
title: Unreal Engine 音频渲染 - 以 IOS 为例 源码分析
description: Unreal Engine 音频渲染 - 以 IOS 为例 源码分析
keywords: Unreal, AudioSystem,AudioMixer,Roadmap,IOS
date: 2024-12-9T22:00:01+08:00
lastmod: 2024-12-9T22:00:01+08:00
categories:
  - Dev
  - UnrealEngine
  - IOS
tags:
  - UE
  - Audio
  - IOS
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


｜ 文章可能存在理解错误，如读者见到烦请指出，不胜感谢。

# 前言

## 相关的参考

- UE5.4
- Platform IOS

## 概述

本文简单说明一下IOS 平台上，UE 音频是如何通过调用系统接口来进行音频的渲染的。

## 以 IOS 为例的原因

之前测试的时候，其他平台没有问题，而IOS 平台因为有Audio Session 等机制，容易出现无声，或者乃至闪退的情况。所以本文以此为例，阐述一下大概的流程和分析。

<!--more-->

# UE 音频系统

## 一些Class 概念简介：

AudioMixer.cpp 中

- **AudioMixer**
    
    每个FMixerDevice 是一个 IAudioMixer 也是一个 FAudioDevice
    
    ```cpp
    	class FMixerDevice :	public。FAudioDevice,
    							public IAudioMixer,
    							public FGCObject
    ```
    
    一个AudioMixer是一个中间层，与平台硬件进行交互，处理相关的音频数据
    
    - 平台抽象出来的IAudioMixer
        
        ```cpp
        	/** Platform independent audio mixer interface. */
        	class IAudioMixer
        	{
        	public:
        		/** Callback to generate a new audio stream buffer. */
        		virtual bool OnProcessAudioStream(FAlignedFloatBuffer& OutputBuffer) = 0;
        
        		/** Called when audio render thread stream is shutting down. Last function called. Allows cleanup on render thread. */
        		virtual void OnAudioStreamShutdown() = 0;
        
        		bool IsMainAudioMixer() const { return bIsMainAudioMixer; }
        
        		/** Called by FWindowsMMNotificationClient to bypass notifications for audio device changes: */
        		AUDIOMIXERCORE_API static bool ShouldIgnoreDeviceSwaps();
        
        		/** Called by FWindowsMMNotificationClient to toggle logging for audio device changes: */
        		AUDIOMIXERCORE_API static bool ShouldLogDeviceSwaps();
        		
        		/** Called by AudioMixer to see if we should do a multithreaded device swap */
        		AUDIOMIXERCORE_API static bool ShouldUseThreadedDeviceSwap();
        
        		/** Called by AudioMixer to see if it should reycle the threads: */
        		AUDIOMIXERCORE_API static bool ShouldRecycleThreads();
        
        		/** Called by AudioMixer if it should use Cache for DeviceInfo Enumeration */
        		AUDIOMIXERCORE_API static bool ShouldUseDeviceInfoCache();
        
        	protected:
        
        		IAudioMixer() 
        		: bIsMainAudioMixer(false) 
        		{}
        
        		bool bIsMainAudioMixer;
        	};
        ```
        
    
    - FAudioDevice 更像一个提供给用户的接口层
    - FMixerDevice 看起来添加了很多处理Submix 混音等相关的
    
- **IAudioMixerPlatformInterface**
    
    可以看到IAudioMixerPlatformInterface 是一个FRunnable 也就是一个UE的线程
    
    ```cpp
    	/** Abstract interface for mixer platform. */
    	class IAudioMixerPlatformInterface : public FRunnable,
    														public FSingleThreadRunnable,
    														public IAudioMixerDeviceChangedListener
    ```
    
    ### 音频线程的创建：
    
    可以看到说 音频的渲染线程名字是 AudioMixerRenderThread
    
    ```cpp
    	void IAudioMixerPlatformInterface::BeginGeneratingAudio()
    	{
    		SCOPED_NAMED_EVENT(IAudioMixerPlatformInterface_BeginGeneratingAudio, FColor::Blue);
    		
    		checkf(!bIsGeneratingAudio, TEXT("BeginGeneratingAudio() is being run with StreamState = %i and bIsGeneratingAudio = %i"), AudioStreamInfo.StreamState, !!bIsGeneratingAudio);
    
    		bIsGeneratingAudio = true;
    
    		// Setup the output buffers
    		const int32 NumOutputFrames = OpenStreamParams.NumFrames;
    		const int32 NumOutputChannels = AudioStreamInfo.DeviceInfo.NumChannels;
    		const int32 NumOutputSamples = NumOutputFrames * NumOutputChannels;
    
    		// Set the number of buffers to be one more than the number to queue.
    		NumOutputBuffers = FMath::Max(OpenStreamParams.NumBuffers, 2);
    		UE_LOG(LogAudioMixer, Display, TEXT("Output buffers initialized: Frames=%i, Channels=%i, Samples=%i, InstanceID=%d"), NumOutputFrames, NumOutputChannels, NumOutputSamples, InstanceID);
    
    		OutputBuffer.Init(AudioStreamInfo.AudioMixer, NumOutputSamples, NumOutputBuffers, AudioStreamInfo.DeviceInfo.Format);
    
    		AudioStreamInfo.StreamState = EAudioOutputStreamState::Running;
    
    		check(AudioRenderEvent == nullptr);
    		AudioRenderEvent = FPlatformProcess::GetSynchEventFromPool();
    		check(AudioRenderEvent != nullptr);
    
    		check(AudioFadeEvent == nullptr);
    		AudioFadeEvent = FPlatformProcess::GetSynchEventFromPool();
    		check(AudioFadeEvent != nullptr);
    
    		check(!AudioRenderThread.IsValid());
    		uint64 RenderThreadAffinityCVar = SetRenderThreadAffinityCVar > 0 ? uint64(SetRenderThreadAffinityCVar) : FPlatformAffinity::GetAudioRenderThreadMask();
    		AudioRenderThread.Reset(FRunnableThread::Create(this, *FString::Printf(TEXT("AudioMixerRenderThread(%d)"), AudioMixerTaskCounter.Increment()), 0, (EThreadPriority)SetRenderThreadPriorityCVar, RenderThreadAffinityCVar));
    		check(AudioRenderThread.IsValid());
    	}
    ```
    
    不同平台会去实现这个线程
    
    ![image.png](/post/dev/unreal_engine/unrealengine音频渲染-以ios为例源码分析/image.png)
    
- **Audio::FOutputBuffer OutputBuffer**  在 IAudioMixerPlatformInterface  FRunable 线程中

![image.png](/post/dev/unreal_engine/unrealengine音频渲染-以ios为例源码分析/image%201.png)

AudioMixerSourceManager

- FMixerSourceManager 的作用，在这里，主要就是对于 音频command **AudioMixerThreadCommand 的处理**
    
    游戏线程中在比如 Play Pause 等塞入Command，音频线程中处理Command
    

## 渲染流程

### 主要关注两个音频 Event

- AudioRenderEvent
    - `AudioRenderEvent` 是Unreal Engine中用于音频渲染的事件。
- CommandsProcessedEvent
    - `CommandsProcessedEvent` 的作用在于游戏线程与音频线程之间的同步

我们这边以当时我处理闪退的思路来介绍

当音频崩溃了首先看到的是这个：

```bash
		// void FMixerSourceManager::AudioMixerThreadCommand(TFunction<void()>&& InFunction, const char* InDebugString, bool bInDeferExecution /*= false*/)
		
		
		// log warnings for command buffer growing too large
		if (OldMax != NewMax)
		{
			// Only throw a warning every time we have to reallocate, which will be less often then every single time we add
			static SIZE_T WarnSize = 1024 * 1024;
			if (CurrentBufferSizeInBytes > WarnSize )
			{
				float TimeSinceLastComplete = FPlatformTime::ToSeconds64(FPlatformTime::Cycles64() - LastPumpCompleteTimeInCycles);

				UE_LOG(LogAudioMixer, Error, TEXT("Command Queue %d has grown to %ukb, containing %d cmds, last complete pump was %2.5f seconds ago."),
					AudioThreadCommandIndex, CurrentBufferSizeInBytes >> 10, NewNum, TimeSinceLastComplete);
				WarnSize *= 2;

				DoStallDiagnostics();
			}
			
			// check that we haven't gone over the max size
			const SIZE_T MaxBufferSizeInBytes = ((SIZE_T)CommandBufferMaxSizeInMbCvar) << 20;
			if (CurrentBufferSizeInBytes >= MaxBufferSizeInBytes)
			{
				int32 NumTimesOvergrown = CommandBuffers[AudioThreadCommandIndex].NumTimesOvergrown.Increment();
				UE_LOG(LogAudioMixer, Error, TEXT("%d: Command buffer %d allocated size has grown to %umb! Likely cause the AudioRenderer has hung"),
					NumTimesOvergrown, AudioThreadCommandIndex, CurrentBufferSizeInBytes >> 20);
			}
		}
```

也就是这边Command Buffer 被塞爆了，并且提示可能的原因是 AudioRenderer 可能被挂起了停止了。

首先去研究`CommandsProcessedEvent` 它是哪儿Wait 哪儿被Trigger的

### 游戏线程中

游戏线程中在`CommandsProcessedEvent` 哪儿Wait： MixerSourceManager 的Update，在处理AudioMixerThreadCommand 时候

![image.png](/post/dev/unreal_engine/unrealengine音频渲染-以ios为例源码分析/image%202.png)

每个AudioDevice 在 Update 的时候，这个会等待, 检查状态

而AudioDevice 的Update 游戏线程中, 从Engine 的Tick 开始

```cpp
//Engine/Source/Runtime/Engine/Private/GameEngine.cpp
void UGameEngine::Tick( float DeltaSeconds, bool bIdleMode ){

		// Update Audio. This needs to occur after rendering as the rendering code updates the listener position.
	FAudioDeviceManager* GameAudioDeviceManager = GEngine->GetAudioDeviceManager();
	if (GameAudioDeviceManager)
	{
		SCOPE_TIME_GUARD(TEXT("UGameEngine::Tick - Update Audio"));
		GameAudioDeviceManager->UpdateActiveAudioDevices(bIsAnyNonPreviewWorldUnpaused);
	}
	
}
```

```cpp
// Engine/Source/Runtime/Engine/Private/AudioDeviceManager.cpp

void FAudioDeviceManager::UpdateActiveAudioDevices(bool bGameTicking)
{
	// Before we kick off the next update make sure that we've finished the previous frame's update (this should be extremely rare)
	if (GCVarEnableAudioThreadWait)
	{
		SyncFence.Wait();
	}

	IterateOverAllDevices(
		[&bGameTicking](Audio::FDeviceId, FAudioDevice* InDevice)
		{
			InDevice->Update(bGameTicking);
		}
	);

	if (GCVarEnableAudioThreadWait)
	{
		SyncFence.BeginFence();
	}
}
```

对于 每个Device 进行Update

```cpp
//Engine/Source/Runtime/Engine/Private/AudioDevice.cpp
void FAudioDevice::Update(bool bGameTicking){

		// now let the platform perform anything it needs to handle
	{
		TRACE_CPUPROFILER_EVENT_SCOPE(FAudioDevice_UpdateHardware);
		UpdateHardware();
	}

	// send any needed information back to the game thread
	SendUpdateResultsToGameThread(FirstActiveIndex);
	
}
```

那么什么算是一个Device 呢

比如 IOSAudioDevice

![image.png](/post/dev/unreal_engine/unrealengine音频渲染-以ios为例源码分析/image%203.png)

不过当前从CallStack 上来看，IOS 用的应该也是FMixerDevice，然后平台层去写相关资源取用实现

补充一下AudioDevice 初始化时候

![image.png](/post/dev/unreal_engine/unrealengine音频渲染-以ios为例源码分析/image%204.png)

## 音频线程 AudioMixerRenderThread 中

而音频线程中对于 `CommandsProcessedEvent` 这个事件的触发Trigger

在一次PumpCommandQueue中

`CommandsProcessedEvent` 在一个Command 被处理完后会Trigger, 不然会在CommandsProcessedEvent->Wait(0) 检查后被Return

```cpp
	void FMixerSourceManager::PumpCommandQueue()
	{
		TRACE_CPUPROFILER_EVENT_SCOPE(AudioMixerThreadCommands::PumpCommandQueue)
		AudioRenderThreadId = FPlatformTLS::GetCurrentThreadId();
		
		// If we're already triggered, we need to wait for the audio thread to reset it before pumping
		if (FPlatformProcess::SupportsMultithreading())
		{
			if (CommandsProcessedEvent->Wait(0))
			{
				return;
			}
		}

		// Pump the MPSC command queue
		RenderThreadPhase = ESourceManagerRenderThreadPhase::PumpMpscCmds;
		TOptional Opt{ MpscCommandQueue.Dequeue() };
		while (Opt.IsSet())
		{
			// First copy/move out the command and keep a copy of it.
			{
				FWriteScopeLock Lock(CurrentlyExecutingCmdLock);
				CurrentlyExecuteingCmd = MoveTemp(Opt.GetValue());
			}
			
			// Execute the current under a read-lock.
			{
				FReadScopeLock Lock(CurrentlyExecutingCmdLock);
				CurrentlyExecuteingCmd();
			}
				
			Opt = MpscCommandQueue.Dequeue();
		}

		int32 CurrentRenderThreadIndex = RenderThreadCommandBufferIndex.GetValue();
		FCommands& Commands = CommandBuffers[CurrentRenderThreadIndex];

		const int32 NumCommandsToExecute = Commands.SourceCommandQueue.Num();
		TRACE_INT_VALUE(TEXT("AudioMixerThreadCommands::NumCommandsToExecute"), NumCommandsToExecute);

		// Pop and execute all the commands that came since last update tick
		TArray<FAudioMixerThreadCommand> DelayedCommands;
		RenderThreadPhase = ESourceManagerRenderThreadPhase::PumpCmds;
		for (int32 Id = 0; Id < NumCommandsToExecute; ++Id)
		{
			// First copy/move out the command and keep a copy of it.
			{ 
				FWriteScopeLock Lock(CurrentlyExecutingCmdLock);
				CurrentlyExecuteingCmd = MoveTemp(Commands.SourceCommandQueue[Id]);
			}
			
			// Execute the current command or differ under a read-lock.
			{
				FReadScopeLock Lock(CurrentlyExecutingCmdLock);
				if (CurrentlyExecuteingCmd.bDeferExecution)
				{
					CurrentlyExecuteingCmd.bDeferExecution = false;
					DelayedCommands.Add(CurrentlyExecuteingCmd);
				}
				else
				{
					CurrentlyExecuteingCmd(); // execute
				}
			}
			
			NumCommands.Decrement();
		}

		LastPumpCompleteTimeInCycles = FPlatformTime::Cycles64();
		// This is intentionally re-assigning the Command Queue and clearing the buffer in the process
		Commands.SourceCommandQueue = MoveTemp(DelayedCommands);
		Commands.SourceCommandQueue.Reserve(GetCommandBufferInitialCapacity());

		if (FPlatformProcess::SupportsMultithreading())
		{
			check(CommandsProcessedEvent != nullptr);
			CommandsProcessedEvent->Trigger();
		}
		else
		{
			RenderThreadCommandBufferIndex.Set(!CurrentRenderThreadIndex);
		}
	} 
```

![image.png](/post/dev/unreal_engine/unrealengine音频渲染-以ios为例源码分析/image%205.png)

而 PumpCommandQueue 主要是在 FlushCommandQueue 的时候

![image.png](/post/dev/unreal_engine/unrealengine音频渲染-以ios为例源码分析/image%206.png)

![image.png](/post/dev/unreal_engine/unrealengine音频渲染-以ios为例源码分析/image%207.png)

## 音频线程中 影响`CommandsProcessedEvent` 的 AudioRenderEvent

### 两者的联系

![image.png](/post/dev/unreal_engine/unrealengine音频渲染-以ios为例源码分析/image%208.png)

AudioRenderEvent 如果那边一直等待

OutputBuffer.MixNextBuffer() 就会被搁置，调用不到 AudioMixer 的 OnProcessAudioStream

也就调用不到FMixerDevice的 OnProcessAudioStream

![image.png](/post/dev/unreal_engine/unrealengine音频渲染-以ios为例源码分析/image%209.png)

![image.png](/post/dev/unreal_engine/unrealengine音频渲染-以ios为例源码分析/image%2010.png)

对于音频线程，我们看到问题Log

```cpp
[2024.12.09-07.52.04:149][437]LogAudioMixer: Warning: AudioMixerPlatformInterface Timeout [ 5 Seconds] waiting for h/w. InstanceID=1
```

找到代码：

1. AudioRenderEvent→Wait

```cpp
uint32 IAudioMixerPlatformInterface::RunInternal()
	{
		UE_LOG(LogAudioMixer, Display, TEXT("Starting AudioMixerPlatformInterface::RunInternal(), InstanceID=%d"), InstanceID);

		// Lets prime and submit the first buffer (which is going to be the buffer underrun buffer)
		int32 NumSamplesPopped;
		TArrayView<const uint8> AudioToSubmit = OutputBuffer.PopBufferData(NumSamplesPopped);

		SubmitBuffer(AudioToSubmit.GetData());

		OutputBuffer.MixNextBuffer();

		while (AudioStreamInfo.StreamState != EAudioOutputStreamState::Stopping)
		{
			// Render mixed buffers till our queued buffers are filled up
			while (bIsDeviceInitialized && OutputBuffer.MixNextBuffer())
			{
			}

			// Bounds check the timeout for our audio render event.
			OverrunTimeoutCVar = FMath::Clamp(OverrunTimeoutCVar, 500, 5000);

			// If we're debugging, make the timeout the maximum to avoid needless swaps.
			OverrunTimeoutCVar = FPlatformMisc::IsDebuggerPresent() ? TNumericLimits<uint32>::Max() : OverrunTimeoutCVar;

			// Now wait for a buffer to be consumed, which will bump up the read index.
			const double WaitStartTime = FPlatformTime::Seconds();
			if (AudioRenderEvent && !AudioRenderEvent->Wait(static_cast<uint32>(OverrunTimeoutCVar)))
			{
				// if we reached this block, we timed out, and should attempt to
				// bail on our current device.
				RequestDeviceSwap(TEXT(""), /* force */true, TEXT("AudioMixerPlatformInterface. Timeout waiting for h/w."));

				const float TimeWaited = FPlatformTime::Seconds() - WaitStartTime;
				UE_LOG(LogAudioMixer, Warning, TEXT("AudioMixerPlatformInterface Timeout [%2.f Seconds] waiting for h/w. InstanceID=%d"), TimeWaited,InstanceID);
			}
		}

		OpenStreamParams.AudioMixer->OnAudioStreamShutdown();

		AudioStreamInfo.StreamState = EAudioOutputStreamState::Stopped;
		return 0;
	}
```

可以看到 AudioRenderEvent 等待超时，没有Trigger，所以触发这个

这个是在 音频线程中：IAudioMixerPlatformInterface::ReadNextBuffer  触发的

1. AudioRenderEvent→Trigger

![image.png](/post/dev/unreal_engine/unrealengine音频渲染-以ios为例源码分析/image%2011.png)

IOS Audio Unit 这边调用：

![image.png](/post/dev/unreal_engine/unrealengine音频渲染-以ios为例源码分析/image%2012.png)

这边已经找到了Apple 的系统层面的调用

关于Apple 的AudioUnit API：

https://developer.apple.com/documentation/audiotoolbox/audio-unit-v2-c-api】；

】=】

## 目前 UE 各平台系统层面音频Module 设置

IOS 是使用AudioUnit ，那么其他平台呢，或者有哪儿些音频Module 可以使用

主要去看音频的Config

![image.png](/post/dev/unreal_engine/unrealengine音频渲染-以ios为例源码分析/image%2013.png)

目前测试 IOS 上使用CoreAudio 不行。