//
//  GGXFileManeger.m
//  AudioRecorder
//
//  Created by 高广校 on 2023/8/24.
//  Copyright © 2023 gaoguangxiao. All rights reserved.
//

#import "GGXFileManeger.h"

#define kAudioFileName @"Audio"
#define kAudioRecordConvertedPCMFile @"convert.caf"
#define kAudioRecordConvertedCAFFile @"caf"

@implementation GGXFileManeger

+ (instancetype)shared {
    static GGXFileManeger *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSString *)createFilePathWithFormat:(NSString *)fileConverte {
    NSString *documentDicPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dictionaryName = [documentDicPath stringByAppendingPathComponent:kAudioFileName];
    
    NSString *plistPath = [self getPlistPath:dictionaryName];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    //
    NSString *videoDestDateString = [self createFileNamePrefix];
    
    if (![fileManager fileExistsAtPath:plistPath]) {
        // 创建文件下载目录
        NSString *directoryPath = dictionaryName;
        [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        // 创建plist文件
        [fileManager createFileAtPath:plistPath contents:nil attributes:nil]; // 立即在沙盒中创建一个空plist文件
        
        NSMutableArray *array = [NSMutableArray new];
        [array writeToFile:plistPath atomically:YES];//写入空数据
    }
    
    NSMutableArray *array = [NSMutableArray arrayWithContentsOfFile:plistPath];
    //
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    NSString *filePath2 = [NSString stringWithFormat:@"%@.%@",videoDestDateString,fileConverte];
    
    [dict setValue:filePath2 forKey:@"name"];
    [array addObject:dict];
    [array writeToFile:plistPath atomically:YES];
    
    NSString *filepath = [documentDicPath stringByAppendingPathComponent:filePath2];
    return filepath;
}

- (NSString *)createFilePath {
    return [self createFilePathWithFormat:kAudioRecordConvertedCAFFile];
}

- (NSString *)getFilePath:(NSString *)fileName {
    NSString *documentDicPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [documentDicPath stringByAppendingPathComponent:fileName];
}

- (NSMutableArray *)getPlistData {
    NSString *documentDicPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dictionaryName = [documentDicPath stringByAppendingPathComponent:kAudioFileName];
    NSString *plistPath = [dictionaryName stringByAppendingPathComponent:@"AudioRecord.plist"];
    NSMutableArray *dict = [NSMutableArray arrayWithContentsOfFile:plistPath];
    return dict;
}

/**
 *  创建文件名
 */
- (NSString *)createFileNamePrefix {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];//zzz
    NSString *destDateString = [dateFormatter stringFromDate:[NSDate date]];
    return destDateString;
}

///获取plist文件路径
- (NSString *)getPlistPath:(NSString *)path{
    NSString *plistPath = [path stringByAppendingPathComponent:@"AudioRecord.plist"];
    return plistPath;
}

@end
