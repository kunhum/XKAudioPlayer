//
//  OCViewController.m
//  XKAudioPlayer_Example
//
//  Created by kenneth on 2022/5/23.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "OCViewController.h"
@import XKAudioPlayer;

NSString *mp31 = @"http://downsc.chinaz.net/Files/DownLoad/sound1/201906/11582.mp3";
NSString *mp32 = @"http://downsc.chinaz.net/files/download/sound1/201206/1638.mp3";

@interface OCViewController ()

@property (nonatomic, strong) XKAudioPlayer *player;

@property (nonatomic, assign) NSInteger tag;

@end

@implementation OCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.player = [XKAudioPlayer new];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    if (self.tag == 0) {
        [self.player playWithPaths:@[mp31, mp32]];
        self.tag++;
    } else {
        [self.player appendWithPath:mp31];
    }
    
    NSLog(@"OC 点击");
}

@end
