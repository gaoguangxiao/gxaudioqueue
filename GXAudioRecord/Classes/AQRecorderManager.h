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

/// 最小音量回调
@property (nonatomic, assign) float minVolumeCallbackTime;

/// 是否设置静音检测：默认Yes
@property (nonatomic, assign) BOOL isVad;

///设置自动停止线单位DB 默认-50
@property (nonatomic, assign) float stopRecordDBLevel;

//静音检测时间 默认3秒
@property (nonatomic, assign) float sliceTime;


-(int)getPCMDB:(NSData* )buffer;

/// 重新记录静音
- (void)resetSliceTimedown;

///是否开启自动停止录制 默认NO
@property (nonatomic, assign) BOOL isAutoStopRecord;

///自动停止录制时长 默认3秒
@property (nonatomic, assign) float stopRecordMaxTime;

/**
 * 是否裁剪停止线之外的首尾 需要开启音量检查，stopRecordDBLevel默认3db
 * 设置fause
 */
///
@property (nonatomic, assign) BOOL isCutsilentHeadTail;

//默认
@property (nonatomic, assign) CGFloat loudnessValue;

//可写入文件
- (void)startWriteRecord;

- (void)stopRecord;

///取消录制-无返回结果
- (void)cancelRecord;

- (void)addBassTimer;

//- (void)removeTimer;

- (Float32 )getCurrentPower;

@end
