//
//  MusicControl.h
//  ZKNASProj
//
//  Created by mac_1104 on 2022/8/23.
//


#ifndef MusicControl_h
#define MusicControl_h

typedef NS_OPTIONS(NSUInteger, MediaLoadState) {
    MediaLoadStateUnknown        = 0,
    MediaLoadStatePlayable       = 1 << 0,
    MediaLoadStatePlaythroughOK  = 1 << 1, // Playback will be automatically started in this state when shouldAutoplay is YES
    MediaLoadStateStalled        = 1 << 2, // Playback will be automatically paused in this state, if started
};


typedef NS_ENUM(NSInteger, MediaPlaybackState) {
    MediaPlaybackStateStopped,
    MediaPlaybackStatePlaying,
    MediaPlaybackStatePaused,
    MediaPlaybackStateEnded,
    MediaPlaybackStateEndedError,
    MediaPlaybackStateInterrupted,
    MediaPlaybackStateSeekingForward,
    MediaPlaybackStateSeekingBackward
};


NS_ASSUME_NONNULL_BEGIN

@protocol MusicControlDelegate <NSObject>

@optional
- (void)mediaPlaybackIsPreparedToPlay;
- (void)mediaPlayerLoadStateDidChange:(NSUInteger)state;
- (void)mediaPlayBackStateDidChange:(MediaPlaybackState )state;
- (void)mediaPlayBackDidFinish:(MediaPlaybackState)finishReason;

@end

@interface MusicControl : NSObject
//@property (nonatomic) float playbackRate;
//@property (nonatomic) float playbackVolume;

@property(nonatomic)            NSTimeInterval currentPlaybackTime;
@property(nonatomic, readwrite) NSTimeInterval duration;
@property(nonatomic, readwrite) NSTimeInterval playableDuration;
@property(nonatomic, readwrite) NSInteger bufferingProgress;

@property(nonatomic)  BOOL isPreparedToPlay;
@property(nonatomic)  BOOL isCompleted;

@property (nonatomic, weak) id <MusicControlDelegate> delegate;

- (void)prepareToPlayURL:(NSURL *)url;

- (void)prepareToPlay;
- (void)play;
- (void)pause;
- (void)stop;
- (void)shutdown;
- (BOOL)isPlaying;

- (instancetype)initWithContentURL:(NSURL *)aUrl;
@end

NS_ASSUME_NONNULL_END

#endif /* MusicControl_h */
