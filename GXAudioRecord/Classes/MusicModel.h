//
//  MusicModel.h
//  AudioRecorder
//
//  Created by gaoguangxiao on 2018/7/30.
//  Copyright © 2018年 gaoguangxiao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MusicModel : NSObject

@property(nonatomic,assign)float value;//取值0~1之间
@property(nonatomic,assign)Float64 time;//时间

@property (nonatomic, assign) float peakPower;

@property(nonatomic,assign)NSInteger patCount;

@end
