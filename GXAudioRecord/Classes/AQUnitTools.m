//
//  AQUnitTools.m
//  GXAudioRecord
//
//  Created by 高广校 on 2023/9/8.
//

#import "AQUnitTools.h"


@implementation AQUnitTools

+ (Float32 )getCurrentPower:(AudioQueueRef)aqQueue andDataFormat:(AudioStreamBasicDescription )mDataFormat {
    //获取levelMater属性
    UInt32 dataSize = sizeof(AudioQueueLevelMeterState) * mDataFormat.mChannelsPerFrame;
    AudioQueueLevelMeterState *levels = (AudioQueueLevelMeterState*)malloc(dataSize);
    //获取峰值信息
    OSStatus rc = AudioQueueGetProperty(aqQueue,
                                        kAudioQueueProperty_CurrentLevelMeterDB,
                                        levels,
                                        &dataSize);
    if (rc) {
        NSLog(@"NoiseLeveMeter>>takeSample - AudioQueueGetProperty(CurrentLevelMeter) returned %d", (int)rc);
    }
    //计算音量
    float channelAvg = 0;
    for (int i = 0; i < mDataFormat.mChannelsPerFrame; i++) {
        channelAvg += levels[i].mPeakPower;
    }
    free(levels);
    return channelAvg;
}

@end
