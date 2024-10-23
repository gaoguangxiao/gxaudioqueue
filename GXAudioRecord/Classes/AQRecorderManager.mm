//
//  AQRecorderManager.m
//  recordAudip
//
//  Created by gaoyu on 2021/6/7.
// https://www.jianshu.com/p/d64c74deb580

#import "AQRecorderManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>
#import "GGXFileManeger.h"
#import "AQUnitTools.h"
#import "GGXAudioConvertor.h"
/// 自定义结构体
static const int kNumberBuffers = 3;
typedef struct AQRecorderState {
    AudioStreamBasicDescription  mDataFormat;
    AudioQueueRef                mQueue; //应用程序创建的录制音频队列
    AudioQueueBufferRef          mBuffers[kNumberBuffers];//音频队列中音频数据指针的数组
    AudioFileID                  mAudioFile;//录制的文件
    UInt32                       bufferByteSize;//当前录制文件的大小
    SInt64                       mCurrentPacket;
    bool                         mIsRunning;//当前音频队列是否正在运行
    
    bool                         mIsWritePackets;//是否开始写入数据，音量达到0.05
    
    //    CMTime
    bool                         mIsEndTime;     //是否开始进入结尾倒计时
    float                        mMaxEndDownTime;//3秒
    float                        mEndDownTimeIndex;//
    
    AQRecorderManager            *recorderManager;//类实例
} AQRecorderState;


#pragma mark Calculate DB
enum ChannelCount
{
    k_Mono = 1,
    k_Stereo
};

void caculate_bm_dbV2(void * const data, UInt32 numberOfSamples) {
    float gain = 3.0f; // 增益因子
    //限幅
    double maxDepth  =  pow(10, KDefaultLimitMaxDb/20);
    double maxDepthPref = maxDepth * KMaxDepthPREF;
//    NSLog(@"限制分贝转采样值 %f",maxDepthPref);//0.7
    SInt16 *curData = (SInt16 *)data;
    for (int pos = 0; pos < numberOfSamples; pos += 2, ++curData) {
        SInt16 data = *curData;
        data *= gain;
        if (data > maxDepthPref) {
//            NSLog(@"太大了 %hd",data);
            data = maxDepthPref;
        } else if (data < -maxDepthPref) {
//            NSLog(@"太小了 %hd",data);
            data = -maxDepthPref;
        }
        *curData = data;
    }
}

void caculate_bm_db(void * const data ,size_t length ,int64_t timestamp, ChannelCount channelModel,
                    float channelValue[2],bool isAudioUnit,double maxDepthPref) {
    int16_t *curData = (int16_t *)data;
    
    if (channelModel == k_Mono) {
//        int     sDbChnnel     = 0;
//        int16_t max           = 0;
        size_t traversalTimes = length;
        for (int pos = 0; pos < traversalTimes; pos += 2, ++curData) {
            int data = *curData;
            NSLog(@"data is :%ld",(long)data);
            {
                if (data > 0) {
                    NSInteger cDB = 20*log10(data);//当前分贝
                    NSInteger ncDB = cDB + 10;
//                    NSLog(@"当前录制:%ld",(long)cDB);
//                    NSLog(@"当前增益录制:%ld",(long)ncDB);
                    double addDepth =  pow(10, ncDB/20);
                    double addDepthPref = addDepth * KMaxDepthPREF;
                    if (data > 0) {
                        data = data + addDepthPref;
                    } else {
                        data = data - addDepthPref;
                    }
                } else {
                    
                }
                
                if (data > maxDepthPref) {
                    data = maxDepthPref;
                } else if (data < -maxDepthPref) {
                    data = -maxDepthPref;
                }
            }
            *curData = data;
//            if(data > max) max = data;
        }
        
//        if(max < 1) {
//            sDbChnnel = -100;
//        }else {
//            sDbChnnel = (20*log10((max)/32767) - 0.5);
//        }
//        
//        channelValue[0] = sDbChnnel;
        
    } else if (channelModel == k_Stereo){
        int sDbChA = 0;
        int sDbChB = 0;
        
        int16_t nCurr[2] = {0};
        int16_t nMax[2] = {0};
        
        for(unsigned int i=0; i<length/2; i++) {
            nCurr[0] = curData[i];
            nCurr[1] = curData[i + 1];
            
            if(nMax[0] < nCurr[0]) nMax[0] = nCurr[0];
            
            if(nMax[1] < nCurr[1]) nMax[1] = nCurr[0];
        }
        
        if(nMax[0] < 1) {
            sDbChA = -100;
        } else {
            sDbChA = (20*log10((0.0 + nMax[0])/32767) - 0.5);
        }
        
        if(nMax[1] < 1) {
            sDbChB = -100;
        } else {
            sDbChB = (20*log10((0.0 + nMax[1])/32767) - 0.5);
        }
        
        channelValue[0] = sDbChA;
        channelValue[1] = sDbChB;
    }
}


//tatic void HandleInputBuffer (
//    void                                 *aqData,//用户数据指针
//    AudioQueueRef                        inAQ, //
//    AudioQueueBufferRef                  inBuffer, 装有音频数据的
//    const AudioTimeStamp                 *inStartTime,
//    UInt32                               inNumPackets,
//    const AudioStreamPacketDescription   *inPacketDesc
//) {

/// 处理回调函数
static void HandleInputBuffer (
                               void                                 *aqData,
                               AudioQueueRef                        inAQ,
                               AudioQueueBufferRef                  inBuffer,
                               const AudioTimeStamp                 *inStartTime,
                               UInt32                               inNumPackets,
                               const AudioStreamPacketDescription   *inPacketDesc
                               ) {
    AQRecorderState *pAqData = (AQRecorderState *)aqData;
    
    AQRecorderManager *audioRecorder = pAqData->recorderManager;
    
    //    se inBuffer->mUserData;
    if (inNumPackets == 0 && pAqData->mDataFormat.mBytesPerPacket != 0) {
        inNumPackets = inBuffer->mAudioDataByteSize / pAqData->mDataFormat.mBytesPerPacket;
    }
    //获取音量
    // Get DB
//    float channelValue[2];
//    double maxDepth  =  pow(10, KDefaultLimitMaxDb/20);
//    double maxDepthPref = maxDepth * KMaxDepthPREF;
//    caculate_bm_db(inBuffer->mAudioData, inBuffer->mAudioDataByteSize, 0, k_Mono, channelValue,true,maxDepthPref);
    
    caculate_bm_dbV2((SInt16 *)inBuffer->mAudioData,inBuffer->mAudioDataByteSize);
    
    //提升录音分贝
    //    NSLog(@"根据AudioData计算的分贝%.2f",channelValue[0]);
    
    //mAudioFile 要写入的音频文件
    //false 写入文件不需要缓存文件
    //mAudioDataByteSize 被写入文件大小
    //
    OSStatus writeStatus = AudioFileWritePackets(pAqData->mAudioFile,
                                                 false,
                                                 inBuffer->mAudioDataByteSize,
                                                 inPacketDesc,
                                                 pAqData->mCurrentPacket,
                                                 &inNumPackets,
                                                 inBuffer->mAudioData);
    if (writeStatus == noErr) {
        pAqData->mCurrentPacket += inNumPackets;
    }
    
    if (pAqData->mIsRunning == false) {
        return;
    }
    
    //获取音频总时长
    //将buffer给audio queue
    //用于音频数据使用完毕，需要重新放回音频队列以存储新的音频数据
    //    inBuffer 等待入队的音频数据
    AudioQueueEnqueueBuffer(pAqData->mQueue,
                            inBuffer,
                            0,
                            NULL);
}


/// 设置缓冲区大小
void DeriveBufferSize (AudioQueueRef audioQueue,
                       AudioStreamBasicDescription &ASBDescription,
                       Float64  seconds,
                       UInt32   *outBufferSize) {
    
    int packets, frames, bytes = 0;
    
    frames = (int)ceil(seconds * ASBDescription.mSampleRate);
    
    if (ASBDescription.mBytesPerFrame > 0)
        bytes = frames * ASBDescription.mBytesPerFrame;
    else {
        UInt32 maxPacketSize;
        if (ASBDescription.mBytesPerPacket > 0)
            maxPacketSize = ASBDescription.mBytesPerPacket;    // constant packet size
        else {
            UInt32 propertySize = sizeof(maxPacketSize);
            AudioQueueGetProperty(audioQueue,
                                  kAudioQueueProperty_MaximumOutputPacketSize,
                                  &maxPacketSize,
                                  &propertySize);
        }
        if (ASBDescription.mFramesPerPacket > 0)
            packets = frames / ASBDescription.mFramesPerPacket;
        else
            packets = frames;    // worst-case scenario: 1 frame in a packet
        if (packets == 0)        // sanity check
            packets = 1;
        bytes = packets * maxPacketSize;
    }
    
    *outBufferSize = bytes;
}

OSStatus SetMagicCookieForFile (
                                AudioQueueRef inQueue,
                                AudioFileID   inFile
                                ) {
    OSStatus result = noErr;
    UInt32 cookieSize;
    
    if (
        AudioQueueGetPropertySize (
                                   inQueue,
                                   kAudioQueueProperty_MagicCookie,
                                   &cookieSize
                                   ) == noErr
        ) {
            char* magicCookie =
            (char *) malloc (cookieSize);
            if (
                AudioQueueGetProperty (
                                       inQueue,
                                       kAudioQueueProperty_MagicCookie,
                                       magicCookie,
                                       &cookieSize
                                       ) == noErr
                )
                result =    AudioFileSetProperty (
                                                  inFile,
                                                  kAudioFilePropertyMagicCookieData,
                                                  cookieSize,
                                                  magicCookie
                                                  );
            free (magicCookie);
        }
    return result;
}


@interface AQRecorderManager () {
    AQRecorderState aqData;
}

@property (nonatomic, assign) CMTime startTime;
@property (nonatomic, assign) CMTime endTime;

@property (nonatomic, strong) NSTimer *timer; //录制结束控制
@property (nonatomic, assign) float stopTimeIndex;

@property (nonatomic, strong) NSTimer *recordTimer;//录制音频时长控制
@property (nonatomic, assign) float recordTimeIndex;

@property (nonatomic, copy) NSString *LocalfilePath;
@end

@implementation AQRecorderManager

- (instancetype)initAudioFormatType:(AudioFormatType)audioFormatType sampleRate:(Float64)sampleRate channels:(UInt32)channels bitsPerChannel:(UInt32)bitsPerChannel {
    self = [super init];
    if (self) {
        [self initRecord];
        
        [self setAudioFormatType:audioFormatType
                      sampleRate:sampleRate
                        channels:channels
                  bitsPerChannel:bitsPerChannel];
    }
    return self;
}

- (void)initRecord {
    aqData.recorderManager = self;
    
    self.isCutsilentHeadTail = NO;
    
    self.stopRecordDBLevel = kDefaultMaxPeak;
}

- (void)setAudioFormatType:(AudioFormatType)audioFormatType
                sampleRate:(Float64)sampleRate
                  channels:(UInt32)channels
            bitsPerChannel:(UInt32)bitsPerChannel {
    aqData.mDataFormat.mSampleRate = sampleRate > 0 ? sampleRate : kDefaultSampleRate;
    aqData.mDataFormat.mChannelsPerFrame = channels > 0 ? channels : kDefaultChannels;
    
    if (audioFormatType == AudioFormatLinearPCM) {
        
        aqData.mDataFormat.mFormatID = kAudioFormatLinearPCM;
        aqData.mDataFormat.mBitsPerChannel = bitsPerChannel > 0 ? bitsPerChannel : kDefaultBitsPerChannel;
        aqData.mDataFormat.mBytesPerPacket =
        aqData.mDataFormat.mBytesPerFrame = (aqData.mDataFormat.mBitsPerChannel / 8) * aqData.mDataFormat.mChannelsPerFrame;
        aqData.mDataFormat.mFramesPerPacket = 1;
        aqData.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        
    } else if (audioFormatType == AudioFormatMPEG4AAC) {
        
        aqData.mDataFormat.mFormatID = kAudioFormatMPEG4AAC;
        aqData.mDataFormat.mFormatFlags = kMPEG4Object_AAC_Main;
        
    }
}

- (void)setIsEnableMeter:(BOOL)isEnableMeter {
    _isEnableMeter = isEnableMeter;
}

- (void)setIsCutsilentHeadTail:(BOOL)isCutsilentHeadTail {
    _isCutsilentHeadTail = isCutsilentHeadTail;
}

- (void)setStopRecordDBLevel:(float)stopRecordDBLevel {
    _stopRecordDBLevel = stopRecordDBLevel;
}

#pragma mark - 录音功能
- (void)initAudioQueueBeforeRecord {
    //1、创建音频队列
    /*
     mDataFormat：指定录制的音频格式
     HandleInputBuffer：指定的回调函数
     aqData 可传入自定义的数据结构,可以是本类的实例,可以是记录音频信息的结构体
     
     mQueue：输出时新分配的音频队列.
     */
    OSStatus queueStatus = AudioQueueNewInput(&aqData.mDataFormat,
                                              HandleInputBuffer,
                                              &aqData,
                                              NULL,
                                              kCFRunLoopCommonModes,
                                              0,
                                              &aqData.mQueue);
    if (queueStatus != noErr) {
        NSLog(@"创建音频队列失败: %d", queueStatus);
        return;
    }
    
    //2、设置magic cookie
    //    if (aqData.mDataFormat.mFormatID != kAudioFormatLinearPCM) {
    //        SetMagicCookieForFile(aqData.mQueue, aqData.mAudioFile);
    //    }
    
    //2、设置缓冲区大小
    DeriveBufferSize(aqData.mQueue,
                     aqData.mDataFormat,
                     0.5,
                     &aqData.bufferByteSize);
    
    //3、创建音频队列缓冲区
    for (int i = 0; i < kNumberBuffers; ++i) {
        OSStatus allocBufferStatus = AudioQueueAllocateBuffer(aqData.mQueue,
                                                              aqData.bufferByteSize,
                                                              &aqData.mBuffers[i]);
        if (allocBufferStatus != noErr) {
            NSLog(@"分配缓冲区失败：%d", allocBufferStatus);
            return;
        }
        
        //音频队列入队，将
        OSStatus enqueueStatus = AudioQueueEnqueueBuffer(aqData.mQueue,
                                                         aqData.mBuffers[i],
                                                         0,
                                                         NULL);
        if (enqueueStatus != noErr) {
            NSLog(@"缓冲区排队失败：%d", enqueueStatus);
            return;
        }
    }
}

- (void)startRecordWithFilePath:(NSString *)filePath {
    
    //设置会话
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    //    UInt32 dataFormatSize = sizeof(aqData.mDataFormat);
    //    AudioQueueGetProperty(aqData.mQueue,
    //                          kAudioQueueProperty_StreamDescription,
    //                          &aqData.mDataFormat,
    //                          &dataFormatSize);
    
    [self initAudioQueueBeforeRecord];
    
    //设置音量检测是否开启
    [self setEnableUpdateLevelMetering];
    
    AudioFileTypeID fileTypeID = [self getAudioFileByPath:filePath];
    
    self.LocalfilePath = filePath;
    //    NSLog(@"----- %@", filePath);
    CFURLRef audioFileURL = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)filePath, NULL);
    
    OSStatus fileStatus = AudioFileCreateWithURL(audioFileURL,
                                                 fileTypeID,
                                                 &aqData.mDataFormat,
                                                 kAudioFileFlags_EraseFile,
                                                 &aqData.mAudioFile);
    CFRelease(audioFileURL);
    if (fileStatus != noErr) {
        NSLog(@"创建文件失败：%d", fileStatus);
        return;
    }
    
    aqData.mIsEndTime        = false;//
    aqData.mEndDownTimeIndex = 0;
    aqData.mMaxEndDownTime   = 3;
    
    aqData.mIsWritePackets = false;
    
    aqData.mCurrentPacket = 0;
    aqData.mIsRunning = true;
    
    //开始录音
    OSStatus startStatus = AudioQueueStart(aqData.mQueue, NULL);
    if (startStatus != noErr) {
        NSLog(@"开始录音失败：%d", startStatus);
        return;
    }
    //成功录音，开启录制声音
    [self addRecordTimer];
}

- (void)recoedTimeAdd {
    //    AudioTimeStamp *ats =  (AudioTimeStamp *)inStartTime;
    if (self.isEnableMeter) {
        float avaValue = [self getCurrentPower];
        //如果音量足够 开始写入数据
        if (avaValue >= self.stopRecordDBLevel) {
            if (aqData.mIsWritePackets) {
                //正在写入数据
                //音量大于阈值时，结束倒计时
                aqData.mIsEndTime = false;
                [self removeTimer];
            } else {
                
                Float64 timeInterval = [self getRecordTime];
                NSLog(@"开始写入数据:%.2f",timeInterval);
                
                self.startTime = CMTimeMakeWithSeconds(timeInterval - 0.2, 600);
                
                aqData.mIsWritePackets = true;
            }
        } else {
            //音量不满足阈值
            if (aqData.mIsWritePackets) {//写入数据中
                
                if (aqData.mIsEndTime) {
                    //音量低，写入数据，并且开启倒计时状态
                    
                } else {
                    aqData.mIsEndTime = true;
                    
                    aqData.mEndDownTimeIndex = 0.1;
                    //进入低音计时
                    [self addBassTimer];
                }
            }
        }
        
        
        if (self.aqDataSource && [self.aqDataSource respondsToSelector:@selector(didOutputAudioPeakPower:)]) {
            [self.aqDataSource didOutputAudioPeakPower:avaValue];
        }
    }
}

- (void)setEnableUpdateLevelMetering {
    UInt32 val = self.isEnableMeter ? 1 : 0;
    CheckError(AudioQueueSetProperty(aqData.mQueue,
                                     kAudioQueueProperty_EnableLevelMetering,
                                     &val,
                                     sizeof(UInt32)), "EnableLevelMetering");
}

- (void)stopRecord {
    //判断是否进行低音计时
    Float64 timeInterval = [self getRecordTime];
    NSLog(@"音频录制时间：%.2f",timeInterval);
    if (aqData.mIsEndTime) {
        //        NSLog(@"尾部空白时间：%.2f",aqData.mEndDownTimeIndex);
        //        NSLog(@"");
        //        NSLog(@"开始结束数据截取:%.2f",timeInterval - aqData.mEndDownTimeIndex);
        self.endTime = CMTimeMakeWithSeconds(timeInterval - aqData.mEndDownTimeIndex, 600);
    } else {
        self.endTime = CMTimeMakeWithSeconds(timeInterval, 600);
    }
    
    aqData.mIsRunning = false;
    AudioQueueStop(aqData.mQueue, true);
    
    // 录音结束后再次调用magic cookies，一些编码器会在录音停止后更新magic cookies数据
    if (aqData.mDataFormat.mFormatID != kAudioFormatLinearPCM) {
        SetMagicCookieForFile(aqData.mQueue, aqData.mAudioFile);
    }
    
    AudioQueueDispose(aqData.mQueue, true);
    AudioFileClose(aqData.mAudioFile);
    
    //停止时低音倒计时
    [self removeTimer];
    
    //停止录制监听倒计时
    [self removeRecordTimer];
    
    if (self.isCutsilentHeadTail) {
        //需要裁剪
        NSLog(@"头部剪辑：%.2f",CMTimeGetSeconds(self.startTime));
        NSLog(@"尾部剪辑：%.2f",CMTimeGetSeconds(self.endTime));
        //内部裁剪
        NSString *outwavPath = [GGXFileManeger.shared createFilePathWithFormat:@"wav"];
        
        /** 配置音频参数 */
        NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:aqData.mDataFormat.mFormatID], AVFormatIDKey,
                                        [NSNumber numberWithFloat:aqData.mDataFormat.mSampleRate], AVSampleRateKey,
                                        [NSNumber numberWithInt:aqData.mDataFormat.mBitsPerChannel], AVLinearPCMBitDepthKey,
                                        [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                        [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                        [NSNumber numberWithInt:aqData.mDataFormat.mChannelsPerFrame],AVNumberOfChannelsKey,
                                        nil];
        //         AVLinearPCMIsNonInterleaved 是否允许音频交叉他的值
        //        AVLinearPCMIsFloatKey 是否支持浮点处理
        //        AVLinearPCMIsBigEndianKey 大端模式 小端模式。内存的组织形式
        [GGXAudioConvertor tailorAudioTimeRange:CMTimeRangeMake(self.startTime, self.endTime) outSettings:outputSettings inputPath:self.LocalfilePath outPath:outwavPath andComplete:^(NSString * _Nonnull outputPath) {
            //输出的路径
            NSLog(@"outputPath:%@",outputPath);
            if (self.aqDataSource && [self.aqDataSource respondsToSelector:@selector(recorderManager:andFilePath:)]) {
                [self.aqDataSource recorderManager:self andFilePath:outputPath];
            }
            
        }];
    } else {
        
        if (self.aqDataSource && [self.aqDataSource respondsToSelector:@selector(recorderManager:didOutputAudiofile:andEndTime:andFilePath:)]) {
            [self.aqDataSource recorderManager:self didOutputAudiofile:self.startTime andEndTime:self.endTime andFilePath:[NSURL fileURLWithPath:self.LocalfilePath]];
        }
    }
}

//获取当前录制时间
- (Float64)getRecordTime {
    Float64 timeInterval = 0;
    AudioQueueTimelineRef timeLine;
    OSStatus status = AudioQueueCreateTimeline(aqData.mQueue, &timeLine);
    if (status == noErr) {
        AudioTimeStamp timeStamp;
        AudioQueueGetCurrentTime(aqData.mQueue, timeLine, &timeStamp, NULL);
        timeInterval = timeStamp.mSampleTime / aqData.mDataFormat.mSampleRate; // modified
        //        NSLog(@"当前录音时长：%.2f",timeInterval);
    }
    return timeInterval;
}

- (Float32 )getCurrentPower {
    return [AQUnitTools getCurrentPower:aqData.mQueue andDataFormat:aqData.mDataFormat];
}

- (AudioFileTypeID)getAudioFileByPath:(NSString *)path{
    if ([path.pathExtension isEqualToString:@"wav"]) {
        return kAudioFileWAVEType;
    } else if ([path.pathExtension isEqualToString:@"caf"]) {
        return kAudioFileCAFType;
    }
    
    return kAudioFileWAVEType;
}

- (void)addPoint:(NSTimer *)timer {
    aqData.mEndDownTimeIndex += 0.1;
    
    NSLog(@"结束倒计时：%.2f",aqData.mEndDownTimeIndex);
    if (aqData.mEndDownTimeIndex >= aqData.mMaxEndDownTime) {
        NSLog(@"停止录制");
        [self stopRecord];
        
        if (self.aqDelegate && [self.aqDelegate respondsToSelector:@selector(recorderStopRecordForLowPeak)]) {
            [self.aqDelegate recorderStopRecordForLowPeak];
        }
    }
}

#pragma mark - 定时器
- (void)removeTimer {
    [_timer invalidate];
    _timer = nil;
}

//添加低音倒计时
- (void)addBassTimer{
    if (!_timer) {
        //添加定时器
        _timer = [NSTimer scheduledTimerWithTimeInterval:.1f target:self selector:@selector(addPoint:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}

- (void)removeRecordTimer {
    [_recordTimer invalidate];
    _recordTimer = nil;
}

- (void)addRecordTimer{
    if (!_recordTimer) {
        _recordTimer = [NSTimer scheduledTimerWithTimeInterval:.1f target:self selector:@selector(recoedTimeAdd) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_recordTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)dealloc {
    NSLog(@"--- dealloc ---");
    AudioQueueStop(aqData.mQueue, true);
    AudioQueueDispose(aqData.mQueue, true);
    AudioFileClose(aqData.mAudioFile);
}

- (BOOL)isRecording {
    return aqData.mIsRunning ? YES : NO;
}

@end
