//
//  TAIManager.h
//  TAISDK
//
//  Created by kennethmiao on 2018/11/27.
//  Copyright © 2018年 kennethmiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TIWLogger/TIWLogger.h>

@interface TAIManager : NSObject

/*
 获取版本号
 */
+ (NSString *)getVersion;

+ (instancetype)sharedInstance;

- (TIWLogger *)getTiwLog:(NSString *)appId;

- (TIWLogger *)getTiwLog;

/**
 * @brief 是否允许sdk收集网络信息，用于问题诊断和网络优化
 */
+ (void)setCollectNetInfo:(bool)enable;


/**
 * @brief 获取sdk是否收集网络信息
 * @return 是否启用
 */
+ (BOOL)enableCollectNetInfo;
@end
