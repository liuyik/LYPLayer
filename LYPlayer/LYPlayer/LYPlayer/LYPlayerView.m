//
//  LYPlayer.m
//  LYPlayer
//
//  Created by 刘毅 on 16/6/23.
//  Copyright © 2016年 刘毅. All rights reserved.
//

#import "LYPlayerView.h"
#import "Masonry.h"

/*
 *图片
 */
#define CloseImage         [UIImage imageNamed:@"close"]
#define DotImage           [UIImage imageNamed:@"dot"]
#define FullScreenImage    [UIImage imageNamed:@"fullscreen"]
#define NonFullScreenImage [UIImage imageNamed:@"nonfullscreen"]
#define PauseImage         [UIImage imageNamed:@"pause"]
#define PlayImage          [UIImage imageNamed:@"Play"]



@implementation LYPlayerView {
    
    CGRect    _originalFrame;
    id        _timeObserver;
    double    _cache;//缓存进度
    BOOL      _isVolume;
    UISlider  *_volumeViewSlider;
    BOOL      _isAutoHiddenBottomView;//开始是否自动隐藏工具栏
}

- (void)dealloc {
    
    [self removeObserver];
}



#pragma mark - 初始化
+ (instancetype)sharedPlayerView {
    static LYPlayerView *lyPlayer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lyPlayer = [[LYPlayerView alloc] init];
    });
    return lyPlayer;
}

- (void)resetPlayer {
    [self removeObserver];
    // 改为为播放完
    self.playDidEnd         = NO;
    self.currentItem        = nil;
    
    // 视频跳转秒数置0
    self.seekTime           = 0;
    // 暂停
    [self.player pause];
    // 移除原来的layer
    [self.playerLayer removeFromSuperlayer];
    // 替换PlayerItem为nil
    [self.player replaceCurrentItemWithPlayerItem:nil];
    // 把player置为nil
    self.player = nil;

}
//判断播放本地还是网络视频
-(AVPlayerItem *)getPlayItemWithURLString:(NSString *)urlString{
    if ([urlString containsString:@"http"]) {
        
//        AVPlayerItem *playerItem=[AVPlayerItem playerItemWithURL:[NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:urlString]];
        return playerItem;
    }else{
    
        AVAsset *movieAsset  = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:urlString] options:nil];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        return playerItem;
    }
    
}


#pragma mark - 定义子视图
- (void)setViewFrame:(CGRect)frame videoURLStr:(NSString *)videoURLStr{
    
    self.frame = frame;
    _originalFrame = frame;
    self.backgroundColor = [UIColor blackColor];
    self.autoresizesSubviews = NO;
    
    //播放器创建
    self.currentItem = [self getPlayItemWithURLString:videoURLStr];
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.currentItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.layer.bounds;
    [self.layer addSublayer:_playerLayer];

    //创建底部工具视图
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.bottomView = [[UIVisualEffectView alloc] initWithEffect:blur];
    
    [self addSubview:_bottomView];

    //autoLayout bottomView
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).with.offset(0);
        make.right.equalTo(self).with.offset(0);
        make.height.mas_equalTo(40);
        make.bottom.equalTo(self).with.offset(0);
        
    }];
    
    
    //创建播放暂停按钮
    self.playOrPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playOrPauseBtn.showsTouchWhenHighlighted = YES;
    [self.playOrPauseBtn addTarget:self action:@selector(PlayOrPauseAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.playOrPauseBtn setImage:PauseImage forState:UIControlStateNormal];
    [self.playOrPauseBtn setImage:PlayImage forState:UIControlStateSelected];
    self.playOrPauseBtn.selected = YES;
    [self.bottomView addSubview:self.playOrPauseBtn];
    
    //autoLayout _playOrPauseBtn
    [self.playOrPauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(0);
        make.height.mas_equalTo(40);
        make.bottom.equalTo(self.bottomView).with.offset(0);
        make.width.mas_equalTo(40);
        
    }];
    
    //创建全屏按钮
    self.fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fullScreenBtn.showsTouchWhenHighlighted = YES;
    [self.fullScreenBtn addTarget:self action:@selector(fullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.fullScreenBtn setImage:FullScreenImage forState:UIControlStateNormal];
    [self.fullScreenBtn setImage:NonFullScreenImage forState:UIControlStateSelected];
    [self.bottomView addSubview:self.fullScreenBtn];
    
    //autoLayout fullScreenBtn
    [self.fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomView).with.offset(0);
        make.height.mas_equalTo(40);
        make.bottom.equalTo(self.bottomView).with.offset(0);
        make.width.mas_equalTo(40);
        
    }];
    //创建缓存进度view
    self.cacheView = [[UIProgressView alloc] init];
    self.cacheView.progressTintColor = [UIColor whiteColor];
    self.cacheView.trackTintColor = [UIColor blackColor];
    [self.bottomView addSubview:_cacheView];
    
    //autoLayout slider
    [self.cacheView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(45);
        make.right.equalTo(self.bottomView).with.offset(-45);
        make.height.mas_equalTo(2);
        make.centerY.equalTo(self.bottomView.mas_centerY);
    }];

    
    //创建播放进度Slider
    self.progressSlider = [[UISlider alloc]init];
    self.progressSlider.minimumValue = 0.0;
    [self.progressSlider setThumbImage:DotImage forState:UIControlStateNormal];
    self.progressSlider.minimumTrackTintColor = [UIColor greenColor];
    self.progressSlider.maximumTrackTintColor = [UIColor clearColor];
    self.progressSlider.value = 0.0;//指定初始值
    [self.progressSlider addTarget:self action:@selector(updateProgress:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.progressSlider];
    //autoLayout slider
    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(45);
        make.right.equalTo(self.bottomView).with.offset(-45);
        make.height.mas_equalTo(40);
        make.top.equalTo(self.bottomView).with.offset(0);
    }];
    
    
    //timeLabel
    self.timeLabel = [[UILabel alloc]init];
    self.timeLabel.textAlignment = NSTextAlignmentRight;
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.backgroundColor = [UIColor clearColor];
    self.timeLabel.font = [UIFont systemFontOfSize:11];
    [self.bottomView addSubview:self.timeLabel];
    //autoLayout timeLabel
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(45);
        make.right.equalTo(self.bottomView).with.offset(-45);
        make.height.mas_equalTo(20);
        make.bottom.equalTo(self.bottomView).with.offset(0);
    }];
    
    [self bringSubviewToFront:self.bottomView];
    
    //创建取消按钮
    _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _closeBtn.showsTouchWhenHighlighted = YES;
    [_closeBtn addTarget:self action:@selector(colseTheVideo:) forControlEvents:UIControlEventTouchUpInside];
    [_closeBtn setImage:CloseImage forState:UIControlStateNormal];
    _closeBtn.layer.cornerRadius = 30/2;
    [self addSubview:_closeBtn];
    
     [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.equalTo(self.bottomView).with.offset(5);
        make.height.mas_equalTo(30);
        make.top.equalTo(self).with.offset(5);
        make.width.mas_equalTo(30);
        
        
    }];
    
    
    //添加观察者
    [self addObserver];
    //添加手势
    [self addGesture];
    //配置音量
    [self configureVolume];
    
    //3.5后隐藏工具视图
    _isAutoHiddenBottomView = YES;
    [self performSelector:@selector(hiddenBottomView) withObject:nil afterDelay:3.5];
}
- (void)hiddenBottomView {
    if (_isAutoHiddenBottomView) {
        [UIView animateWithDuration:0.5 animations:^{
            
            _bottomView.alpha = 0;
            _closeBtn.alpha = 0;
        } completion:^(BOOL finished) {
            
            _closeBtn.hidden = YES;
            _bottomView.hidden = YES;
            
            _bottomView.alpha = 1;
            _closeBtn.alpha = 1;
        }];
    }

}
//设置新的视频
- (void)resetToPlayNewURL:(NSString *)videoURLStr {
    [self resetPlayer];
    //播放器创建
    self.currentItem = [self getPlayItemWithURLString:videoURLStr];
    
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.currentItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.layer.bounds;
    [self.layer insertSublayer:self.playerLayer atIndex:0];
    //添加观察者
    [self addObserver];
    //添加手势
    [self addGesture];
}
#pragma mark - 添加手势和手势处理
- (void)addGesture{
    //单击
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self addGestureRecognizer:tap];
    
    // 双击(播放/暂停)
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapAction:)];
    [doubleTap setNumberOfTapsRequired:2];
    [self addGestureRecognizer:doubleTap];
    
    [tap requireGestureRecognizerToFail:doubleTap];
}
//单击
- (void)tapAction:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        if (_bottomView.hidden == YES || _closeBtn.hidden == YES) {
            _closeBtn.hidden = NO;
            _bottomView.hidden = NO;
            
            //3.5后隐藏工具视图
            _isAutoHiddenBottomView = YES;
            [self performSelector:@selector(hiddenBottomView) withObject:nil afterDelay:3.5];
        }else {
            _isAutoHiddenBottomView = NO;
            [UIView animateWithDuration:0.5 animations:^{
                
                _bottomView.alpha = 0;
                _closeBtn.alpha = 0;
            } completion:^(BOOL finished) {
                
                _closeBtn.hidden = YES;
                _bottomView.hidden = YES;
                
                _bottomView.alpha = 1;
                _closeBtn.alpha = 1;
            }];
        }
    }
    
}
//双击
- (void)doubleTapAction:(UITapGestureRecognizer *)gesture
{
    [self PlayOrPauseAction:self.playOrPauseBtn];
}
//滑动
- (void)panAction:(UIPanGestureRecognizer *)pan {
    //根据在view上Pan的位置，确定是调音量还是亮度
    CGPoint locationPoint = [pan locationInView:self];
    
    // 我们要响应水平移动和垂直移动
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self];
    static BOOL isHorizontal = NO;
    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{ // 开始移动
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { // 水平移动
            
                isHorizontal = YES;
            }
            else if (x < y){ // 垂直移动
                
                // 开始滑动的时候,状态改为正在控制音量
                if (locationPoint.x > self.bounds.size.width / 2) {
                    _isVolume = YES;
                }else { // 状态改为显示亮度调节
                    _isVolume = NO;
                }
                isHorizontal = NO;
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{ // 正在移动
            if (isHorizontal) {
                // 每次滑动需要叠加时间
                self.seekTime += veloctyPoint.x / 200;
                
                // 需要限定sumTime的范围
                CMTime totalTime           = self.currentItem.duration;
                CGFloat totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
                if (self.seekTime > totalMovieDuration) { self.seekTime = totalMovieDuration;}
                if (self.seekTime < 0){ self.seekTime = 0; }
                
                // 当前播放的时间
               [self.player seekToTime:CMTimeMakeWithSeconds(self.seekTime, 1)];
                
            }else {
                //音量or亮度
                _isVolume ? (_volumeViewSlider.value -= veloctyPoint.y / 10000) : ([UIScreen mainScreen].brightness -= veloctyPoint.y / 10000);
            }
            

        }
        case UIGestureRecognizerStateEnded:{ // 移动停止
            NSLog(@"移动停止");
        }
        default:
            break;
    }
}

#pragma mark - 获取系统音量
- (void)configureVolume
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: &setCategoryError];
    
    if (!success) {}
    
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint point = [touch locationInView:self];
    // （屏幕下方slider区域） || （在cell上播放视频 && 不是全屏状态） || (播放完了) =====>  不响应pan手势
    if ((point.y > self.bounds.size.height-40) || !self.isFullscreen || self.playDidEnd) { return NO; }
    return YES;
}
#pragma mark - 数据处理
//时间转换
- (NSString *)convertTime:(CGFloat)second{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [dateFormatter setDateFormat:@"HH:mm:ss"];
    } else {
        [dateFormatter setDateFormat:@"mm:ss"];
    }
    NSString *newTime = [dateFormatter stringFromDate:d];
    return newTime;
}

#pragma mark - 事件处理
//播放暂停
- (void)PlayOrPauseAction:(UIButton *)button {
//    button.selected = !button.selected;
    if (self.player.rate != 1.f) {
       
        [self.player play];
        button.selected = NO;
    } else {
        [self.player pause];
        button.selected = YES;
    }
    
    _isAutoHiddenBottomView = NO;
}
//关闭
- (void)colseTheVideo:(UIButton *)button{
    
//    self.hidden = YES;
    [self.player pause];
    self.closeBlock(button);
    
    _isAutoHiddenBottomView = NO;
}
//全屏
- (void)fullScreenAction:(UIButton *)button {

    if (button.selected == NO) {
        [self toFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
    }else {
        [self toScreenNormal:UIInterfaceOrientationPortrait];
    }
    
    
    _isAutoHiddenBottomView = NO;
}
//进度
- (void)updateProgress:(UISlider *)slider{
    if(_cache > slider.value) {
        
        [self.player seekToTime:CMTimeMakeWithSeconds(slider.value, 1)];
        self.seekTime = slider.value;
    }
    else {
        [self.player seekToTime:CMTimeMakeWithSeconds(_cache, 1)];
        self.seekTime = _cache;
    }
    
    
    _isAutoHiddenBottomView = NO;
}

#pragma mark - 屏幕旋转
//垂直
-(void)toScreenNormal:(UIInterfaceOrientation )interfaceOrientation{
    
    if (self.isFullscreen == YES) {
        //转换屏幕
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            
            SEL selector = NSSelectorFromString(@"setOrientation:");
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:[UIDevice currentDevice]];
            int val = interfaceOrientation;
            [invocation setArgument:&val atIndex:2];
            [invocation invoke];
            
            
        }
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        self.transform = CGAffineTransformIdentity;
        
        self.frame = _originalFrame;
        self.playerLayer.frame =  self.bounds;

        
    }completion:^(BOOL finished) {
        self.isFullscreen = NO;
        self.fullScreenBtn.selected = NO;
        
        //        [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
        
    }];
}
//水平
-(void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation{
    
        if (self.isFullscreen == NO) {
            if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
                
                SEL selector = NSSelectorFromString(@"setOrientation:");
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
                [invocation setSelector:selector];
                [invocation setTarget:[UIDevice currentDevice]];
                int val = interfaceOrientation;
                [invocation setArgument:&val atIndex:2];
                [invocation invoke];
                
                
            }
        }

//        }
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        self.playerLayer.frame =  CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    
    
}

#pragma mark - 观察者的添加与移除
//添加观察者
- (void)addObserver {
    
    //旋转屏幕通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    //block监听播放进度
    __weak typeof(UISlider *) weakSlider = _progressSlider;
    __weak typeof(AVPlayerItem *) weakItem = _currentItem;
    __weak typeof(UILabel *) weakLabel = _timeLabel;
    __weak typeof(self) weakSelf = self;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        double current = CMTimeGetSeconds(time);
        if (!isnan(CMTimeGetSeconds(weakItem.duration))) {
            double total = CMTimeGetSeconds(weakItem.duration);
            
            //设置滑块的最大值
            weakSlider.maximumValue = total;
            weakSlider.value = current;
            //设置时间Label
            NSString *currentTime = [weakSelf convertTime:current];
            NSString *totalTime = [weakSelf convertTime:total];
            weakLabel.text = [NSString stringWithFormat:@"%@/%@",currentTime,totalTime];
        }
        
        
    }];
    //KVO监听缓存
    [_currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //KVO监听状态
    [_currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //添加观察者监听播放的状态
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    // 监听耳机插入和拔掉通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
}
//移除观察者
- (void)removeObserver{
    if (_timeObserver) {
        [_player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
    [_currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_currentItem removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    
}
#pragma mark - 观察者的监听事件
//监听缓存和播放状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void *)context {
    
    AVPlayerItem * sonItem = object;
    //缓存
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray * array = sonItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue]; //本次缓冲的时间范围
        NSTimeInterval totalBuffer = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration); //缓冲总长度
        _cache = totalBuffer;
        self.cacheView.progress = totalBuffer;
        //        NSLog(@"共缓冲%.2f",totalBuffer);
    
    }
    //是否开始播放
    if ([keyPath isEqualToString:@"status"]) {
        switch (_player.status) {
            case AVPlayerStatusUnknown:
                NSLog(@"未知状态，此时不能播放");
                break;
            case AVPlayerStatusReadyToPlay:
            {
                //按钮的状态
                _playOrPauseBtn.selected = NO;
                [_player play];
                self.playDidEnd = NO;
                NSLog(@"准备完毕,可以播放");
                
                // 跳到xx秒播放视频
                if (self.seekTime) {
                    [self.player seekToTime:CMTimeMakeWithSeconds(self.seekTime, 1)];

                }
                
                // 加载完成后，再添加平移手势
                // 添加平移手势，用来控制音量、亮度、快进快退
                UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
                pan.delegate                = self;
                [self addGestureRecognizer:pan];
                
              
            }
                break;
            case AVPlayerStatusFailed:
                NSLog(@"加载失败，网络或者服务器出现问题");
                break;
            default:
                break;
        }
    }
}

//播放完成调用的方法
- (void)playbackFinished:(NSNotification *)notice {
    
    _progressSlider.value = 0;
    _playOrPauseBtn.selected = YES;
    
    self.playDidEnd = YES;
    NSLog(@"播放完成");
    [self removeObserver];
}

// 旋转屏幕通知
- (void)onDeviceOrientationChange{
    if (self.player==nil||self.superview==nil){
        return;
    }
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:{
            NSLog(@"状态栏在下");
        }
            break;
        case UIInterfaceOrientationPortrait:{
            NSLog(@"状态栏在上");

            self.isFullscreen = NO;
            self.fullScreenBtn.selected = NO;
            [self toScreenNormal:UIInterfaceOrientationPortrait];

        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            NSLog(@"状态栏在左");
            
            self.isFullscreen = YES;
            self.fullScreenBtn.selected = YES;
            [self toFullScreenWithInterfaceOrientation:interfaceOrientation];

        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            NSLog(@"状态栏在右");

            self.isFullscreen = YES;
            self.fullScreenBtn.selected = YES;
            [self toFullScreenWithInterfaceOrientation:interfaceOrientation];

        }
            break;
        default:
            break;
    }
}
/**
 *  耳机插入、拔出事件
 */
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;

    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];

    switch (routeChangeReason) {

        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // 耳机插入
            break;

        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            // 耳机拔掉
            // 拔掉耳机继续播放
            [self.player play];
        }
            break;

        case AVAudioSessionRouteChangeReasonCategoryChange:
            
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}

@end
