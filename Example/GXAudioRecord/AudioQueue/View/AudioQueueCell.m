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

#import "GGXAudioConvertor.h"
@interface AudioQueueCell ()
@property (weak, nonatomic) IBOutlet UILabel *m4aPath;
@property (weak, nonatomic) IBOutlet UILabel *wavPath;

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
    
    NSString *filePath = [GGXFileManeger.shared getFilePath:self.audioName.text];
    NSURL *uuInputPath = [NSURL fileURLWithPath:filePath];
    NSLog(@"filePath:%@",filePath);
    
    NSString *outPath = [GGXFileManeger.shared createFilePathWithFormat:@"m4a"];
    NSURL *uuPath =  [NSURL fileURLWithPath:outPath];
    
    [GGXAudioConvertor convertCAFToM4A:uuInputPath outPath:uuPath andComplete:^(id _Nonnull obj) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"输出路径：%@",outPath);
            self.m4aPath.text = [NSString stringWithFormat:@"%@",uuPath.lastPathComponent];
        });
    }];
}
- (IBAction)m4aTowavHnader:(id)sender {
    //获取
    NSString *filePath = [GGXFileManeger.shared getFilePath:self.audioName.text];
    NSURL *uuInputPath = [NSURL fileURLWithPath:filePath];
    if (![uuInputPath.pathExtension isEqualToString:@"m4a"]) {
        filePath = [GGXFileManeger.shared getFilePath:self.m4aPath.text];
    }
    
    NSLog(@"原始路径：%@",filePath);
    NSString *outPath = [GGXFileManeger.shared createFilePathWithFormat:@"wav"];
    
    [GGXAudioConvertor convertM4AToWAV:filePath outPath:outPath success:^(NSString * _Nonnull outputPath) {
        NSURL *uOutPath = [NSURL fileURLWithPath:outputPath];
        //当前文件中 增加wav路径 wavName
        dispatch_async(dispatch_get_main_queue(), ^{
            self.wavPath.text = [NSString stringWithFormat:@"%@",uOutPath.lastPathComponent];
        });
    } failure:^(NSError * _Nonnull error) {
        
    }];
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
