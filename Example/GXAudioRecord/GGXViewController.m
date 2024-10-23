//
//  GGXViewController.m
//  GXAudioRecord
//
//  Created by gaoguangxiao on 08/25/2023.
//  Copyright (c) 2023 gaoguangxiao. All rights reserved.
//

#import "GGXViewController.h"
#import "AQRecordController.h"
#import <AQPlayerManager.h>
#import "GGXFileManeger.h"
#import "JHAudioRecorder.h"
@interface GGXViewController ()

@property (nonatomic, strong) AQPlayerManager *playerManager;

@end

@implementation GGXViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //    [self pushVc:nil];
    //    [CustomUtil saveAcessToken:@"Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJCYXpoZkIxMCIsInV1aWQiOiI1ZDg2YThmYjhlNzU0YjVjOTlmZTQxOGViZjc3M2U0MCIsInRpbWVzdGFtcCI6MTcyODU0NjA1Njc5N30.IBJsvTBN7XyOMEHZEGkbQj_YH5kuHDpBpKYNCWI0xPR_-HrnuC0YdFLzP98tvvqS6MH6u3FlTsUSdxr8LdtTrg"];
    //    https://gateway-test.risekid.cn/wap/api/certificate/tencent
}

- (IBAction)pushVc:(id)sender {
    AQRecordController *Vc = [AQRecordController new];
    [self.navigationController pushViewController:Vc animated:YES];
    
    //    [self loadCerData];
}

//播放本地PCM数据
- (IBAction)didPlayPCM:(id)sender {
    NSString *pcmPath = [[NSBundle mainBundle]pathForResource:@"2024-10-21_16-53-32" ofType:@"pcm"];
    
    [JHAudioRecorder.shareAudioRecorder playRecordingWith:pcmPath];
//    [self.playerManager startPlay:pcmPath];
    
    //获取
//    NSString *filePath = [GGXFileManeger.shared getFilePath:pcmPath];
//    NSURL *uuInputPath = [NSURL fileURLWithPath:filePath];
//    if (![uuInputPath.pathExtension isEqualToString:@"m4a"]) {
//        filePath = [GGXFileManeger.shared getFilePath:self.m4aPath.text];
//    }
    
//    NSLog(@"原始路径：%@",pcmPath);
//    NSString *outPath = [GGXFileManeger.shared createFilePathWithFormat:@"wav"];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (AQPlayerManager *)playerManager {
    if (!_playerManager) {
        _playerManager = [[AQPlayerManager alloc] init];
        _playerManager.aqDelegate = self;
    }
    return _playerManager;
}
@end
