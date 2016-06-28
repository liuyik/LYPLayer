# LYPLayer
可以播放网络和本地视频，可以全屏、调节音量、亮度、进度等。

使用方法
- (void)viewDidLoad {
    [super viewDidLoad];
    
    LYPlayerView *playerView = [LYPlayerView sharedPlayerView];
    [playerView setViewFrame:CGRectMake(0, 0, 375, 250) videoURLStr:@"http://flv2.bn.netease.com/videolib3/1606/22/TunxQ4736/HD/TunxQ4736-mobile.mp4"];
    //点击关闭按钮回调的block
    [playerView setCloseBlock:^(UIButton *button) {
       NSLog(@"close-------%@",button);
    }];

    [self.view addSubview:playerView];
    
}

