//
//  AQPlayerManager.m
//  recordAudip
//
//  Created by 高广校 on 2023/8/24.
//  https://www.jianshu.com/p/d64c74deb580?utm_campaign=maleskine&utm_content=note&utm_medium=seo_notes&utm_source=recommendation

#import "AQPlayerManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>
#import "AQUnitTools.h"
static const int kNumberBuffers = 3;                              // 1
typedef struct AQPlayerState {
    AudioStreamBasicDescription   mDataFormat;                    // 2
    AudioQueueRef                 mQueue;                         // 3
    AudioQueueBufferRef           mBuffers[kNumberBuffers];       // 4
    AudioFileID                   mAudioFile;                     // 5
    UInt32                        bufferByteSize;                 // 6
    SInt64                        mCurrentPacket;                 // 7
    UInt32                        mNumPacketsToRead;              // 8
    AudioStreamPacketDescription  *mPacketDescs;                  // 9
    bool                          mIsRunning;                     // 10
    Float64                       duration;                       // 11 音频时长
} AQPlayerState;

//The Playback Audio Queue Callback
static void HandleOutputBuffer(void* aqData,
                               AudioQueueRef inAQ,
                               AudioQueueBufferRef inBuffer){
    AQPlayerState *pAqData = (AQPlayerState *) aqData;
//    if (pAqData->mIsRunning == 0) return; // 注意苹果官方文档这里有这一句,应该是有问题,这里应该是判断如果pAqData->isDone??
    
    UInt32 numBytesReadFromFile;
    UInt32 numPackets = pAqData->mNumPacketsToRead;
    CheckPlayError(AudioFileReadPackets(pAqData->mAudioFile,
                                    false,
                                    &numBytesReadFromFile,
                                    pAqData->mPacketDescs,
                                    pAqData->mCurrentPacket,
                                    &numPackets,
                                    inBuffer->mAudioData), "AudioFileReadPackets");
    
    if (numPackets > 0) {
        inBuffer->mAudioDataByteSize = numBytesReadFromFile;
        AudioQueueEnqueueBuffer(inAQ,inBuffer,(pAqData->mPacketDescs ? numPackets : 0),pAqData->mPacketDescs);
        pAqData->mCurrentPacket += numPackets;
    } else {
        
        AudioQueueStop(inAQ,false);
        pAqData->mIsRunning = false;
    }
}


//计算buffer size
void DeriveBufferSize (AudioStreamBasicDescription inDesc,UInt32 maxPacketSize,Float64 inSeconds,UInt32 *outBufferSize,UInt32 *outNumPacketsToRead) {
    
    static const int maxBufferSize = 0x10000;
    static const int minBufferSize = 0x4000;
    
    if (inDesc.mFramesPerPacket != 0) {
        Float64 numPacketsForTime = inDesc.mSampleRate / inDesc.mFramesPerPacket * inSeconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    } else {
        *outBufferSize = maxBufferSize > maxPacketSize ? maxBufferSize : maxPacketSize;
    }
    
    if (*outBufferSize > maxBufferSize && *outBufferSize > maxPacketSize){
        *outBufferSize = maxBufferSize;
    }
    else {
        if (*outBufferSize < minBufferSize){
            *outBufferSize = minBufferSize;
        }
    }
    
    *outNumPacketsToRead = *outBufferSize / maxPacketSize;
}

static void MyCopyEncoderCookieToQueue(AudioFileID theFile,AudioQueueRef queue) {
    UInt32 cookieSize;
    OSStatus result = AudioFileGetPropertyInfo(theFile,kAudioFilePropertyMagicCookieData,&cookieSize,NULL);
    
    if (result == noErr && cookieSize > 0) {
        char* magicCookie = (char *) malloc(cookieSize);
        AudioFileGetProperty(theFile,kAudioFilePropertyMagicCookieData,&cookieSize,magicCookie);
        AudioQueueSetProperty(queue,kAudioQueueProperty_MagicCookie,magicCookie,cookieSize);
        free (magicCookie);
    }
}

@interface AQPlayerManager () {
    AQPlayerState aqData;
}

@property (nonatomic, strong) NSTimer *playTimer;//播放音频时长控制
@end

@implementation AQPlayerManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self initPlay];
    }
    return self;
}

//- (instancetype)initAudioFormatType:(AudioFormatType)audioFormatType sampleRate:(Float64)sampleRate channels:(UInt32)channels bitsPerChannel:(UInt32)bitsPerChannel {
//    self = [super init];
//    if (self) {
//        [self initPlay];
//        
//        [self setAudioFormatType:audioFormatType
//                      sampleRate:sampleRate
//                        channels:channels
//                  bitsPerChannel:bitsPerChannel];
//    }
//    return self;
//}

- (void)initPlay {
    
    self.volume = 1.0;
    
    self.avAudioSessionPermission = AQPlayAudioPermissionAll;
}

//- (void)setAudioFormatType:(AudioFormatType)audioFormatType
//                sampleRate:(Float64)sampleRate
//                  channels:(UInt32)channels
//            bitsPerChannel:(UInt32)bitsPerChannel {
//    aqData.mDataFormat.mSampleRate = sampleRate > 0 ? sampleRate : kDefaultSampleRate;
//    aqData.mDataFormat.mChannelsPerFrame = channels > 0 ? channels : kDefaultChannels;
//    
//    if (audioFormatType == AudioFormatLinearPCM) {
//        
//        aqData.mDataFormat.mFormatID = kAudioFormatLinearPCM;
//        aqData.mDataFormat.mBitsPerChannel = bitsPerChannel > 0 ? bitsPerChannel : kDefaultBitsPerChannel;
//        aqData.mDataFormat.mBytesPerPacket =
//        aqData.mDataFormat.mBytesPerFrame = (aqData.mDataFormat.mBitsPerChannel / 8) * aqData.mDataFormat.mChannelsPerFrame;
//        aqData.mDataFormat.mFramesPerPacket = 1;
//        aqData.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
//        
//    } else if (audioFormatType == AudioFormatMPEG4AAC) {
//        
//        aqData.mDataFormat.mFormatID = kAudioFormatMPEG4AAC;
//        aqData.mDataFormat.mFormatFlags = kMPEG4Object_AAC_Main;
//        
//    }
//}

- (void)setVolume:(float)volume {
    _volume = volume;
}

- (void)setAvAudioSessionPermission:(AQPlayAudioPermission)avAudioSessionPermission {

    _avAudioSessionPermission = avAudioSessionPermission;
    
    if (_avAudioSessionPermission == AQPlayAudioPermissionNone) {
       
    } else if (_avAudioSessionPermission == AQPlayAudioPermissionAll) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    } else if (self.avAudioSessionPermission == AQPlayAudioPermissionSetActive) {
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    }
}

- (void)startPlay:(NSString *)filePath {

    //1、获取文件路径
//    NSLog(@"----- %@", filePath);
    if (!filePath) {
        return;
    }
//    CFStringRef
    // CFStringRef to NSString *
//    NSString *yourFriendlyNSString = (__bridge NSString *)yourFriendlyCFString;

    // NSString * to CFStringRef
//    CFStringRef yourFriendlyCFString = (__bridge CFStringRef)yourFriendlyNSString;
//    char fp = [filePath cStringUsingEncoding:NSUTF8StringEncoding];
//    char fp = filePath.cString;
//    NSString *happyString = (NSString*)CFBridgingRelease(sadString);
    CFStringRef cfsRef = (__bridge CFStringRef)filePath;
    //获取一个CFURL对象表示音频路径
    CFURLRef audioFileURL =  CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                           cfsRef,
                                                          kCFURLPOSIXPathStyle,
                                                          false);

    //2、打开音频文件
    AQPlayerState aqData;                                   // 1
    OSStatus fileStatus =
        AudioFileOpenURL (                                  // 2
            audioFileURL,                                   // 3
            kAudioFileReadPermission,                                       // 4
            0,                                              // 5
            &aqData.mAudioFile                              // 6
        );
    CFRelease (audioFileURL);                               // 7
    
    if (fileStatus != noErr) {
        NSLog(@"获取文件失败：%d", fileStatus);
        return;
    }
    
    //3、获取文件格式
    UInt32 dataFormatSize = sizeof(aqData.mDataFormat);
    AudioFileGetProperty(aqData.mAudioFile,
                          kAudioFilePropertyDataFormat,
                          &dataFormatSize,
                          &aqData.mDataFormat);
    
    //4、创建音频队列
    OSStatus queueStatus = AudioQueueNewOutput (&aqData.mDataFormat,
        HandleOutputBuffer,
        &aqData,
        CFRunLoopGetCurrent(),
        kCFRunLoopCommonModes,
        0,
        &aqData.mQueue
    );
    
    if (queueStatus != noErr) {
        NSLog(@"创建音频队列失败: %d", queueStatus);
        return;
    }
    
    //6、设置播放音频队列大小
    UInt32 maxPacketSize;
    UInt32 propertySize = sizeof(maxPacketSize);
    CheckPlayError(AudioFileGetProperty(aqData.mAudioFile,kAudioFilePropertyPacketSizeUpperBound,&propertySize,&maxPacketSize),"AudioFileGetProperty");
    
    // 设置缓冲区大小
    DeriveBufferSize (                                   // 6
        aqData.mDataFormat,                              // 7
        maxPacketSize,                                   // 8
        0.5,                                             // 9
        &aqData.bufferByteSize,                          // 10
        &aqData.mNumPacketsToRead                        // 11
    );
    
    bool isFormatVBR = (aqData.mDataFormat.mBytesPerPacket == 0 ||aqData.mDataFormat.mFramesPerPacket == 0);
    if (isFormatVBR) {
        aqData.mPacketDescs =(AudioStreamPacketDescription*) malloc (aqData.mNumPacketsToRead * sizeof (AudioStreamPacketDescription));
    } else {
        aqData.mPacketDescs = NULL;
    }
    
    //Set a Magic Cookie for a Playback Audio Queue
    MyCopyEncoderCookieToQueue(aqData.mAudioFile, aqData.mQueue);

    //Allocate and Prime Audio Queue Buffers
    aqData.mCurrentPacket = 0;
    
    for (int i = 0; i < kNumberBuffers; ++i) {
        CheckPlayError(AudioQueueAllocateBuffer(aqData.mQueue,
                                            aqData.bufferByteSize,
                                            &aqData.mBuffers[i]),"AudioQueueAllocateBuffer");
        HandleOutputBuffer(&aqData,aqData.mQueue,aqData.mBuffers[i]);
    }
    
    
    Float32 gain = self.volume;
    // Optionally, allow user to override gain setting here
    AudioQueueSetParameter (
                            aqData.mQueue,
                            kAudioQueueParam_Volume,
                            gain
                            );
    
    //Start and Run an Audio Queue
    aqData.mIsRunning = true;
    CheckPlayError(AudioQueueStart(aqData.mQueue,NULL),"AudioQueueStart failed");

    //开启音量检测
    UInt32 val = 1;
    CheckPlayError(AudioQueueSetProperty(aqData.mQueue,
                                     kAudioQueueProperty_EnableLevelMetering,
                                     &val,
                                     sizeof(UInt32)), "EnableLevelMetering");

    do {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.25,false);
    } while (aqData.mIsRunning);
    
    CFRunLoopRunInMode(kCFRunLoopDefaultMode,2,false);
    
    [self addPlayTimer];
}

- (void)stopPlayer {
    aqData.mIsRunning = false;
    AudioQueueStop(aqData.mQueue, true);
    
    // 录音结束后再次调用magic cookies，一些编码器会在录音停止后更新magic cookies数据
//    if (aqData.mDataFormat.mFormatID != kAudioFormatLinearPCM) {
//        SetMagicCookieForFile(aqData.mQueue, aqData.mAudioFile);
//    }
    
    AudioQueueDispose(aqData.mQueue, true);
    AudioFileClose(aqData.mAudioFile);
    
    [self removePlayTimer];
}

- (void)playTimeAdd {
    
    float avaValue = [AQUnitTools getCurrentPower:aqData.mQueue andDataFormat:aqData.mDataFormat];
    if (self.aqDelegate && [self.aqDelegate respondsToSelector:@selector(didOutputAudioPeakPower:)]) {
        [self.aqDelegate didOutputAudioPeakPower:avaValue];
    }

    if (aqData.mIsRunning) {
        
        
    } else {
        //
        AudioQueueDispose(aqData.mQueue, true);
        AudioFileClose(aqData.mAudioFile);
        
        [self removePlayTimer];
        
        if (self.aqDelegate && [self.aqDelegate respondsToSelector:@selector(playAudioFinish)]) {
            [self.aqDelegate playAudioFinish];
        }
    }
    //播放
}

#pragma mark - property
- (NSTimeInterval)playedAudioTime {
    if (aqData.mDataFormat.mSampleRate == 0)
    {
        return 0;
    }
    
    NSTimeInterval _playedAudioTime = 0.0;
    AudioTimeStamp time;
    OSStatus status = AudioQueueGetCurrentTime(aqData.mQueue, NULL, &time, NULL);
    if (status == noErr)
    {
        _playedAudioTime = time.mSampleTime / aqData.mDataFormat.mSampleRate;
    }
    
    return _playedAudioTime;
}

- (void)removePlayTimer {
    [_playTimer invalidate];
    _playTimer = nil;
}

- (void)addPlayTimer{
    if (!_playTimer) {
        _playTimer = [NSTimer scheduledTimerWithTimeInterval:.02f target:self selector:@selector(playTimeAdd) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_playTimer forMode:NSRunLoopCommonModes];
    }
}

@end
