//
//  GGXAudioConvertor.h
//  GXAudioRecord
//
//  Created by 高广校 on 2023/9/10.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface GGXAudioConvertor : NSObject



+(void)convertCAFToM4A:(CMTime)source endTime:(CMTime)end inputPath:(NSURL *)inputpath outPath:(NSURL *)outPath andComplete:(void (^ _Nullable)(id _Nonnull))block;


/// caf转->m4a
/// - Parameters:
///   - path: <#path description#>
///   - outPath: <#outPath description#>
///   - block: <#block description#>
+(void)convertCAFToM4A:(NSURL *)path
               outPath:(NSURL *)outPath
           andComplete:(void (^ _Nullable)(id _Nonnull))block;

///  m4a转-wav
/// - Parameters:
///   - originalPath: <#originalPath description#>
///   - outputPath: <#outputPath description#>
///   - success: <#success description#>
///   - failure: <#failure description#>
+ (void)convertM4AToWAV:(NSString *)originalPath
                outPath:(NSString *)outputPath
                success:(void(^)(NSString *outputPath))success
                failure:(void(^)(NSError *error))failure;


/// 裁剪音频
/// - Parameters:
///   - timeRange: <#timeRange description#>
///   - outputSettings: <#outputSettings description#>
///   - originalPath: <#originalPath description#>
///   - outputPath: <#outputPath description#>
///   - block: <#block description#>
///   
+(void)tailorAudioTimeRange:(CMTimeRange)timeRange outSettings:(NSDictionary *)outputSettings inputPath:(NSString *)originalPath outPath:(NSString *)outputPath andComplete:(void (^ _Nullable)(id _Nonnull))block;

/// m4a转mp3
/// - Parameters:
///   - originalPath: <#originalPath description#>
///   - outputPath: <#outputPath description#>
///   - success: <#success description#>
///   - failure: <#failure description#>
+ (void)convertM4AToMp3:(NSString *)originalPath
                outPath:(NSString *)outputPath
                success:(void(^)(NSString *mp3Path))success
                failure:(void(^)(NSError *error))failure;
@end

NS_ASSUME_NONNULL_END
