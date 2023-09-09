//
//  AQRecorderManager.h
//  recordAudip
//
//  Created by gaoyu on 2021/6/7.
//

#import <Foundation/Foundation.h>
#import "GGXAudioQueueHeader.h"
#import <AudioToolbox/AudioToolbox.h>

@interface AQRecorderManager : NSObject<GGXAudioQueueOperation>

@property (nonatomic, assign, readonly) BOOL isRecording;

/// 设置音频数据属性
/// @param audioFormatType 音频格式 AudioFormatType
/// @param sampleRate 采样率
/// @param channels 声道
/// @param bitsPerChannel 位深度
- (instancetype)initAudioFormatType:(AudioFormatType)audioFormatType
                         sampleRate:(Float64)sampleRate
                           channels:(UInt32)channels
                     bitsPerChannel:(UInt32)bitsPerChannel;

@property (nonatomic, weak) id<GGXAudioQueueOperation> aqDelegate;
///数据源代理
@property (nonatomic, weak) id<GGXAudioQueueDataSource>aqDataSource;

///是否开启音量检查
@property (nonatomic, assign) BOOL isEnableMeter;

///设置自动停止线单位DB
@property (nonatomic, assign) NSInteger stopRecordDBLevel;

///是否开启自动停止录制 默认NO
@property (nonatomic, assign) BOOL isAutoStopRecord;

///是否裁剪停止线之外的首位
@property (nonatomic, assign) BOOL isCutsilentHeadTail;

//默认
@property (nonatomic, assign) CGFloat loudnessValue;
//- (void)startRecord;

- (void)stopRecord;

- (void)addBassTimer;

- (void)removeTimer;

- (Float32 )getCurrentPower;

@end
