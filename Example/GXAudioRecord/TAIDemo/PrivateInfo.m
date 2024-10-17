//
//  PrivateInfo.m
//  TAIDemo
//
//  Created by kennethmiao on 2019/2/26.
//  Copyright © 2019年 kennethmiao. All rights reserved.
//

#import "PrivateInfo.h"

@implementation PrivateInfo

+ (instancetype)shareInstance
{
    static PrivateInfo *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
//        自行传入appId, secretId, secretKey参数
        instance = [[PrivateInfo alloc] init];
        instance.appId = @"";
        instance.secretId = @"AKIDDhg0ClI7nkDzqwbAWeeNkDZN0DOl2-Ti-Nzrki8Kgr0KoX5S8ZNo2NTExkZ-Up6c";
        instance.secretKey = @"ZWlKDvjC00bwEBXnZB23EaO03jiYhLJROvEsTuAwFUQ=";
        instance.token = @"zLOnwGQ2Gs7e7aM9XtjV41MtNJyPFxBa7d3d698582af9f85a93d9d2957116b59BjX4MaasmrNIHBXpfopX5t4IKnhZW8a0zI5qt9-eWrL13vOGe14PxQKuiJ7hkK7-kHjOq3WKzfxXK44LmMD3jNhL8RpXijHqSNPAPkBe-CfdnIQN4qS48OoAhYUmP_8yioXWQfiAsUerM2zGfSPvwyvwFguO3a3pMPCCshOokxPCcJc9sOq2Dl46s4b4ViQ-BdL3VWFMXKc4NUHlzJarDhYC8BNOa8dGGBIYOpmS9krFjXApMMYb6X4thnCbN73RFkZW8JEkAdPEEEpo0Lp0v7qhdDwQ9-RE6mKtCY-C-0s1hylQ3CfpPZmkMIS1N4OI_IWlEgM8KDUgaUettliVfw";
        instance.soeAppId = @"";
        instance.hcmAppId = @"";
    });
    return instance;
}
@end
