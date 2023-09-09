//
//  AQPlayerManager.h
//  recordAudip
//
//  Created by 高广校 on 2023/8/24.
//

#import <Foundation/Foundation.h>
#import "GGXAudioQueueHeader.h"
NS_ASSUME_NONNULL_BEGIN

@interface AQPlayerManager : NSObject<GGXAudioQueueOperation>

- (instancetype)initAudioFormatType:(AudioFormatType)audioFormatType sampleRate:(Float64)sampleRate channels:(UInt32)channels bitsPerChannel:(UInt32)bitsPerChannel;

///数据源代理
@property (nonatomic, weak) id<GGXAudioQueueDataSource>aqDataSource;
@end

NS_ASSUME_NONNULL_END
