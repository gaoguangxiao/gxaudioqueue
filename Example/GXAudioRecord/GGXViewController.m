//
//  GGXViewController.m
//  GXAudioRecord
//
//  Created by gaoguangxiao on 08/25/2023.
//  Copyright (c) 2023 gaoguangxiao. All rights reserved.
//

#import "GGXViewController.h"
#import "AQRecordController.h"
//#import "AFServiceNet/CustomUtil.h"
//#import "AFServiceNet/Service.h"
#import <GXSwiftNetwork-Swift.h>
#import <RSAdventureApi-Swift.h>
#import <GXAudioRecord_Example-Swift.h>
@interface GGXViewController ()

@end

@implementation GGXViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//    [self pushVc:nil];
//    [CustomUtil saveAcessToken:@"Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJCYXpoZkIxMCIsInV1aWQiOiI1ZDg2YThmYjhlNzU0YjVjOTlmZTQxOGViZjc3M2U0MCIsInRpbWVzdGFtcCI6MTcyODU0NjA1Njc5N30.IBJsvTBN7XyOMEHZEGkbQj_YH5kuHDpBpKYNCWI0xPR_-HrnuC0YdFLzP98tvvqS6MH6u3FlTsUSdxr8LdtTrg"];
//    https://gateway-test.risekid.cn/wap/api/certificate/tencent
    [MSBApiConfig.shared setApiConfigWithApiHost:@"https://gateway-test.risekid.cn"
                                   commonHeaders:@{@"token":@"Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJCYXpoZkIxMCIsInV1aWQiOiI1ZDg2YThmYjhlNzU0YjVjOTlmZTQxOGViZjc3M2U0MCIsInRpbWVzdGFtcCI6MTcyODU0NjA1Njc5N30.IBJsvTBN7XyOMEHZEGkbQj_YH5kuHDpBpKYNCWI0xPR_-HrnuC0YdFLzP98tvvqS6MH6u3FlTsUSdxr8LdtTrg"}
                             isAddDefaultHeaders:YES];
    [self loadCerData];
}

- (IBAction)pushVc:(id)sender {
    AQRecordController *Vc = [AQRecordController new];
    [self.navigationController pushViewController:Vc animated:YES];
    
    [self loadCerData];
}

- (void)loadCerData {
    
//    TencentSOE *soe = [TencentSOE new];
//    soe.
    SOE *s = [SOE new];
    [s startSOE];
//    soe st
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSString *url = [NSString stringWithFormat:@"/wap/api/certificate/tencent"];
//        CGDataResult *r = [Service loadNetWorkingMethodisPost:NO ByParameters:@{} andBymethodName:url];;
////        NSArray *list = [NSArray yy_modelArrayWithClass:PopupMenusModel.class json:r.dataList];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSLog(@"r:%@",r.dataList);
//        });
//    });
    
//    [self showAnimated:YES title:@"" whileExecutingBlock:^CGDataResult *{
//        return [Service loadNetWorkingMethodisPost:NO ByParameters:@{} andBymethodName:url];
//    } completionBlock:^(BOOL b, CGDataResult *r) {
////        r = [TESTDATA testData:@"audioRecordDetail.json"];
//        if (r.dataList) {
//            RSAudioDetailModel *apModel = [RSAudioDetailModel yy_modelWithDictionary:r.dataList];
//            [self.audioContentView fillWithData:apModel];
//            [self.operationAudioView fillWithData:apModel];
//        }
//    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
