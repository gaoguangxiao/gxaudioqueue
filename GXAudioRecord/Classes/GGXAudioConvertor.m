//
//  GGXAudioConvertor.m
//  GXAudioRecord
//
//  Created by 高广校 on 2023/9/10.
//

#import "GGXAudioConvertor.h"

#import <AVFoundation/AVFoundation.h>
#import "GGXAudioQueueHeader.h"
#import "lame.h"
@implementation GGXAudioConvertor

//导出M4A
+(void)convertCAFToM4A:(NSURL *)path outPath:(NSURL *)outPath andComplete:(void (^ _Nullable)(id _Nonnull))block{
    //获取音频元数据
    AVURLAsset *audioAsset = [AVURLAsset assetWithURL:path];
    [self convertCAFToM4A:kCMTimeZero endTime:audioAsset.duration inputPath:path outPath:outPath andComplete:block];
}

+(void)convertWAVToM4A:(CMTime)source endTime:(CMTime)end inputPath:(NSURL *)inputpath outPath:(NSURL *)outPath andComplete:(void (^ _Nullable)(id _Nonnull))block{
    //音频输出会话
    AVURLAsset *audioAsset = [AVURLAsset assetWithURL:inputpath];
    //音频输出会话
    //AVAssetExportPresetAppleM4A
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:audioAsset presetName:AVAssetExportPresetAppleM4A];
    exportSession.outputURL = outPath;
    exportSession.outputFileType = AVFileTypeAppleM4A;
    //1 1.5
    exportSession.timeRange = CMTimeRangeFromTimeToTime(source, end);
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        //exporeSession.status
        if (AVAssetExportSessionStatusCompleted == exportSession.status) {
            //            NSLog(@"新文件路径:%@",outPath);
            block(outPath);
        } else if (AVAssetExportSessionStatusFailed == exportSession.status) {
            NSLog(@"导出失败！");
        }else{
            NSLog(@"Export Session Status: %ld", (long)exportSession.status);
        }
    }];
}

//裁剪音频
+(void)tailorAudioTimeRange:(CMTimeRange)timeRange outSettings:(NSDictionary *)outputSettings inputPath:(NSString *)originalPath outPath:(NSString *)outputPath andComplete:(void (^ _Nullable)(id _Nonnull))block {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:originalPath]) {
        NSLog(@"文件不存在");
        return ;
    }
    NSError *error = nil;
    NSURL *originalUrl = [NSURL fileURLWithPath:originalPath];
    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
    if ([fm fileExistsAtPath:outputPath]) {
        NSLog(@"outPutUrl：文件存在，删除");
        [fm removeItemAtPath:outputPath error:&error];
    }
    
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:originalUrl options:nil];    //读取原始文件信息
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:songAsset error:&error];
    if (error) {
        NSLog(@"error: %@", error);
        return;
    }
    assetReader.timeRange = timeRange;
    AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput
                                              assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks
                                              audioSettings: nil];
    if (![assetReader canAddOutput:assetReaderOutput]) {
        NSLog(@"can't add reader output... die!");
        return;
    }
    assetReaderOutput.alwaysCopiesSampleData = NO;//是否总是拷贝采样数据。如果要修改读取的采样数据，可以设置 YES，否则就设置 NO，这样性能会更好。
    [assetReader addOutput:assetReaderOutput];
    
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:outputURL fileType:AVFileTypeWAVE error:&error];
    if (error) {
        NSLog(@"error: %@", error);
        return;
    }
    AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:outputSettings];
    if ([assetWriter canAddInput:assetWriterInput]) {
        [assetWriter addInput:assetWriterInput];
    } else {
        NSLog(@"can't add asset writer input... die!");
        return;
    }
    assetWriterInput.expectsMediaDataInRealTime = NO;
    [assetWriter startWriting];
    [assetReader startReading];
    
    AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
    CMTime _startTime = CMTimeMakeWithSeconds(0, soundTrack.naturalTimeScale);
    [assetWriter startSessionAtSourceTime:_startTime];
    
    __block UInt64 convertedByteCount = 0;
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
//    `requestMediaDataWhenReadyOnQueue` AVAssetWriterInput 在方便的时候去请求数据并写入输出文件。在对接拉取式的数据源时，可以用这个方法。
    [assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue  usingBlock: ^{
        while (assetWriterInput.readyForMoreMediaData) {//表示AVAssetWriterInput 是否已经准备好接受媒体数据
            CMSampleBufferRef nextBuffer = [assetReaderOutput copyNextSampleBuffer];            
            if (nextBuffer) {
                // append buffer
                [assetWriterInput appendSampleBuffer: nextBuffer];
                convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
            } else {
                [assetWriterInput markAsFinished];
                [assetWriter finishWritingWithCompletionHandler:^{
                }];
                [assetReader cancelReading];
                block(outputPath);
                break;
            }
        }
    }];
}

//m4a转成wav
+ (void)convertM4AToWAV:(NSString *)originalPath
                outPath:(NSString *)outputPath
                success:(void(^)(NSString *outputPath))success
                failure:(void(^)(NSError *error))failure {
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:originalPath]) {
        NSLog(@"文件不存在");
        return ;
    }
    NSError *error = nil;
    NSURL *originalUrl = [NSURL fileURLWithPath:originalPath];
    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
    if ([fm fileExistsAtPath:outputPath]) {
        NSLog(@"outPutUrl：文件存在，删除");
        [fm removeItemAtPath:outputPath error:&error];
    }
    
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:originalUrl options:nil];    //读取原始文件信息
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:songAsset error:&error];
    if (error) {
        NSLog(@"error: %@", error);
        return;
    }
    AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput
                                              assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks
                                              audioSettings: nil];
    if (![assetReader canAddOutput:assetReaderOutput]) {
        NSLog(@"can't add reader output... die!");
        return;
    }
    [assetReader addOutput:assetReaderOutput];
    
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:outputURL fileType:AVFileTypeCoreAudioFormat error:&error];
    if (error) {
        NSLog(@"error: %@", error);
        return;
    }
    AudioChannelLayout channelLayout;
    //memset用于将channelLayout结构初始化为零，确保没有未定义的值。
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    //mChannelLayoutTag设置为kAudioChannelLayoutTag_Mono，表示使用单声道布局。
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;//
    //这行代码将channelLayout结构转换为NSData对象，以便可以将其用作音频设置的一部分。
    NSData *channelLayoutAsData = [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)];
    /** 配置音频参数 */
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                    [NSNumber numberWithFloat:kDefaultSampleRate], AVSampleRateKey,
                                    [NSNumber numberWithInt:kDefaultChannels], AVNumberOfChannelsKey,
                                    channelLayoutAsData, AVChannelLayoutKey,
                                    [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                    [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                    nil];
    AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio                                                                                outputSettings:outputSettings];
    if ([assetWriter canAddInput:assetWriterInput]) {
        [assetWriter addInput:assetWriterInput];
    } else {
        NSLog(@"can't add asset writer input... die!");
        return;
    }
    [assetWriter startWriting];
    [assetReader startReading];
    
    AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
    CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
    [assetWriter startSessionAtSourceTime:startTime];
    
    __block UInt64 convertedByteCount = 0;
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    [assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue  usingBlock: ^{
        while (assetWriterInput.readyForMoreMediaData) {
            CMSampleBufferRef nextBuffer = [assetReaderOutput copyNextSampleBuffer];
            if (nextBuffer) {
                // append buffer
                [assetWriterInput appendSampleBuffer: nextBuffer];
                convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
            } else {
                [assetWriterInput markAsFinished];
                [assetWriter finishWritingWithCompletionHandler:^{
                }];
                [assetReader cancelReading];
                success(outputPath);
                break;
            }
        }
    }];
}

+ (void)convertM4AToMp3:(NSString *)originalPath
                outPath:(NSString *)outputPath
                success:(void(^)(NSString *mp3Path))success
                failure:(void(^)(NSError *error))failure {
    
    [self convertM4AToWAV:originalPath outPath:outputPath success:^(NSString * _Nonnull outputPath) {
        [self convertPCMToMp3:originalPath outPath:outputPath success:^(NSString *outPath) {
            success(outPath);
        } failure:^(NSError *error) {
            failure(error);
        }];
    } failure:^(NSError * _Nonnull error) {
        
    }];
}

// wav 转 mp3
+ (void)convertPCMToMp3:(NSString *)pcmFilePath
                outPath:(NSString *)outputPath
                success:(void(^)(NSString *outPath))success
                failure:(void(^)(NSError *error))failure {
    
    // 判断输入路径是否存在
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:pcmFilePath])
    {
//        NSLog(@"文件不存在");
        return ;
    }
    
    // 输出路径
    NSString *mp3FilePath = [[pcmFilePath stringByDeletingPathExtension] stringByAppendingString:@".mp3"];
    @try {
        
        int channel = 1;
        int read, write;
        FILE *pcm = fopen([pcmFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        if (!pcm) {
            return;
        }
        
        // 删除头，否则在前一秒钟会有杂音
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
//        lame_t lame = lame_init();
//        lame_set_num_channels(lame,channel);
//        lame_set_in_samplerate(lame, kDefaultSampleRate);
//        //        lame_set_out_samplerate(lame, kMSBAudioSampleRate/2); //设置输出数据采样率，默认和输入的一致
//        //关键这一句！！！！！！！！！！！！
//        lame_set_VBR_mean_bitrate_kbps(lame, 24);
//        // lame_set_VBR(lame, vbr_default);//压缩级别参数：
//        lame_set_brate(lame,16);/* CBR模式下的，CBR比特率 */
//        lame_set_mode(lame,MONO);//输出通道数 模式参数:stereo 双，MONO 单
//        lame_set_quality(lame,2);/* 2=high  5 = medium  7=low */
//
//        lame_init_params(lame);
//
//        do {
//            read = (int)fread(pcm_buffer, channel*sizeof(short int), PCM_SIZE, pcm);
//            if (read == 0)
//                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
//            else {
//                if (channel == 2) {
//                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
//                }else {//单声道走这
//                    write = lame_encode_buffer(lame, pcm_buffer, NULL, read, mp3_buffer, MP3_SIZE);
//                }
//
//            }
//
//            /*
//             * 二进制形式写数据到文件中
//             *
//             * mp3_buffer：数据输出到文件的缓冲区首地址
//             * write：一个数据块的字节数
//             * 1：指定一次输出数据块的个数
//             * mp3：文件指针
//             */
//            fwrite(mp3_buffer, write, 1, mp3);
//
//        } while (read != 0);
//        lame_mp3_tags_fid(lame, mp3);
//
//        lame_close(lame);
//        fclose(mp3);
//        fclose(pcm);
    } @catch (NSException *exception) {
        NSLog(@"%@", [exception description]);
        if (failure) {
            failure(nil);
        }
    } @finally {
        NSLog(@"PCM转换MP3转换成功");
        if (success) {
            success(mp3FilePath);
        }
    }
}


@end
