//
//  CoreMotionView.m
//  CoreMotionAnimation
//
//  Created by Fangjw on 2017/12/13.
//  Copyright © 2017年 Fangjw. All rights reserved.
//

#import "CoreMotionView.h"
#import <CoreMotion/CoreMotion.h>

#define HEIGHTOFSCREEN [[UIScreen mainScreen] bounds].size.height
#define WIDTHOFSCREEN [[UIScreen mainScreen] bounds].size.width
#define ROADWIDTH 45

@interface CoreMotionView()<UICollisionBehaviorDelegate>{
    NSMutableArray *directionArray;//运动方向
    int XCount;
    int YCount;
    int StartX;
    int StartY;
    NSMutableArray *roadArray;
}

//实现的动画
@property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
//动画行为
@property (nonatomic, strong) UIDynamicItemBehavior *dynamicItemBehavior;
//碰撞行为
@property (nonatomic, strong) UICollisionBehavior *collisionBehavior;
//重力行为
@property (nonatomic, strong) UIGravityBehavior * gravityBehavior;
//传感器
@property (nonatomic, strong) CMMotionManager *motionManager;

@end

@implementation CoreMotionView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self createAnimation];
//        [self createRoad];深度算法随机生成路径
        [self openMotion];
    }
    return self;
}

-(void)createAnimation{
    _dynamicAnimator = [[UIDynamicAnimator alloc]initWithReferenceView:self];
    
    _dynamicItemBehavior = [[UIDynamicItemBehavior alloc]init];
    //弹性系数,数值越大,弹力值越大
    _dynamicItemBehavior.elasticity = 0.5;
    
    //碰撞
    _collisionBehavior = [[UICollisionBehavior alloc]init];
    _collisionBehavior.collisionDelegate=self;
    //开启刚体碰撞
    _collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    
    [self BezierPath:@"line1" pathStartPoint:CGPointMake(50, 0) pathEndPoint:CGPointMake(50, 200)];
    [self BezierPath:@"line2" pathStartPoint:CGPointMake(50, 160) pathEndPoint:CGPointMake(150, 160)];
    [self BezierPath:@"line3" pathStartPoint:CGPointMake(0, 250) pathEndPoint:CGPointMake(250, 250)];
    [self BezierPath:@"line4" pathStartPoint:CGPointMake(100, 200) pathEndPoint:CGPointMake(100, 250)];
    [self BezierPath:@"line5" pathStartPoint:CGPointMake(150, 50) pathEndPoint:CGPointMake(WIDTHOFSCREEN, 50)];
    [self BezierPath:@"line6" pathStartPoint:CGPointMake(250, 50) pathEndPoint:CGPointMake(250, 150)];
    [self BezierPath:@"line7" pathStartPoint:CGPointMake(50, 300) pathEndPoint:CGPointMake(50, HEIGHTOFSCREEN-50)];
    [self BezierPath:@"line8" pathStartPoint:CGPointMake(50, 300) pathEndPoint:CGPointMake(WIDTHOFSCREEN-50, 300)];
    [self BezierPath:@"line9" pathStartPoint:CGPointMake(100, 0) pathEndPoint:CGPointMake(100, 110)];
    [self BezierPath:@"line10" pathStartPoint:CGPointMake(100, 110) pathEndPoint:CGPointMake(200, 110)];
    [self BezierPath:@"line11" pathStartPoint:CGPointMake(200, 110) pathEndPoint:CGPointMake(200, 200)];
    [self BezierPath:@"line12" pathStartPoint:CGPointMake(WIDTHOFSCREEN-50, 300) pathEndPoint:CGPointMake(WIDTHOFSCREEN-50, 100)];
    [self BezierPath:@"line13" pathStartPoint:CGPointMake(WIDTHOFSCREEN-50, 200) pathEndPoint:CGPointMake(WIDTHOFSCREEN-100, 200)];

    [self BezierPath:@"line14" pathStartPoint:CGPointMake(50, 350) pathEndPoint:CGPointMake(WIDTHOFSCREEN/2, 350)];
    [self BezierPath:@"line15" pathStartPoint:CGPointMake(WIDTHOFSCREEN/2, 350) pathEndPoint:CGPointMake(WIDTHOFSCREEN/2, HEIGHTOFSCREEN-100)];
    [self BezierPath:@"line16" pathStartPoint:CGPointMake(100, HEIGHTOFSCREEN) pathEndPoint:CGPointMake(100, 400)];
    [self BezierPath:@"line17" pathStartPoint:CGPointMake(100, 450) pathEndPoint:CGPointMake(150, 450)];
    [self BezierPath:@"line18" pathStartPoint:CGPointMake(WIDTHOFSCREEN/2, 450) pathEndPoint:CGPointMake(WIDTHOFSCREEN-50, 450)];
    [self BezierPath:@"line19" pathStartPoint:CGPointMake(WIDTHOFSCREEN-50, 450) pathEndPoint:CGPointMake(WIDTHOFSCREEN-50, HEIGHTOFSCREEN-50)];
    
    _gravityBehavior = [[UIGravityBehavior alloc]init];
    
    //行为放入动画
    [_dynamicAnimator addBehavior:_dynamicItemBehavior];
    [_dynamicAnimator addBehavior:_collisionBehavior];
    [_dynamicAnimator addBehavior:_gravityBehavior];
    
}

-(void)createRoad{
    XCount= WIDTHOFSCREEN/ROADWIDTH;
    YCount= HEIGHTOFSCREEN/ROADWIDTH;
    StartX = 0;
    StartY = 0;
    directionArray=[@[@[@"0",@"-1"],//上
                      @[@"-1",@"0"],//左
                      @[@"0",@"1"],//下
                      @[@"1",@"0"]]mutableCopy];//右
    
    roadArray=[NSMutableArray new];
    for (int i=0; i<XCount; i++) {
        NSMutableArray *array=[NSMutableArray new];
        for (int j=0; j<YCount; j++) {
            [array addObject:@"0"];
        }
        [roadArray addObject:array];
    }

    [self visitedRoad:StartX Y:StartY];
    for (int i=1; i<XCount; i++) {
        for (int j=1; j<YCount; j++) {
            [self findNextRoad:StartX Y:StartY];
        }
    }

    for (int i=1; i<XCount; i++) {
        [self BezierPath:@"line" pathStartPoint:CGPointMake(ROADWIDTH*i, 0) pathEndPoint:CGPointMake(ROADWIDTH*i, HEIGHTOFSCREEN)];
    }
    for (int j=1; j<YCount; j++) {
        [self BezierPath:@"line" pathStartPoint:CGPointMake(0, ROADWIDTH*j) pathEndPoint:CGPointMake(WIDTHOFSCREEN, ROADWIDTH*j)];
    }
}

-(void)visitedRoad:(int)X Y:(int)Y{
    [roadArray[X] replaceObjectAtIndex:Y withObject:@"1"];
}

-(void)findNextRoad:(int)X Y:(int)Y{
    for (int i=0; i<directionArray.count; i++) {
        //        int count = arc4random() % directionArray.count;
        int x=StartX+[directionArray[i][0] intValue];
        int y=StartY+[directionArray[i][1] intValue];
        
        if (x>=0&&y>=0&&x<XCount&&y<YCount&&[roadArray[x][y] isEqualToString:@"0"]) {
            StartX=x;
            StartY=y;
            [self visitedRoad:StartX Y:StartY];
            return;
        }
    }
}

-(void)BezierPath:(NSString *)pathName pathStartPoint:(CGPoint)pathStartPoint pathEndPoint:(CGPoint)pathEndPoint{
    UIBezierPath *pathLine = [UIBezierPath bezierPath];
    [pathLine moveToPoint:pathStartPoint];
    [pathLine addLineToPoint:pathEndPoint];
    
    CAShapeLayer *layerLine= [CAShapeLayer layer];
    layerLine.path=pathLine.CGPath;
    layerLine.lineWidth=5;
    layerLine.strokeColor=[UIColor blackColor].CGColor;
    [self.layer addSublayer:layerLine];
    
//    [_collisionBehavior addBoundaryWithIdentifier:pathName forPath:pathLine];
    [_collisionBehavior addBoundaryWithIdentifier:pathName fromPoint:pathStartPoint toPoint:pathEndPoint];
}

-(void)openMotion{
    self.motionManager=[[CMMotionManager alloc]init];
    if ([self.motionManager isDeviceMotionAvailable]) {
        ///设备 运动 更新 间隔
        self.motionManager.deviceMotionUpdateInterval = 1;
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            double gravityX = motion.gravity.x;
            double gravityY = motion.gravity.y;
//            double gravityZ = motion.gravity.z;
            // 获取手机的倾斜角度(z是手机与水平面的夹角， xy是手机绕自身旋转的角度)：
//            double z = atan2(gravityZ,sqrtf(gravityX * gravityX + gravityY * gravityY))  ;
            double xy = atan2(gravityX, gravityY);
            // 计算相对于y轴的重力方向
            _gravityBehavior.angle = xy-M_PI_2;
        }];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSArray * imageArray = @[@"ca",@"dog",@"ele",@"rabbit",@"sheep"];
//    int x = arc4random() % (int)self.bounds.size.width;
    int size = arc4random() % 10 +20;
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 10, size, size)];
    
    imageView.image = [UIImage imageNamed:imageArray[arc4random() %  imageArray.count]];
    
    [self addSubview:imageView];
    
    //添加行为
    [_dynamicItemBehavior addItem:imageView];
    [_gravityBehavior addItem:imageView];
    [_collisionBehavior addItem:imageView];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissImage:)];
    tapGestureRecognizer.numberOfTapsRequired=1;
    [imageView addGestureRecognizer:tapGestureRecognizer];
}

-(void)dismissImage:(UITapGestureRecognizer *)tap{
    UIView *tempViews = tap.view;
    [_dynamicItemBehavior removeItem:tempViews];
    [_gravityBehavior removeItem:tempViews];
    [_gravityBehavior removeItem:tempViews];
    [tempViews removeFromSuperview];
}

@end
