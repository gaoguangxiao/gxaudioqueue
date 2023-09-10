//
//  MusicControl.m
//  ZKNASProj
//
//  Created by mac_1104 on 2022/8/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MusicControl.h"
//#import "MediaDefine.h"

NSString *const AVNaturalSizeAvailableNotification = @"AVNaturalSizeAvailableNotification";
static const float kMaxHighWaterMarkMilli   = 15 * 1000;

static bool isFloatZero(float value)
{
    return fabsf(value) <= 0.00001f;
}

@interface MusicControl (){
    BOOL _isPrerolling;

    NSTimeInterval _seekingTime;

    
    BOOL _isError;
    BOOL _isCompleted;
    BOOL _isShutdown;
    
    BOOL _pauseInBackground;
    
    BOOL _playbackLikelyToKeeyUp;
    BOOL _playbackBufferEmpty;
    BOOL _playbackBufferFull;
    
    dispatch_once_t _readyToPlayToken;
    float _playbackRate;
    float _playbackVolume;

    BOOL _audioSessionInitialized;
}

@property(nonatomic, strong) AVPlayer *player;
@property(nonatomic, strong) NSURL *playUrl;
@property(nonatomic, strong) AVURLAsset      *playAsset;
@property(nonatomic, strong) AVPlayerItem    *playerItem;
@property(nonatomic) BOOL isPrerolling;
@property(nonatomic) BOOL isSeeking;


@end

@implementation MusicControl

- (instancetype)init {
    if (self = [super init]) {
        
        [self initObject];
        
        [self setupAudioSession];
        
    }
    return self;
}

- (instancetype)initWithContentURL:(NSURL *)aUrl
{
    self = [super init];
    if (self != nil) {
//        self.scalingMode = IJKMPMovieScalingModeAspectFit;
//        self.shouldAutoplay = NO;
        _playUrl = aUrl;

        // TODO:
        [self setupAudioSession];

        [self initObject];
        // init extra
//        [self setScreenOn:YES];

//        _notificationManager = [[IJKNotificationManager alloc] init];
    }
    return self;
}

- (void)initObject {
    _isPrerolling           = NO;

    _isSeeking              = NO;
    _isError                = NO;
    _isCompleted            = NO;
    self.bufferingProgress  = 0;

    _playbackLikelyToKeeyUp = NO;
    _playbackBufferEmpty    = YES;
    _playbackBufferFull     = NO;

    _playbackRate           = 1.0f;
    _playbackVolume         = 1.0f;

    _audioSessionInitialized = NO;
    _readyToPlayToken = 0;
}

- (void)setupAudioSession
{
    if (!_audioSessionInitialized) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(audioSessionInterrupt:)
                                                     name: AVAudioSessionInterruptionNotification
                                                   object: [AVAudioSession sharedInstance]];
        _audioSessionInitialized = YES;
    }

    /* Set audio session to mediaplayback */
    NSError *error = nil;
    if (NO == [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error]) {
        NSLog(@"IJKAudioKit: AVAudioSession.setCategory() failed: %@\n", error ? [error localizedDescription] : @"nil");
        return;
    }

    error = nil;
    if (NO == [[AVAudioSession sharedInstance] setActive:YES error:&error]) {
        NSLog(@"IJKAudioKit: AVAudioSession.setActive(YES) failed: %@\n", error ? [error localizedDescription] : @"nil");
        return;
    }

    return ;
}

- (void)setActive:(BOOL)active
{
    if (active != NO) {
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    } else {
        @try {
            [[AVAudioSession sharedInstance] setActive:NO error:nil];
        } @catch (NSException *exception) {
            NSLog(@"failed to inactive AVAudioSession\n");
        }
    }
}

- (void)handleInterruption:(NSNotification *)notification
{
    int reason = [[[notification userInfo] valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    switch (reason) {
        case AVAudioSessionInterruptionTypeBegan: {
            NSLog(@"AVAudioSessionInterruptionTypeBegan\n");
            [self setActive:NO];
            break;
        }
        case AVAudioSessionInterruptionTypeEnded: {
            NSLog(@"AVAudioSessionInterruptionTypeEnded\n");
            [self setActive:YES];
            break;
        }
    }
}

- (void)prepareToPlayURL:(NSURL *)url {

    _playUrl = url;
    
    [self prepareToPlay];
}

- (void)prepareToPlay
{
    self.playAsset = nil;
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_playUrl options:nil];
    NSArray *requestedKeys = @[@"playable"];
        
    self.playAsset = asset;

    __weak typeof(self) weakSelf =  self;
//    weakSelf(self);
    [asset loadValuesAsynchronouslyForKeys:requestedKeys
                         completionHandler:^{
                             dispatch_async( dispatch_get_main_queue(), ^{
                                 [weakSelf didPrepareToPlayAsset:asset withKeys:requestedKeys];
//                                 [[NSNotificationCenter defaultCenter]
//                                  postNotificationName:AVNaturalSizeAvailableNotification
//                                  object:self];

                                 [weakSelf setPlaybackVolume:weakSelf.playbackVolume];
                             });
                         }];
}

- (void)play
{
    if (_isCompleted)
    {
        NSLog(@"play _isCompleted ");
        _isCompleted = NO;
        //nas流媒体不起作用,网络流媒体可以
//        weakSelf(self);
//        [_player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
//            [weakself.player play];
//            return;
//        }];
        [self initObject];
        [self prepareToPlay];
    } else {
        NSLog(@"play _isCompleted no ");
        [_player play];
    }
}

- (void)pause
{
    _isPrerolling = NO;
    [_player pause];
}

- (void)stop
{
    [_player pause];
//    [self setScreenOn:NO];
    _isCompleted = YES;
    
    //播放状态
    if(self.delegate && [self.delegate respondsToSelector:@selector(mediaPlayBackDidFinish:)]) {
        [self.delegate mediaPlayBackDidFinish:MediaPlaybackStateStopped];
    }
}

- (BOOL)isPlaying
{
    NSLog(@"_isprerolling:%@", _isPrerolling?@"YES":@"NO");
//    NSLog(@"rate:%f", _player.rate);

    if (!isFloatZero(_player.rate)) {
        return YES;
    } else {
        if (_isPrerolling) {
            return YES;
        } else {
            return NO;
        }
    }
}

- (void)shutdown
{
    _isShutdown = YES;
    [self stop];
    
    if (_playerItem != nil) {
        [_playerItem cancelPendingSeeks];
    }
    
    [self unregisterKVOForPlayerItem];
    [self unregisterKVOForPlayer];
    
    [self unregisterObservers];
    //[self unregisterApplicationObservers];
}

-(void)setPlaybackRate:(float)playbackRate
{
    _playbackRate = playbackRate;
    if (_player != nil && !isFloatZero(_player.rate)) {
        _player.rate = _playbackRate;
    }
}

-(float)playbackRate
{
    return _playbackRate;
}

-(void)setPlaybackVolume:(float)playbackVolume
{
    _playbackVolume = playbackVolume;
    if (_player != nil && _player.volume != playbackVolume) {
        _player.volume = playbackVolume;
    }
    BOOL muted = fabs(playbackVolume) < 1e-6;
    if (_player != nil && _player.muted != muted) {
        _player.muted = muted;
    }
}

-(float)playbackVolume
{
    return _playbackVolume;
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)aCurrentPlaybackTime
{
    if (!_player)
        return;

    _seekingTime = aCurrentPlaybackTime;
    _isSeeking = YES;
    _bufferingProgress = 0;
    [self didPlaybackStateChange];
    [self didLoadStateChange];
    if (_isPrerolling) {
        [_player pause];
    }
    __weak typeof(self) weakself =  self;
    [_player seekToTime:CMTimeMakeWithSeconds(aCurrentPlaybackTime, NSEC_PER_SEC) toleranceBefore:(CMTime)kCMTimeZero toleranceAfter:kCMTimeZero
      completionHandler:^(BOOL finished) {
          dispatch_async(dispatch_get_main_queue(), ^{
              weakself.isSeeking = NO;
              if (weakself.isPrerolling) {
                  [weakself.player play];
              }
              [weakself didPlaybackStateChange];
              [weakself didLoadStateChange];
          });
      }];
}

- (NSTimeInterval)currentPlaybackTime
{
    if (!_player)
        return 0.0f;

    if (_isSeeking)
        return _seekingTime;

    return CMTimeGetSeconds([_player currentTime]);
}

- (void)didPrepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    if (_isShutdown)
        return;
    
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys)
    {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed)
        {
            [self assetFailedToPrepareForPlayback:error];
            return;
        } else if (keyStatus == AVKeyValueStatusCancelled) {
            // TODO [AVAsset cancelLoading]
            NSError *error = [NSError errorWithDomain:@"music player"
                                                 code:0
                                             userInfo:@{@"NSLocalizedDescriptionKey":@"playitem cancelled"}];
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"AVMoviePlayer"
                                                                code:0
                                                            userInfo:nil];
        
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        return;
    }
    
    /* At this point we're ready to set up for playback of the asset. */
    
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.playerItem) {
        NSLog(@"旧有 playeritem is %@",self.playerItem);

        [self unregisterKVOForPlayerItem];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:nil
                                                      object:_playerItem];
        self.playerItem = nil;
    }
    
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    _playerItem = [AVPlayerItem playerItemWithAsset:asset];
    NSLog(@"新建 playeritem is %@", _playerItem);

    [self registerKVOForPlayerItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:_playerItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemFailedToPlayToEndTime:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:_playerItem];
    
    _isCompleted = NO;
    
    /* Create new player, if we don't already have one. */
    if (!_player)
    {
        _player = [AVPlayer playerWithPlayerItem:_playerItem];
        [self registerKVOForPlayer];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (_player.currentItem != _playerItem)
    {
        [_player replaceCurrentItemWithPlayerItem:_playerItem];
    }
}

- (void)fetchLoadStateFromItem:(AVPlayerItem*)playerItem
{
    if (playerItem == nil)
        return;

    _playbackLikelyToKeeyUp = playerItem.isPlaybackLikelyToKeepUp;
    _playbackBufferEmpty    = playerItem.isPlaybackBufferEmpty;
    _playbackBufferFull     = playerItem.isPlaybackBufferFull;
}

- (void)didLoadStateChange
{
    // NOTE: do not force play after stall,
    // which may cause AVPlayer get into wrong state
    //
    // Rely on AVPlayer's auto resume.
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(mediaPlayerLoadStateDidChange:)]) {
        [self.delegate mediaPlayerLoadStateDidChange:self.loadState];
    }
}

- (void)didPlaybackStateChange
{
//    if (_playbackState != self.playbackState) {
//        _playbackState = self.playbackState;
//    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(mediaPlayBackStateDidChange:)]) {
        [self.delegate mediaPlayBackStateDidChange:self.playbackState];
    }
}

- (void)didPlayableDurationUpdate
{
    NSTimeInterval currentPlaybackTime = self.currentPlaybackTime;
    int playableDurationMilli    = (int)(self.playableDuration * 1000);
    int currentPlaybackTimeMilli = (int)(currentPlaybackTime * 1000);
    
    int bufferedDurationMilli = playableDurationMilli - currentPlaybackTimeMilli;
    
    __weak typeof(self) weakself =  self;
    if (bufferedDurationMilli > 0) {
        self.bufferingProgress = bufferedDurationMilli * 100 / kMaxHighWaterMarkMilli;
        
        if (self.bufferingProgress > 100) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakself.bufferingProgress > 100) {
                    if ([weakself isPlaying]) {
                        weakself.player.rate = _playbackRate;
                    }
                }
            });
        }
    }
    
    NSLog(@"KVO_AVPlayerItem_loadedTimeRanges: %d / %d\n",
          bufferedDurationMilli,
          (int)kMaxHighWaterMarkMilli);
}

- (void)assetFailedToPrepareForPlayback:(NSError *)error
{
    if (_isShutdown)
        return;
    
    [self onError:error];
}

- (void)onError:(NSError *)error
{
    _isError = YES;
    __weak typeof(self) weakself =  self;
    NSLog(@"AVPlayer: onError:%@\n",error);
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself didPlaybackStateChange];
        [weakself didLoadStateChange];
//        [weakself setScreenOn:NO];
        
        if (weakself.delegate && [self.delegate respondsToSelector:@selector(mediaPlayBackDidFinish:)]) {
            [weakself.delegate mediaPlayBackDidFinish:MediaPlaybackStateEndedError];
        }
    });
}
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    if (_isShutdown)
        return;
    NSLog(@"playerItemDidReachEnd");
    _isCompleted = YES;
    [_player pause];
    __weak typeof(self) weakself =  self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself didPlaybackStateChange];
        [weakself didLoadStateChange];
//        [weakself setScreenOn:NO];
        
        if(weakself.delegate && [self.delegate respondsToSelector:@selector(mediaPlayBackDidFinish:)]) {
            [weakself.delegate mediaPlayBackDidFinish:MediaPlaybackStateEnded];
        }
    });
}

- (void)playerItemFailedToPlayToEndTime:(NSNotification *)notification
{
    if (_isShutdown)
        return;
    
    [self onError:[notification.userInfo objectForKey:@"error"]];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString*)path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    if (_isShutdown)
        return;
    
    if ([path isEqualToString:@"status"])
    {
        /* AVPlayerItem "status" property value observer. */
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
            case AVPlayerItemStatusUnknown:
            {
            }
                break;
                
            case AVPlayerItemStatusReadyToPlay:
            {
                NSLog(@"AVPlayerItemStatusReadyToPlay");
//                dispatch_once(&_readyToPlayToken, ^{
//                    [_avView setPlayer:_player];
                    self.isPreparedToPlay = YES;
                    AVPlayerItem *playerItem = (AVPlayerItem *)object;
                    NSLog(@"AVPlayerItemStatusReadyToPlay playeritem is %@", playerItem);
                    NSTimeInterval playduration = CMTimeGetSeconds(playerItem.duration);
                    if (playduration <= 0)
                        self.duration = 0.0f;
                    else
                        self.duration = playduration;
                    
                    if (self.delegate) {
                        [self.delegate mediaPlaybackIsPreparedToPlay];
                    }
                    
//                    if (_shouldAutoplay && (!_pauseInBackground || [UIApplication sharedApplication].applicationState == UIApplicationStateActive))
//                        [self.player play];
//                });
            }
                break;
                
            case AVPlayerItemStatusFailed:
            {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:playerItem.error];
            }
                break;
        }
        
//        [self didPlaybackStateChange];
//        [self didLoadStateChange];
    }
    else if ([path isEqualToString:@"loadedTimeRanges"])
    {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        if (_player != nil && playerItem.status == AVPlayerItemStatusReadyToPlay) {
            NSArray *timeRangeArray = playerItem.loadedTimeRanges;
            CMTime currentTime = [_player currentTime];
            
            BOOL foundRange = NO;
            CMTimeRange aTimeRange = {0};
            
            if (timeRangeArray.count) {
                aTimeRange = [[timeRangeArray objectAtIndex:0] CMTimeRangeValue];
                if(CMTimeRangeContainsTime(aTimeRange, currentTime)) {
                    foundRange = YES;
                }
            }
            
            if (foundRange) {
                CMTime maxTime = CMTimeRangeGetEnd(aTimeRange);
                NSTimeInterval playableDuration = CMTimeGetSeconds(maxTime);
                if (playableDuration > 0) {
                    self.playableDuration = playableDuration;
                    [self didPlayableDurationUpdate];
                }
            }
        }
        else
        {
            self.playableDuration = 0;
        }
    }
    else if ([path isEqualToString:@"playbackLikelyToKeepUp"]) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        NSLog(@"playbackLikelyToKeepUp: %@\n", playerItem.isPlaybackLikelyToKeepUp ? @"YES" : @"NO");
        [self fetchLoadStateFromItem:playerItem];
        [self didLoadStateChange];
    }
    else if ([path isEqualToString:@"playbackBufferEmpty"]) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        NSLog(@"playbackBufferEmpty playeritem is %@", playerItem);
        BOOL isPlaybackBufferEmpty = playerItem.isPlaybackBufferEmpty;
        NSLog(@"playbackBufferEmpty: %@\n", isPlaybackBufferEmpty ? @"YES" : @"NO");
        if (isPlaybackBufferEmpty)
            _isPrerolling = YES;
        [self fetchLoadStateFromItem:playerItem];
        [self didLoadStateChange];
    }
    else if ([path isEqualToString:@"playbackBufferFull"]) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        NSLog(@"playbackBufferFull playeritem is %@", playerItem);
        NSLog(@"playbackBufferFull: %@\n", playerItem.isPlaybackBufferFull ? @"YES" : @"NO");
        [self fetchLoadStateFromItem:playerItem];
        [self didLoadStateChange];
    }
    else if ([path isEqualToString:@"rate"])
    {
        if (_player != nil && !isFloatZero(_player.rate))
            _isPrerolling = NO;
        /* AVPlayer "rate" property value observer. */
        [self didPlaybackStateChange];
        [self didLoadStateChange];
    }
    else if ([path isEqualToString:@"currentItem"])
    {
        _isPrerolling = NO;
        /* AVPlayer "currentItem" property observer.
         Called when the AVPlayer replaceCurrentItemWithPlayerItem:
         replacement will/did occur. */
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* Is the new player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
            NSError *error = [NSError errorWithDomain:@"music player"
                                                 code:0
                                             userInfo:@{@"NSLocalizedDescriptionKey":@"urrent player item is nil"}];
            [self assetFailedToPrepareForPlayback:error];
        }
        else /* Replacement of player currentItem has occurred */
        {
//            [_avView setPlayer:_player];
            [self didPlaybackStateChange];
            [self didLoadStateChange];
        }
    }
    else if ([path isEqualToString:@"airPlayVideoActive"])
    {
    }
    else
    {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}

#pragma mark ---kvo and notification

- (void)registerKVOForPlayer {
    [_player addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    [_player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
//        [_player addObserver:self forKeyPath:@"airPlayVideoActive" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
}

- (void)unregisterKVOForPlayer {
    [_player removeObserver:self forKeyPath:@"currentItem"];
    [_player removeObserver:self forKeyPath:@"rate"];
}

- (void)registerKVOForPlayerItem {
    NSLog(@"registerKVOForPlayerItem");
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackBufferFull" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
}

- (void)unregisterKVOForPlayerItem {
    NSLog(@"unregisterKVOForPlayerItem");
    [_playerItem removeObserver:self forKeyPath:@"status"];
    [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_playerItem removeObserver:self forKeyPath:@"playbackBufferFull"];
}

- (void)registerApplicationObservers
{
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                             selector:@selector(audioSessionInterrupt:)
//                                 name:AVAudioSessionInterruptionNotification
//                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                             selector:@selector(applicationWillEnterForeground)
                                 name:UIApplicationWillEnterForegroundNotification
                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                             selector:@selector(applicationDidBecomeActive)
                                 name:UIApplicationDidBecomeActiveNotification
                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                             selector:@selector(applicationWillResignActive)
                                 name:UIApplicationWillResignActiveNotification
                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                             selector:@selector(applicationDidEnterBackground)
                                 name:UIApplicationDidEnterBackgroundNotification
                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                             selector:@selector(applicationWillTerminate)
                                 name:UIApplicationWillTerminateNotification
                               object:nil];
}

- (void)unregisterObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)audioSessionInterrupt:(NSNotification *)notification
{
    int reason = [[[notification userInfo] valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    switch (reason) {
        case AVAudioSessionInterruptionTypeBegan: {
            NSLog(@"IJKAVMoviePlayerController:audioSessionInterrupt: begin\n");
            switch (self.playbackState) {
                case MediaPlaybackStatePaused:
                case MediaPlaybackStateStopped:
//                    _playingBeforeInterruption = NO;
                    break;
                default:
//                    _playingBeforeInterruption = YES;
                    break;
            }
            [self pause];
            [self setActive:NO];
            break;
        }
        case AVAudioSessionInterruptionTypeEnded: {
            NSLog(@"IJKAVMoviePlayerController:audioSessionInterrupt: end\n");
            [self setActive:YES];
//            if (_playingBeforeInterruption) {
                [self play];
//            }
            break;
        }
    }
}

- (MediaPlaybackState)playbackState
{
    if (!_player)
        return MediaPlaybackStateStopped;
    
    MediaPlaybackState mpState = MediaPlaybackStateStopped;
    if (_isCompleted) {
        mpState = MediaPlaybackStateStopped;
    } else if (_isSeeking) {
        mpState = MediaPlaybackStateSeekingForward;
    } else if ([self isPlaying]) {
        mpState = MediaPlaybackStatePlaying;
    } else {
        mpState = MediaPlaybackStatePaused;
    }
    return mpState;
}

- (MediaLoadState)loadState
{
    if (_player == nil)
        return MediaLoadStateUnknown;
    
    if (_isSeeking)
        return MediaLoadStateStalled;
    
    AVPlayerItem *playerItem = [_player currentItem];
    if (playerItem == nil)
        return MediaLoadStateUnknown;
    
    if (_player != nil && !isFloatZero(_player.rate)) {
        // NSLog(@"loadState: playing");
        return MediaLoadStatePlayable | MediaLoadStatePlaythroughOK;
    } else if ([playerItem isPlaybackBufferFull]) {
        // NSLog(@"loadState: isPlaybackBufferFull");
        return MediaLoadStatePlayable | MediaLoadStatePlaythroughOK;
    } else if ([playerItem isPlaybackLikelyToKeepUp]) {
        // NSLog(@"loadState: isPlaybackLikelyToKeepUp");
        return MediaLoadStatePlayable | MediaLoadStatePlaythroughOK;
    } else if ([playerItem isPlaybackBufferEmpty]) {
        // NSLog(@"loadState: isPlaybackBufferEmpty");
        return MediaLoadStateStalled;
    } else {
        NSLog(@"loadState: unknown");
        return MediaLoadStateUnknown;
    }
}

-(void)applicationWillEnterForeground {

}

-(void)applicationDidBecomeActive {

}

-(void)applicationWillResignActive {

}

-(void)applicationDidEnterBackground {

}

-(void)applicationWillTerminate {

}

- (void)dealloc {
    NSLog(@"%s",__func__);
}

@end
