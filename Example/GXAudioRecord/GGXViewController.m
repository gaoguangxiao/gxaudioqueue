//
//  GGXViewController.m
//  GXAudioRecord
//
//  Created by gaoguangxiao on 08/25/2023.
//  Copyright (c) 2023 gaoguangxiao. All rights reserved.
//

#import "GGXViewController.h"
#import "AQRecordController.h"
@interface GGXViewController ()

@end

@implementation GGXViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self pushVc:nil];
}

- (IBAction)pushVc:(id)sender {
    AQRecordController *Vc = [AQRecordController new];
    [self.navigationController pushViewController:Vc animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
