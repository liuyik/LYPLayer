//
//  LYPlayer.h
//  LYPlayer
//
//  Created by 刘毅 on 16/6/23.
//  Copyright © 2016年 刘毅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>


@interface LYPlayerView : UIView<UIGestureRecognizerDelegate>
/**
 *  播放器player
 */
@property(nonatomic,retain)AVPlayer       *player;
/**
 *playerLayer,可以修改frame
 */
@property(nonatomic,retain)AVPlayerLayer  *playerLayer;
/**
 *  底部操作工具栏
 */
@property(nonatomic,retain) UIVisualEffectView  *bottomView;
@property(nonatomic,retain) UISlider            *progressSlider;
@property(nonatomic,retain) UIProgressView      *cacheView;
@property(nonatomic,  copy) NSString            *videoURLStr;
/**
 *  BOOL值判断当前的是否全屏
 */
@property(nonatomic,assign) BOOL                isFullscreen;
/**
 *  BOOL值判断当前的是否播放完成
 */
@property(nonatomic,assign) BOOL                playDidEnd;
/**
 *  从xx秒开始播放视频跳转
 */
@property(nonatomic,assign) CGFloat             seekTime;
/**
 *  显示播放时间的UILabel
 */
@property(nonatomic,retain) UILabel             *timeLabel;
/**
 *  控制全屏的按钮
 */
@property(nonatomic,retain) UIButton            *fullScreenBtn;
/**
 *  播放暂停按钮
 */
@property(nonatomic,retain) UIButton            *playOrPauseBtn;
/**
 *  关闭或返回按钮
 */
@property(nonatomic,retain) UIButton            *closeBtn;

/* playItem */
@property(nonatomic,retain) AVPlayerItem        *currentItem;
/**
 *  关闭或返回回调的block
 */
@property(nonatomic, copy) void(^closeBlock)(UIButton *closeButton);
/**
 *  单例
 *
 *  @return LYPlayer
 */
+ (instancetype)sharedPlayerView;

/**
 *  初始化LYPlayer子视图的方法
 *
 *  @param frame       frame
 *  @param videoURLStr URL字符串，包括网络的和本地的URL
 */
- (void)setViewFrame:(CGRect)frame videoURLStr:(NSString *)videoURLStr;

/**
 *  重置player
 */
- (void)resetPlayer;

/**
 *  设置新的视频
 *  @param videoURLStr URL字符串，包括网络的和本地的URL
 */
- (void)resetToPlayNewURL:(NSString *)videoURLStr;
@end
