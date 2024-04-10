//
//  JHAudioRecorder.m
//  AudioRecorder
//
//  Created by gaoguangxiao on 2018/7/29.
//  Copyright © 2018年 gaoguangxiao. All rights reserved.
//

#import "JHAudioRecorder.h"

#import "MusicModel.h"
@interface JHAudioRecorder ()<AVCaptureAudioDataOutputSampleBufferDelegate,AVAudioPlayerDelegate,AVAudioRecorderDelegate>{
    
    NSString*  nowTempPath;
    
    NSTimer *checkTime;//获取音乐声道的定时器
    
    NSMutableArray *pointArr;
    float viewWidth;
    float viewHeight;
}

@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@end


@implementation JHAudioRecorder
//static JHAudioRecorder *shareAudioRecorder = nil;
static JHAudioRecorder *_instance;
//+ (JHAudioRecorder *)shareAudioRecorder{
//
//    @synchronized(self)
//    {
//        if (shareAudioRecorder == nil)
//        {
//            shareAudioRecorder = [[self alloc] init];
//        }
//    }
//
//    return shareAudioRecorder;
//}
+(instancetype)shareAudioRecorder{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc]init];
    });
    return _instance;
}
+(instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
-(id)copyWithZone:(NSZone *)zone{
    return _instance;
}

- (BOOL)startRecording{
    
    NSLog(@"startRecording");
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];//设置可录制 和播放
    [audioSession setActive:YES error:nil];
    
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] initWithCapacity:10];
    [recordSettings setObject:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey: AVFormatIDKey];//ID
    [recordSettings setObject:[NSNumber numberWithFloat:44100] forKey: AVSampleRateKey];//采样率
    [recordSettings setObject:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];//通道的数目,1单声道,2立体声
    [recordSettings setObject:[NSNumber numberWithInt: AVAudioQualityMedium] forKey: AVEncoderAudioQualityKey];
    
    nowTempPath = [self filePathWithName:@"recordTemp" andType:[NSString stringWithFormat:@"%d",(int )[[NSDate date] timeIntervalSince1970]]];
    NSLog(@"nowTempPath:%@",nowTempPath);
    NSURL *url = [NSURL fileURLWithPath:nowTempPath];
    NSError *error = nil;
    
    if (self.audioRecorder) {
        if ([self.audioRecorder isRecording]) {
            [self.audioRecorder stop];
        }
        self.audioRecorder = nil;
    }
    if (self.audioPlayer) {
        if ([self.audioPlayer isPlaying]) {
            [self stopPlaying];
        }
    }
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:recordSettings error:&error];
    
    if ([self .audioRecorder prepareToRecord]){
        
        self.audioRecorder.meteringEnabled = YES;
        
        self.audioRecorder.delegate = self;
        
        [self startCheck];
        
        return [self.audioRecorder record];
    }else{
        
        int errorCode = CFSwapInt32HostToBig ([error code]);
        NSLog( @"Error: %@ [%4.4s])" , [error localizedDescription], (char*)&errorCode);
        
        return NO;
    }
}
- (void)stopRecording{
    [self.audioRecorder stop];
    [self stopCheck];
}

- (void)playRecordingWith:(NSString *)filePath{
    
    NSLog(@"playRecording");
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    
    NSURL *url = [NSURL fileURLWithPath:filePath];;
    if (filePath.length > 0) {
       url = [NSURL fileURLWithPath:filePath];
    }
    
    NSError *error;
    

    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    self.audioPlayer.numberOfLoops = -1;
    if (!error&&self.audioPlayer) {
        self.audioPlayer.numberOfLoops = 0;
        self.audioPlayer.meteringEnabled = YES;
        self.audioPlayer.delegate = self;
        //设置播放速率， 前提设置为YES
        //    self.audioPlayer.enableRate = YES;
        //    self.audioPlayer.rate = ;
        
        [self.audioPlayer play];
    }

    
    
    [self startCheck];
}
- (void)stopPlaying{
    NSLog(@"stopPlaying");
    if (self.audioPlayer) {
        [self.audioPlayer stop];
//        [self.audioPlayer pause];
//        [self.audioPlayer play];
    }
    [self stopCheck];
}
- (void)stopCheck{
    if (checkTime) {
        [checkTime invalidate];
        checkTime = nil;
    }
    
    [pointArr removeAllObjects];
}
- (void)startCheck{
    if (!checkTime) {
        checkTime = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkRecordValueWithTime:) userInfo:nil repeats:YES];
    }
    pointArr = [[NSMutableArray alloc]init];
}

- (void)checkRecordValueWithTime:(NSTimer *)time{
    
    float peakPower = 1;
    float timeValue = 0.01;
//    double peakPowerForChannel =
    if (self.audioRecorder.isRecording) {
        [self.audioRecorder updateMeters];
        peakPower = [self.audioRecorder peakPowerForChannel:0];
        timeValue = self.audioRecorder.currentTime;
    } else if (self.audioPlayer.isPlaying){
        [self.audioPlayer updateMeters];
        peakPower = [self.audioPlayer peakPowerForChannel:0];
        timeValue = self.audioPlayer.currentTime;
    }
    
    NSLog(@"分贝 : %f",peakPower);
//    NSLog(@"timeValue:%f",timeValue);

    MusicModel *m = [[MusicModel alloc]init];
    m.value = peakPower;
    m.time  = timeValue;
    
    [pointArr addObject:m];
    
    
    //获取一段声音中第几拍
//    if (self.delegate&&[self.delegate respondsToSelector:@selector(reloadPatCount:)]&&newPat) {
//        [self.delegate reloadPatCount:m.patCount];
//    }
    
    //将suoy
//    if ([pointArr count] >= 10) {
//        [pointArr removeObjectAtIndex:0];
//    }
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(reloadPlayTime:)]) {
        [self.delegate reloadPlayTime:self.audioPlayer];
    }
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(reloadValueWithArr:)]) {
        [self.delegate reloadValueWithArr:[pointArr copy]];
    }
    
    if ([self.delegate respondsToSelector:@selector(reloadMeterValue:)]) {
        [self.delegate reloadMeterValue:peakPower];
    }
//    }
    
    
}
- (NSString *)filePathWithName:(NSString *)recorderName andType:(NSString *)type{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path = [paths  objectAtIndex:0];
    NSString *account = @"yinyue";
    NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat: @"/sens/%@/recorder/",account]];
    NSFileManager* fm = [NSFileManager defaultManager];
    
    if(![fm fileExistsAtPath:filePath]) {
            [fm createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filename = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@",recorderName,type]];
    return filename;
}

#pragma mark - AVAudioPlayer Delegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [self stopPlaying];
}

-(void)dealloc{
//    [audioPlayer.url release];
    if (self.audioPlayer && [self.audioPlayer isPlaying]) {
        [self.audioPlayer stop];
    }
    self.audioPlayer = nil;
//    [audioPlayer release];
//    audioPlayer = nil;/
//    [super dealloc];
}
@end
