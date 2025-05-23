//
//  ParsingAudioHander.h
//  EditAudio
//
//  Created by yoyochecknow on 2021/5/27.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
NS_ASSUME_NONNULL_BEGIN

@interface ParsingAudioHander : NSObject

- (NSArray<NSNumber *> *)getRecorderDataFromURL:(NSURL *)url;

- (NSArray *)pcmDB:(NSURL *)aUrl;

- (void)synthetiAudioWithAudioPath:(NSString *)audioPath bgPath:(NSString *)bgPath outPath:(NSString *)outPath completion:(void (^_Nullable)(BOOL isSucess,NSString * path))completion;


@end





NS_ASSUME_NONNULL_END
