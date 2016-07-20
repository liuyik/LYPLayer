//
//  ViewController.m
//  LYPlayer
//
//  Created by 刘毅 on 16/6/28.
//  Copyright © 2016年 刘毅. All rights reserved.
//

#import "ViewController.h"
#import "LYPlayerView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    LYPlayerView *playerView = [LYPlayerView sharedPlayerView];
    [playerView setViewFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 250) videoURLStr:@"http://flv2.bn.netease.com/videolib3/1606/22/TunxQ4736/HD/TunxQ4736-mobile.mp4"];
    //点击关闭按钮回调的block
    [playerView setCloseBlock:^(UIButton *button) {
       NSLog(@"close-------%@",button);
    }];

    [self.view addSubview:playerView];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
