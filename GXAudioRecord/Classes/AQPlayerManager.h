//
//  AQPlayerManager.h
//  recordAudip
//
//  Created by 高广校 on 2023/8/24.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

/// 播放操作
@protocol GGXAudioQueuePlayOperation <NSObject>

- (void)didOutputAudioPeakPower:(float)audioPeak;

- (void)playAudioFinish;

@end

typedef NS_ENUM(NSInteger, AQPlayAudioPermission)
{
    //不容许SDK对AVAudioSession 进行更改, 由App进行SetActive和SetCategory
    AQPlayAudioPermissionNone = 1 << 0,
    //容许SDK对AVAudioSession进行SetCategory和Options。
    AQPlayAudioPermissionSetCategoryOptions = 1 << 1,
    //容许SDK对AVAudioSession进行SetActive。
    AQPlayAudioPermissionSetActive = 1 << 2,
    //容许SDK对AVAudioSession同时进行SetCategory和SetActive，默认值
    AQPlayAudioPermissionAll = AQPlayAudioPermissionSetCategoryOptions | AQPlayAudioPermissionSetActive,
};


@interface AQPlayerManager : NSObject

///数据源代理
@property (nonatomic, weak) id<GGXAudioQueuePlayOperation>aqDelegate;

// 播放音量
@property (nonatomic, assign) float volume;

//默认值AQPlayAudioPermissionAll
@property (nonatomic, assign) AQPlayAudioPermission avAudioSessionPermission; //

- (void)startPlay:(NSString *)filePath;

- (void)stopPlayer;
@end

NS_ASSUME_NONNULL_END

#pragma mark utility functions
static void CheckPlayError(OSStatus error, const char *operation) {
    if(error == noErr) return;
    
    char errorString[20];
    
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errorString[1]) && isprint(errorString[2]) &&isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
        
    } else { // No, format it as an integer
        sprintf(errorString, "%d", (int)error);
    }
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
//    exit(1);
}
//#endif /* GGXAudioQueueHeader_h */
