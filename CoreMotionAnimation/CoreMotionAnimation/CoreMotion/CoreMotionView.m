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
//#define ROADWIDTH 40 //宽度
#define XCount 10//X轴个数
#define YCount 15//Y轴个数

@interface CoreMotionView()<UICollisionBehaviorDelegate>{
    NSMutableArray *directionArray;//运动方向
    int XROADWIDTH;//宽度
    int YROADWIDTH;
//    int XCount;//X轴个数
//    int YCount;//Y轴个数
    int StartX;//开始点
    int StartY;
    int BackCount;//退回
    NSMutableArray *roadArray;//判断是否访问过
    NSMutableArray *pathArray;//运动轨迹
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
        [self createRoad];//深度算法随机生成路径
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

    _gravityBehavior = [[UIGravityBehavior alloc]init];

    //行为放入动画
    [_dynamicAnimator addBehavior:_dynamicItemBehavior];
    [_dynamicAnimator addBehavior:_collisionBehavior];
    [_dynamicAnimator addBehavior:_gravityBehavior];
    
}
//开始生成路径
-(void)createRoad{
//    XCount= WIDTHOFSCREEN/ROADWIDTH+1;
//    YCount= HEIGHTOFSCREEN/ROADWIDTH+1;
    XROADWIDTH = WIDTHOFSCREEN/(XCount-1);
    YROADWIDTH = HEIGHTOFSCREEN/(YCount-1);
    StartX = 1;
    StartY = 1;
    BackCount = 1;
    directionArray=[@[@[@"0",@"-1"],//上
                      @[@"-1",@"0"],//左
                      @[@"0",@"1"],//下
                      @[@"1",@"0"]]mutableCopy];//右
    
    roadArray=[NSMutableArray new];
    pathArray=[NSMutableArray new];
    
    for (int i=0; i<XCount; i++) {
        NSMutableArray *array=[NSMutableArray new];
        for (int j=0; j<YCount; j++) {
            [array addObject:@"0"];
        }
        [roadArray addObject:array];
    }
    [self BezierPath:@"line" pathStartPoint:CGPointMake(0,0) pathEndPoint:CGPointMake(0,HEIGHTOFSCREEN)];
    [self visitedRoad:StartX Y:StartY];
    [self findNextRoad:StartX Y:StartY];
    
    while (![self ifAllVisited]) {
        [self findNextRoad:StartX Y:StartY];
    }

    for (int i=0; i<pathArray.count-1; i++) {
        NSString *pathS=pathArray[i];
        NSString *pathE=pathArray[i+1];
        [self BezierPath:@"line" pathStartPoint:CGPointMake(XROADWIDTH*[[pathS substringToIndex:1] intValue], YROADWIDTH*[[pathS substringFromIndex:2] intValue]) pathEndPoint:CGPointMake(XROADWIDTH*[[pathE substringToIndex:1] intValue], YROADWIDTH*[[pathE substringFromIndex:2] intValue])];
    }
}
//记录路径
-(void)visitedRoad:(int)X Y:(int)Y{
    [pathArray addObject:[NSString stringWithFormat:@"%d,%d",X,Y]];
    [roadArray[X] replaceObjectAtIndex:Y withObject:@"1"];
}
//寻找路径
-(void)findNextRoad:(int)X Y:(int)Y{
    for (int i=0; i<directionArray.count; i++) {
        int count = arc4random() % directionArray.count;
        int x=StartX+[directionArray[count][0] intValue];
        int y=StartY+[directionArray[count][1] intValue];
        
        if (x>0&&y>=0&&x<XCount&&y<YCount&&[roadArray[x][y] isEqualToString:@"0"]) {
            StartX=x;
            StartY=y;
            BackCount=1;
            [self visitedRoad:StartX Y:StartY];
            return;
        }
    }
    [self backRoad];
}
//退回一格
-(void)backRoad{
    NSString *path=pathArray[pathArray.count-BackCount];
    BackCount+=2;
    StartX=[[path substringToIndex:1] intValue];
    StartY=[[path substringFromIndex:2] intValue];
    [pathArray addObject:[NSString stringWithFormat:@"%d,%d",StartX,StartY]];
    [self findNextRoad:StartX Y:StartY];
}
//是否遍历完全
-(BOOL)ifAllVisited{
    for (int i=1; i<XCount; i++) {
        for (int j=1; j<YCount; j++) {
            if ([roadArray[i][j] isEqualToString:@"0"]) {
                return false;
            }
        }
    }
    return true;
}
//创建路径
-(void)BezierPath:(NSString *)pathName pathStartPoint:(CGPoint)pathStartPoint pathEndPoint:(CGPoint)pathEndPoint{
    UIBezierPath *pathLine = [UIBezierPath bezierPath];
    [pathLine moveToPoint:pathStartPoint];
    [pathLine addLineToPoint:pathEndPoint];
    
    CAShapeLayer *layerLine= [CAShapeLayer layer];
    layerLine.path=pathLine.CGPath;
    layerLine.lineWidth=5;
    layerLine.strokeColor=[UIColor blackColor].CGColor;
    [self.layer addSublayer:layerLine];
    
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
