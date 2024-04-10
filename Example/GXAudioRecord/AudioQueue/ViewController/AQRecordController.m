//
//  AQRecordController.m
//  recordAudip
//
//  Created by gaoyu on 2021/6/7.
//

#import "AQRecordController.h"
#import "GGXFileManeger.h"
#import "AQRecorderManager.h"
#import "AQPlayerManager.h"
#import "ParsingAudioHander.h"
#import <Masonry/Masonry.h>
#import "AQRecordListViewController.h"
#import "JHAudioRecorder.h"
#import "GGXAudioConvertor.h"
@interface AQRecordController ()<UITableViewDataSource,UITableViewDelegate,GGXAudioQueueDataSource>

@property (nonatomic, strong) UILabel *levekDBTxt;

@property (nonatomic, strong) UIButton *btnRecord; //录制按钮

//调整录制音量大小
@property(retain, nonatomic) UISlider* slider;

@property (nonatomic, copy)   NSString *recordFilePath;

@property (nonatomic, strong) UIButton *playRecord;

@property (nonatomic, strong) UIButton *recordFileBtn;
//裁剪音频
@property (nonatomic, strong) UIButton *cutRecordFile;

//播放音频
//@property (nonatomic, strong) UIButton *cutRecordFile;

//获取一段音频信息
@property (nonatomic, strong) UIButton *audioFileInfo;

@property (nonatomic, strong) AQRecorderManager *recorderMgr;

@property (nonatomic, strong) AQPlayerManager *playerManager;

@end

@implementation AQRecordController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.slider];
    [self.view addSubview:self.levekDBTxt];
    [self.view addSubview:self.btnRecord];
    
    //缓冲条
    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(5);
        make.bottom.mas_equalTo(self.levekDBTxt.mas_top).offset(-30);
    }];
    
    [self.levekDBTxt mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.btnRecord.mas_centerY);
        make.left.mas_equalTo(self.btnRecord.mas_right).offset(10);
    }];
    
    [self.btnRecord mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.size.mas_equalTo(CGSizeMake(100, 40));
        make.centerY.mas_equalTo(0);
    }];
    
    [self.view addSubview:self.cutRecordFile];
    [self.cutRecordFile mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.btnRecord.mas_left).offset(10);
        make.size.mas_equalTo(CGSizeMake(100, 40));
        make.top.mas_equalTo(self.btnRecord.mas_top).offset(10);
    }];
    
    [self.view addSubview:self.audioFileInfo];
    [self.audioFileInfo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.cutRecordFile.mas_right);
        make.size.mas_equalTo(CGSizeMake(100, 40));
        make.top.mas_equalTo(self.cutRecordFile.mas_bottom).offset(10);
    }];
    
    [self.view addSubview:self.playRecord];
    [self.playRecord mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.size.mas_equalTo(CGSizeMake(100, 40));
        make.top.mas_equalTo(self.btnRecord.mas_bottom).offset(10);
    }];
    
    [self.view addSubview:self.recordFileBtn];
    [self.recordFileBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.size.mas_equalTo(CGSizeMake(100, 40));
        make.top.mas_equalTo(self.playRecord.mas_bottom).offset(10);
    }];
}

- (void)recordAction:(UIButton *)btn {
    btn.selected = !btn.selected;
    if (self.recorderMgr.isRecording) {
        [self.btnRecord setTitle:@"开始录制" forState:UIControlStateNormal];
        
        [self.recorderMgr stopRecord];
        
    } else {
        
        if (@available(iOS 17.0, *)) {
            [AVAudioApplication requestRecordPermissionWithCompletionHandler:^(BOOL granted) {
                NSLog(@"录制权限:%d",granted);
            }];
        } else {
            // Fallback on earlier versions
        }
        
        //生成录制路径
        NSString *audioFormat = @"caf";
        audioFormat = @"wav";
        self.recordFilePath = [GGXFileManeger.shared createFilePathWithFormat:audioFormat];
        [self.btnRecord setTitle:@"结束录制" forState:UIControlStateNormal];
        //
        [self.recorderMgr startRecordWithFilePath:self.recordFilePath];
    }
}

- (void)playRecordFileAction {
    //获取当前录制文件
//    [self.playerManager startPlay:self.recordFilePath];
    [JHAudioRecorder.shareAudioRecorder playRecordingWith:self.recordFilePath];
//    NSLog(@"%@",self.recordFilePath);
    
//    NSString *inputPath = [[NSBundle mainBundle]pathForResource:@"music-Loop" ofType:@"mp3"];
//    [JHAudioRecorder.shareAudioRecorder playRecordingWith:inputPath];
    
//    [self.playerManager startPlay:@"http://192.168.50.165:8081/static/music-Loop.mp3"];
}

//裁剪音频
- (void)tailorAudioFile {
   
    NSString *inputPath = [[NSBundle mainBundle]pathForResource:@"tailorAudio" ofType:@"wav"];
    
    NSString *outwavPath = [GGXFileManeger.shared createFilePathWithFormat:@"wav"];
    
//    AudioChannelLayout channelLayout;
//    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
//    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
//    
//    NSData *channelLayoutAsData = [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)];
    /** 配置音频参数 */
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                    [NSNumber numberWithFloat:kDefaultSampleRate], AVSampleRateKey,
                                    [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
//                                    channelLayoutAsData, AVChannelLayoutKey,
                                    [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                    [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                    nil];
//    AVLinearPCMIsNonInterleaved
//    AVLinearPCMIsFloatKey 是否支持浮点处理
//    AVLinearPCMIsBigEndianKey 大端模式 小端模式
    
    [GGXAudioConvertor tailorAudioTimeRange:CMTimeRangeMake(CMTimeMake(3, 1), CMTimeMakeWithSeconds(6.0, 600)) outSettings:outputSettings inputPath:inputPath outPath:outwavPath andComplete:^(NSString * _Nonnull outputPath) {
        NSLog(@"outputPath:%@",outputPath);
    }];
}
    
- (void)getAudioFileInfo {
    NSLog(@"获取音频文件信息");
    
    NSString *inputPath = [[NSBundle mainBundle]pathForResource:@"tailorAudio" ofType:@"wav"];
    NSURL *url = [NSURL fileURLWithPath:inputPath];
     
    url = [NSURL URLWithString:@"http://192.168.50.165:8081/static/question.fccbbee5.mp3"];
    ParsingAudioHander *audioHander =  [ParsingAudioHander new];
    NSArray *datas = [audioHander getRecorderDataFromURL:url];
    
//    NSLog(@"%@",datas);
    datas = [audioHander pcmDB:url];
//    NSLog(@"%@",datas);
}

- (void)recordFileAction:(UIButton *)sender {
    AQRecordListViewController *Vc = [AQRecordListViewController new];
    [self.navigationController pushViewController:Vc animated:YES];
}

- (void)pressSlider:(UISlider *)slider {

    NSLog(@"滑块的值：%f",slider.value);
    //
    //-20 -10 0 20 30 40
//    slider.value;
    self.recorderMgr.loudnessValue = slider.value;
}

#pragma mark - GGXAudioQueueDataSource
- (void)didOutputAudioPeakPower:(float)audioPeak {
    
//    NSLog(@"音量变化：%.2f",audioPeak);
    
    self.levekDBTxt.text = [NSString stringWithFormat:@"音量：%.2f",audioPeak];
}

- (void)recorderManager:(AQRecorderManager *)recorderManager andFilePath:(NSString *)filePath {
    
    NSLog(@"录制完毕的路径:%@",filePath);
}

//-recordma
#pragma mark - getter
- (UILabel *)levekDBTxt {
    if (!_levekDBTxt) {
        _levekDBTxt = [UILabel new];
        _levekDBTxt.text = @"音量：db";
    }
    return _levekDBTxt;
}

- (UISlider *)slider {
    if (_slider == nil) {
        //滑动条
        _slider = [[UISlider alloc] init];
        //高度不可设置
        _slider.frame = CGRectMake(10, 200, 300, 40);
        //设置最大值
        _slider.maximumValue = 1;
        //设置最小值，可以为负值
        _slider.minimumValue = 0;
        //设置滑块左侧背景颜色
        _slider.minimumTrackTintColor = [UIColor blueColor];
        //设置滑块右侧背景颜色
        _slider.maximumTrackTintColor = [UIColor greenColor];
        //设置滑块颜色
        _slider.thumbTintColor = [UIColor orangeColor];
        //设置滑动条滑动事件回调
        [_slider addTarget:self action:@selector(pressSlider:) forControlEvents:UIControlEventValueChanged];
    }
    return _slider;
}

- (UIButton *)btnRecord {
    if (!_btnRecord) {
        _btnRecord = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnRecord setTitle:@"开始录制" forState:UIControlStateNormal];
        [_btnRecord setTitleColor:UIColor.redColor forState:UIControlStateNormal];
        [_btnRecord addTarget:self action:@selector(recordAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnRecord;
}

- (UIButton *)playRecord {
    if (!_playRecord) {
        _playRecord = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playRecord setTitle:@"播放录制" forState:UIControlStateNormal];
        [_playRecord setTitleColor:UIColor.redColor forState:UIControlStateNormal];
        [_playRecord addTarget:self action:@selector(playRecordFileAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playRecord;
}

- (UIButton *)recordFileBtn {
    if (!_recordFileBtn) {
        _recordFileBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_recordFileBtn setTitle:@"录制文件" forState:UIControlStateNormal];
        [_recordFileBtn setTitleColor:UIColor.redColor forState:UIControlStateNormal];
        [_recordFileBtn addTarget:self action:@selector(recordFileAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _recordFileBtn;
}

- (UIButton *)cutRecordFile {
    if (!_cutRecordFile) {
        _cutRecordFile = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cutRecordFile setTitle:@"裁剪音频文件" forState:UIControlStateNormal];
        [_cutRecordFile setTitleColor:UIColor.redColor forState:UIControlStateNormal];
        [_cutRecordFile addTarget:self action:@selector(tailorAudioFile) forControlEvents:UIControlEventTouchUpInside];
        _cutRecordFile.titleLabel.font = [UIFont systemFontOfSize:15];
    }
    return _cutRecordFile;
}

- (UIButton *)audioFileInfo {
    if (!_audioFileInfo) {
        _audioFileInfo = [UIButton buttonWithType:UIButtonTypeCustom];
        [_audioFileInfo setTitle:@"获取音频信息" forState:UIControlStateNormal];
        [_audioFileInfo setTitleColor:UIColor.redColor forState:UIControlStateNormal];
        [_audioFileInfo addTarget:self action:@selector(getAudioFileInfo) forControlEvents:UIControlEventTouchUpInside];
        _audioFileInfo.titleLabel.font = [UIFont systemFontOfSize:15];
    }
    return _audioFileInfo;
}


- (AQRecorderManager *)recorderMgr {
    if (!_recorderMgr) {
        _recorderMgr = [[AQRecorderManager alloc] initAudioFormatType:AudioFormatLinearPCM sampleRate:8000.0 channels:1 bitsPerChannel:16];
        _recorderMgr.isEnableMeter = YES;
        _recorderMgr.isCutsilentHeadTail = YES;
        _recorderMgr.aqDataSource = self;
        _recorderMgr.stopRecordDBLevel = -15;
    }
    return _recorderMgr;
}

- (AQPlayerManager *)playerManager {
    if (!_playerManager) {
        _playerManager = [[AQPlayerManager alloc] init];
    }
    return _playerManager;
}

@end
