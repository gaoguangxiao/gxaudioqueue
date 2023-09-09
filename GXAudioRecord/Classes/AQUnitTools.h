//
//  AQUnitTools.h
//  GXAudioRecord
//
//  Created by 高广校 on 2023/9/8.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface AQUnitTools : NSObject

+ (Float32 )getCurrentPower:(AudioQueueRef)aqQueue andDataFormat:(AudioStreamBasicDescription )mDataFormat;

@end

NS_ASSUME_NONNULL_END
