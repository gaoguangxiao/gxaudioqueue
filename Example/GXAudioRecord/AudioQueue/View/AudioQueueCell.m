//
//  AudioQueueCell.m
//  recordAudip
//
//  Created by 高广校 on 2023/8/24.
//

#import "AudioQueueCell.h"
#import "GGXFileManeger.h"
#import "AQPlayerManager.h"
#import "ParsingAudioHander.h"
#import "JHAudioRecorder.h"
@interface AudioQueueCell ()

@property (weak, nonatomic) IBOutlet UILabel *audioName;

@property (nonatomic, strong) AQPlayerManager *playerManager;
@end

@implementation AudioQueueCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)fillData:(NSString *)txt {
    self.audioName.text = txt;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)playAction:(id)sender {
    NSString *filePath = [GGXFileManeger.shared getFilePath:self.audioName.text];
//    [self.playerManager startPlay:filePath];
    NSLog(@"%@",filePath);
    JHAudioRecorder *audio = [JHAudioRecorder shareAudioRecorder];
    audio.delegate = self;
    [audio playRecordingWith:filePath];
}

-(void)reloadValueWithArr:(NSArray *)valueArr{
    
//    NSLog(@"%@",valueArr);
//    self.waveView
}

- (IBAction)handleSE:(id)sender {
    NSLog(@"处理音频前后");
    
    NSString *filePath = [GGXFileManeger.shared getFilePath:self.audioName.text];
    NSLog(@"filePath:%@",filePath);
    
//    [ParsingAudioHander cutAudioStartTime:1.0 endTime:1.5 withPath:filePath andComplete:^(id  _Nonnull selfPtr) {
//        
//    }];
//    +(void)cutAudioStartTime:(CGFloat)source endTime:(CGFloat)end withPath:(NSString *)path
}
- (IBAction)GainDBPcm:(id)sender {
    //获取PCM的分贝
    NSLog(@"获取PCM分贝");
    ParsingAudioHander *ap = [ParsingAudioHander new];
    NSString *filePath = [GGXFileManeger.shared getFilePath:self.audioName.text];
    NSArray *datas = [ap getRecorderDataFromURL:[NSURL fileURLWithPath:filePath]];
    
//    [ap pcmDB:[NSURL fileURLWithPath:filePath]];
    
//    NSLog(@"PCM分贝：%@",datas);
}

- (AQPlayerManager *)playerManager {
    if (!_playerManager) {
        _playerManager = [[AQPlayerManager alloc] initAudioFormatType:AudioFormatLinearPCM sampleRate:8000.0 channels:1 bitsPerChannel:16];
    }
    return _playerManager;
}

@end
