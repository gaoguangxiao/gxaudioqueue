//
//  ParsingAudioHander.m
//  EditAudio
//
//  Created by yoyochecknow on 2021/5/27.
//

#import "ParsingAudioHander.h"
#import <AVFoundation/AVFoundation.h>
#import "MusicModel.h"
#import "GGXFileManeger.h"
#import "GGXAudioQueueHeader.h"
@interface ParsingAudioHander()

@property (nonatomic,copy) NSURL *url;
@property (nonatomic,strong) NSMutableData *audioData;
@property (nonatomic,assign) CMTime assetTime;

@property (nonatomic, assign) BOOL isEndHandleStart;
@property (nonatomic, assign) CMTime startTime;

@property (nonatomic,assign) CMTime endTime;
@end



@implementation ParsingAudioHander
- (NSArray *)getRecorderDataFromURL:(NSURL *)url {
    self.url = url;
    NSMutableData *data = [[NSMutableData alloc]init];     //用于保存音频数据
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];           //获取文件
    NSError *error;
    AVAssetReader *reader = [[AVAssetReader alloc]initWithAsset:asset error:&error]; //创建读取
    if (!reader) {
        NSLog(@"%@",[error localizedDescription]);
    }
//    reader.timeRange 设置读取范围
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];//从媒体中得到声音轨道
    
    //读取配置 资源应该来自URL磁盘本身
//    NSDictionary *dic   = @{AVFormatIDKey            :@(kAudioFormatLinearPCM),
//                            AVLinearPCMIsBigEndianKey:@NO,
//                            AVLinearPCMIsFloatKey    :@NO,
//                            AVLinearPCMBitDepthKey   :@(16)
//                            };
    
    //在创建asset reader之后，至少设置一个output来接受读取的媒体数据
    AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc]initWithTrack:track outputSettings:nil];
    //赋给读取并开启读取，
    [reader addOutput:output];
    [reader startReading];
    //读取是一个持续的过程，每次只读取后面对应的大小的数据。当读取的状态发生改变时，其status属性会发生对应的改变，我们可以凭此判断是否完成文件读取
//    AVAudioPlayer(
    while (reader.status == AVAssetReaderStatusReading) {
//      每个出口分别获取媒体数据,
        CMSampleBufferRef  sampleBuffer = [output copyNextSampleBuffer]; //读取到数据,这个结构在iOS表示一帧音频/视频数据
//        recorder?.averagePower(forChannel: 0) ?? 0
        
        if (sampleBuffer) {
            
            CMBlockBufferRef blockBUfferRef = CMSampleBufferGetDataBuffer(sampleBuffer);//取出数据
            size_t length = CMBlockBufferGetDataLength(blockBUfferRef);
            //和上面方法获取数值一样，只是不同类的方法
//            NSInteger audioDataSize = CMSampleBufferGetTotalSampleSize(sampleBuffer);
            //返回一个大小，size_t针对不同的品台有不同的实现，扩展性更好
            SInt16 sampleBytes[length];
            CMBlockBufferCopyDataBytes(blockBUfferRef, 0, length, sampleBytes); //将数据放入数组
            [data appendBytes:sampleBytes length:length];                 //将数据附加到data中
            CMSampleBufferInvalidate(sampleBuffer);  //销毁
            CFRelease(sampleBuffer);                 //释放
        }
    }
    
    if (reader.status == AVAssetReaderStatusCompleted) {
        self.audioData = data;
        self.assetTime = asset.duration;
        
//        NSData *zdata = [NSData dataWithContentsOfURL:url];//845,678
        float duration = CMTimeGetSeconds(self.assetTime);//获取音频时长 转换为秒
        NSLog(@"使用AssetTrack的duration：%f",duration);
        return [self cutAudioData:CGSizeMake(60, 60)];
    }else{
        
        NSLog(@"获取音频数据失败");
        return nil;
    }
    
    /**
     
     NSData *zdata = [NSData dataWithContentsOfURL:url];
     
     使用`NSData`实例方法`dataWithContentsOfURL`读取文件的data，是文件二进制数据，而使用`AVAssetReaderTrackOutput`的实例方法copyNextSampleBuffer`获取的`CMSampleBufferRef`是采样PCM数据，通过`CMBlockBufferCopyDataBytes`方法将采样数据可追加到字节数组中，通过`appendBytes`将字节数据追加到NSMutableData中
     */
    
}

- (NSArray *)pcmDB:(NSURL *)aUrl {
    
    //一段音频文件有几帧构成
//    可以通过`AVAudioFile`的`length`获取，该音频文件的帧数，422817
    
    //读取文件
    NSError *errorone;
    AVAudioFile *drumLoopFile = [[AVAudioFile alloc] initForReading:aUrl error:&errorone];
    if (errorone) {
        NSLog(@"%@", [errorone localizedDescription]);
        return nil;
    }
    /*
     drumLoopFile.processingFormat
     streamDescription->mBytesPerFrame：4//每帧4个字节，
     streamDescription->mBitsPerChannel：32 对应的是采样位深
     */
    AVAudioFormat *processingFormt = drumLoopFile.processingFormat;
    /*
     * drumLoopFile.fileFormat
     streamDescription->mBytesPerFrame：2 //每帧2个字节
     streamDescription->mBitsPerChannel：16
     得到的 2 * 
     
     根据帧数，声道数 * 采样率 * (每帧多少字节)  每声道的位数 计算音频
     其中每帧多少字节，可以为 mBitsPerChannel/8 字节
     */
    AVAudioFormat *fileFormat = drumLoopFile.fileFormat;
    
    AVAudioFramePosition aFramePosition = drumLoopFile.length;//422817
    NSLog(@"该%@由%lld帧构成",aUrl,aFramePosition);
    
    AVAudioFormat *pcmFormat = fileFormat;
    //    file.
    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:pcmFormat frameCapacity:(AVAudioFrameCount)aFramePosition];
    //将音频读入`AVAudioPCMBuffer`中
    [drumLoopFile readIntoBuffer:pcmBuffer error:nil];
    const AudioBufferList *audioBufferList = pcmBuffer.audioBufferList;
//    计算一帧多少字节，声道数 * 每声道的位数/8 可得出 mBytesPreFrame
//    float formatValue = pcmFormat.streamDescription->mBitsPerChannel;//kb
    float aformatValue = pcmFormat.streamDescription->mBytesPerFrame * aFramePosition;
    NSLog(@"该音频由%f字节构成",aformatValue);
//    float bytes = aformatValue/1000;//计算多少兆
//    buffer->mBuffers
//    AudioBufferList audioBufferList = *(pcmBuffer.mutableAudioBufferList);
    AudioBuffer audiobuffer = audioBufferList->mBuffers[0];//单声道
    UInt32 mDataByteSize = audiobuffer.mDataByteSize;//音频大小//1691268
    
    void* __nullable mData = audiobuffer.mData;
    NSMutableData *mtData = [NSMutableData new];
//    NSData *mtData = [NSData dataWithBytes:mData length:mDataByteSize];
    [mtData appendBytes:mData length:mDataByteSize];
    
    self.audioData = mtData;
    
    NSLog(@"使用：AVAudioPCMBuffer读取data：%@",mtData);
    return [self cutAudioData:CGSizeMake(60, 60)];
//    playerLoopBuffer.is
}

- (int)hal_get_ai_frame_db:(const unsigned char *)pcmdata and:(size_t)size{
    short tmp = 0;
    int i = 0;
    int sum = 0;
    short* addr = (short*)pcmdata;
    for (i = 0 ; i < size; i += 1) {
        memcpy(&tmp, addr +  i, sizeof(short)); //获取2个字节的大小(值)
        sum += abs(tmp); //绝对值求和
    }

    sum = sum / (size / 2); //求平均值(2个字节表示一个振幅，所以振幅个数为：size/2个
    if(sum) {
        return  (int)(20.0 * log10(sum));
    }
    return 0;
}

//缩减音频 (size为将要绘制波纹的view的尺寸，不需要请忽略)
- (NSArray *)cutAudioData:(CGSize)size {
    NSMutableArray *filteredSamplesMA = [[NSMutableArray alloc]init];
//    NSData *data = [self getRecorderDataFromURL:self.url];
    //data
    NSData *data = self.audioData;
//    NSLog(@"%@--%ld",data.bytes,data.length/1024);
    NSUInteger sampleCount = data.length / sizeof(SInt16);//计算所有数据个数，通过data长度
    //需要的个数 每秒划分10个
    Float64 count = CMTimeGetSeconds(self.assetTime) * 10;

    NSUInteger binSize = sampleCount; //将数据分割为一个个小包
    
    SInt16 *bytes = (SInt16 *)data.bytes; //总的数据个数
    SInt16 maxSample = 0; //sint16两个字节的空间
    
    //以binSize为一个样本。每个样本中取一个最大数。也就是在固定范围取一个最大的数据保存，达到缩减目的
    for (NSUInteger i = 0; i < sampleCount; i += binSize) {
        //在sampleCount（所有数据）个数据中抽样，抽样方法为在binSize个数据为一个样本，在样本中选取一个数据
        SInt16 sampleBin[binSize];
        for (NSUInteger j = 0; j < binSize; j++) {//先将每次抽样样本的binSize个数据遍历出来
            sampleBin[j] = CFSwapInt16LittleToHost(bytes[i + j]);
        }
        
        //选取样本数据中最大的一个数据
        SInt16 value = [self maxValueInArray:sampleBin ofSize:binSize];
        
        float g_frame_db = (int)(20.0 * log10(value));
        //低于某个值记录时间
        MusicModel *model = [MusicModel new];
//        kAudioPlayerLineSpacing
        model.value = value;
        model.time  = i/binSize * kAudioPlayerLineSpacing;//
        model.peakPower = g_frame_db;
        NSLog(@"时间：%.2f、音频分贝：%.2f",model.time,g_frame_db);
        //保存数据
        [filteredSamplesMA addObject:model];
        //将所有数据中的最大数据保存，作为一个参考。可以根据情况对所有数据进行“缩放”
        if (value > maxSample) {
            maxSample = value;
        }
    }
    
//    NSLog(@"录音文件总时间：%.2f",CMTimeGetSeconds(self.assetTime));
//    NSLog(@"录音文件开始时间：%.2f",CMTimeGetSeconds(self.startTime));
//    NSLog(@"录音文件结束时间：%.2f",CMTimeGetSeconds(self.endTime));
    
    //计算比例因子
    CGFloat scaleFactor = (size.height * 0.5)/maxSample;
    //对所有数据进行“缩放”
    for (NSUInteger i = 0; i < filteredSamplesMA.count; i++) {
        MusicModel *model = filteredSamplesMA[i];
        model.value = model.value * scaleFactor;
//        filteredSamplesMA[i] = @([filteredSamplesMA[i] integerValue] * scaleFactor);
    }
    
    return filteredSamplesMA;
}

-(BOOL)isQuite:(NSData *)pcmData {
    if(pcmData ==nil) {
        return NO;
    }
    long long pcmAllLenght = 0;
    short butterByte[pcmData.length/2];
    memcpy(butterByte, pcmData.bytes, pcmData.length);//frame_size * sizeof(short)
    // 将 buffer 内容取出，进行平方和运算
    for(int i =0; i < pcmData.length/2; i++) {
        pcmAllLenght += butterByte[i] * butterByte[i];
    }
    // 平方和除以数据总长度，得到音量大小。
    double mean   = pcmAllLenght / (double)pcmData.length;
    NSLog(@" -=-=-=--=-=%fmean",mean);
    double volume = 10*log10(mean);//volume为分贝数大小
    NSLog(@" -=-=-=--=-=%f分贝",volume);
    return YES;
}

//比较大小的方法，返回最大值
- (SInt16)maxValueInArray:(SInt16[])values ofSize:(NSUInteger)size {
    SInt16 maxvalue = 0;
    for (int i = 0; i < size; i++) {
        
        if (abs(values[i] > maxvalue)) {
            
            maxvalue = abs(values[i]);
        }
    }
    return maxvalue;
}


- (void)synthetiAudioWithAudioPath:(NSString *)audioPath bgPath:(NSString *)bgPath outPath:(NSString *)outPath completion:(void (^)(BOOL isSucess,NSString * path))completion{
        
    NSString *auidoPath1 = audioPath;
    NSString *audioPath2 = bgPath;

    AVURLAsset *audioAsset1 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:auidoPath1]];
    AVURLAsset *audioAsset2 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:audioPath2]];
 
    
    
    AVMutableComposition *composition = [AVMutableComposition composition];    // 音频轨道
    AVMutableCompositionTrack *audioTrack1 = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
    AVMutableCompositionTrack *audioTrack2 = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
    // 音频素材轨道
    AVAssetTrack *audioAssetTrack1 = [[audioAsset1 tracksWithMediaType:AVMediaTypeAudio] firstObject];
    AVAssetTrack *audioAssetTrack2 = [[audioAsset2 tracksWithMediaType:AVMediaTypeAudio] firstObject];
//    audioAssetTrack2.preferredVolume = 0.5;
    
    AVMutableAudioMixInputParameters *newAudioInputParams = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack2] ;
       [newAudioInputParams setVolumeRampFromStartVolume:0.1 toEndVolume:.5f timeRange:CMTimeRangeMake(kCMTimeZero, audioAsset2.duration)];
       [newAudioInputParams setTrackID:audioTrack2.trackID];
    

     
    AVMutableAudioMix *mix = [AVMutableAudioMix audioMix];
    
    
    
    //得到对应轨道中的音频声音信息，并更改
       AVMutableAudioMixInputParameters *parameters1 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack1];
    
    //得到对应轨道中的音频声音信息，并更改
       AVMutableAudioMixInputParameters *parameters2 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack2];
       [parameters2 setVolume:0.2 atTime:kCMTimeZero];    //从audio1开始让声音变为0.2
       [parameters2 setVolumeRampFromStartVolume:0.2 toEndVolume:0.2 timeRange:CMTimeRangeMake(kCMTimeZero, audioAsset2.duration)];  //在range这个时间段让声音音量平滑的从02变为0.2
    
    mix.inputParameters = @[parameters1,parameters2];
       
    float time1 = CMTimeGetSeconds(audioAsset1.duration);
    float time2 = CMTimeGetSeconds(audioAsset2.duration);
    
    if (time2 > time1) {
        // 音频合并 - 插入音轨文件
        [audioTrack1 insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset1.duration) ofTrack:audioAssetTrack1 atTime:kCMTimeZero error:nil];
        [audioTrack2 insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset2.duration) ofTrack:audioAssetTrack2 atTime:kCMTimeZero error:nil];
    }else{
        NSInteger number = (int)(time1/time2);
        float residue = time1 - number * time2;
        [audioTrack1 insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset1.duration) ofTrack:audioAssetTrack1 atTime:kCMTimeZero error:nil];
        for (int i = 0; i < number; i++) {
            CMTime time = CMTimeMake(i * time2, audioAsset2.duration.timescale);
            [audioTrack2 insertTimeRange:CMTimeRangeMake(time, audioAsset2.duration) ofTrack:audioAssetTrack2 atTime:time error:nil];
        }
        
        if (residue-0.2 > 0) {//如果未结束,添加歌曲时间
            CMTime time = CMTimeMake(number * time2, audioAsset2.duration.timescale);
            CMTime residueTime = CMTimeMake(residue * audioAsset2.duration.timescale, audioAsset2.duration.timescale);
            
            NSError *error;
           BOOL fail = [audioTrack2 insertTimeRange:CMTimeRangeMake(time, residueTime) ofTrack:audioAssetTrack2 atTime:time error:&error];
            if (!fail) {
                NSLog(@"插入失败======%@",error);
            }
        }
    }
    
    // 合并后的文件导出 - 音频文件目前只找到合成m4a类型的
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    NSString *outPutFilePath = outPath;
    session.outputURL = [NSURL fileURLWithPath:outPutFilePath];
    session.outputFileType = AVFileTypeAppleM4A;
    session.audioMix = mix;
    
    
    [session exportAsynchronouslyWithCompletionHandler:^{
        BOOL isSucess = NO;
        if (session.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"合并完成----%@", outPutFilePath);
            isSucess = YES;
        }
        if (completion) {
            completion(isSucess,outPutFilePath);
        }
    }];
}


 
@end

 
