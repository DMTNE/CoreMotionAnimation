//
//  ViewController.m
//  CoreMotionAnimation
//
//  Created by Fangjw on 2017/12/13.
//  Copyright © 2017年 Fangjw. All rights reserved.
//

#import "ViewController.h"
#import "CoreMotionView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CoreMotionView *view = [[CoreMotionView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:view];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
