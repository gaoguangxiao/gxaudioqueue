//
//  GGXFileManeger.h
//  AudioRecorder
//
//  Created by 高广校 on 2023/8/24.
//  Copyright © 2023 gaoguangxiao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GGXFileManeger : NSObject

+ (instancetype)shared;

/// 自动创建文件，返回创建完毕的
- (NSString *)createFilePath;

- (NSString *)createFilePathWithFormat:(NSString *)fileConverte;

- (NSMutableArray *)getPlistData;


/// 获取全路径
/// - Parameter fileName: <#fileName description#>
- (NSString *)getFilePath:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
