//
//  GGXAudioQueueHeader.h
//  recordAudip
//
//  Created by 高广校 on 2023/8/25.
//

#ifndef GGXAudioQueueHeader_h
#define GGXAudioQueueHeader_h

#define kDefaultSampleRate 44100 //采样率
#define kDefaultChannels 1 //声道数
#define kDefaultBitsPerChannel 16 //采样/量化 位深

//#define kDefaultMaxPeak 0.2 //阈值 0.2 对应metellevel
//#define kDefaultMaxPeak -60 //采集设备为6 对应metellevelDB -60
#define kDefaultMaxPeak -50 //采集设备为7 对应metellevelDB -50

#define KMaxDepthPREF 32767
#define KDefaultLimitMaxDb -3.0

//横线间隔
#define kAudioPlayerLineSpacing 4

@class AQRecorderManager;
#import <CoreMedia/CoreMedia.h>
typedef NS_ENUM(NSInteger, AudioFormatType) {
    AudioFormatLinearPCM,
    AudioFormatMPEG4AAC,
};

@protocol GGXAudioQueueDataSource <NSObject>

- (void)didOutputAudioPeakPower:(float)audioPeak;


- (void)recorderManager:(AQRecorderManager *_Nonnull)recorderManager didOutputAudiofile:(CMTime )sTime andEndTime:(CMTime)eTime andFilePath:(NSURL *_Nullable)filePath;

///  时间
/// - Parameters:
///   - recorderManager: <#recorderManager description#>
///   - endTime: <#endTime description#>

@end

@protocol GGXAudioQueueOperation <NSObject>

- (void)recorderStopRecordForLowPeak;

- (void)startRecordWithFilePath:(NSString *)filePath;

- (void)startPlay:(NSString *)filePath;
@end

#pragma mark utility functions
static void CheckError(OSStatus error, const char *operation) {
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
#endif /* GGXAudioQueueHeader_h */
