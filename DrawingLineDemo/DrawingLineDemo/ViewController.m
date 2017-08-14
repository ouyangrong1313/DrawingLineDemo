//
//  ViewController.m
//  DrawingLineDemo
//
//  Created by 欧阳荣 on 17/8/10.
//  Copyright © 2017年 HengTaiXin. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#include <math.h>

//动态获取设备高度
#define IPHONE_HEIGHT [UIScreen mainScreen].bounds.size.height
//字体大小首页标题
#define KDregree_D 15
//动态获取设备宽度
#define IPHONE_WIDTH [UIScreen mainScreen].bounds.size.width
#define pi 3.14159265358979323846
#define degreesToRadian(x) (pi * x / 180.0)
#define radiansToDegrees(x) (180.0 * x / pi)


@interface PainterLineModel : NSObject

@property (assign,nonatomic) CGFloat lineWidth;//线宽
@property (strong,nonatomic) UIColor * lineColor;//颜色
@property (strong,nonatomic) UIBezierPath * linePath;//路径
@property (nonatomic,assign) CGPoint startPoint;//起始的点
@property (nonatomic,assign) CGPoint endPoint;//终点
@property (nonatomic,assign) BOOL isDegree;

-(instancetype)initWithPainterInfo:(CGFloat) anWidth withColor:(UIColor *) anColor withPath:(UIBezierPath *) anPath startPoint:(CGPoint ) startPoint endPoint:(CGPoint ) endPoint;

@end

@implementation PainterLineModel

-(instancetype)initWithPainterInfo:(CGFloat) anWidth withColor:(UIColor *) anColor withPath:(UIBezierPath *) anPath startPoint:(CGPoint ) startPoint endPoint:(CGPoint ) endPoint{

    self=[super init];
    if(self) {
        _lineWidth=anWidth;
        _lineColor=anColor;
        _linePath=anPath;
        _startPoint = startPoint;
        _endPoint = endPoint;
    }
    return self;

}


@end


@interface ViewController ()<CALayerDelegate>

@property(nonatomic,assign)CGMutablePathRef path;//可变路径
@property(nonatomic,strong)CALayer *rectLayer;//画图子层
@property(nonatomic,strong)CALayer *drawLayer;//画线子层

@property (assign,nonatomic) CGFloat lineWidth;
@property (strong,nonatomic) UIColor *lineColor;
@property (nonatomic,assign) CGPoint startPoint;//起始的点
@property (nonatomic,assign) CGPoint endPoint;//终点
@property (nonatomic,assign) CGPoint movePoint;//移动中的点
@property (nonatomic,assign) int nLeftOffset;
@property (nonatomic,assign) int nTopOffSet;
@property (nonatomic,assign) BOOL mouseMoved;

@property (nonatomic,copy) NSMutableArray * pathArray;

//PainterLineModel
@property (nonatomic,strong) PainterLineModel * lastPathModel;
@property (nonatomic,strong) PainterLineModel * lastSecPathModel;

@property (nonatomic,assign) CGFloat degreeUpDown;
@property (nonatomic,assign) CGPoint samePoint;
@property (nonatomic,assign) CGPoint anotherPoint;
//保存角度lab
@property (nonatomic,copy) NSMutableArray * degreeArr;
//是否是删除操作
@property (nonatomic,assign) BOOL isDelete;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.lineColor = [UIColor redColor];
    self.lineWidth = 2.0f;
    self.nLeftOffset = 0;
    self.nTopOffSet = 0;
    [self.view.layer addSublayer:self.drawLayer];
    //[self.view.layer addSublayer:self.rectLayer];
    
    UIButton * undoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    undoBtn.frame = CGRectMake(IPHONE_WIDTH - 100, 20, 90, 40);
    [undoBtn setTitle:@"撤销" forState:UIControlStateNormal];
    [undoBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [undoBtn addTarget:self action:@selector(undoBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:undoBtn];
}

#pragma mark - Event Response

-(void)undoBtnClick:(UIButton *)btn{
    _isDelete = YES;
    PainterLineModel *lstPath = [_pathArray lastObject];
    if (lstPath.isDegree) {
        UILabel * lable = [_degreeArr lastObject];
        [lable removeFromSuperview];
        lable = nil;
        [_degreeArr removeLastObject];
    }
    if (lstPath) {
        _startPoint = _endPoint ;
        [_pathArray removeLastObject];
    }
    [self.drawLayer setNeedsDisplay];
}

-(void)compareLastTwoPathinContext:(CGContextRef)ctx{

    if (_pathArray.count < 2) {
        return;
    }
    self.lastPathModel = [_pathArray lastObject];
    self.lastSecPathModel = _pathArray[_pathArray.count - 2];
    //如果上一根线画过了就不画了
    if (_lastSecPathModel.isDegree) {
        return;
    }else if (_isDelete){
        return;
    }
    
    
    //A1 A2  VS  B1 B2
    CGFloat A1B1 = distanceBetweenPoints(_lastPathModel.startPoint, _lastSecPathModel.startPoint);
    CGFloat A1B2 = distanceBetweenPoints(_lastPathModel.startPoint, _lastSecPathModel.endPoint);
    
    CGFloat A2B1 = distanceBetweenPoints(_lastPathModel.endPoint, _lastSecPathModel.startPoint);
    CGFloat A2B2 = distanceBetweenPoints(_lastPathModel.endPoint, _lastSecPathModel.endPoint);

    CGFloat angle = 0;
    
    //A1 - B1 B2
    //A2 - B1 B2
    if (A1B1 < KDregree_D || A1B2 < KDregree_D || A2B1 < KDregree_D || A2B2 < KDregree_D) {
        CGFloat x_offset = 0;
        CGFloat y_offset = 0;
        if (A1B1 < KDregree_D) {
            x_offset = self.lastPathModel.startPoint.x - self.lastSecPathModel.startPoint.x;
            y_offset = self.lastPathModel.startPoint.y - self.lastSecPathModel.startPoint.y;
            _anotherPoint = CGPointMake(self.lastPathModel.endPoint.x - x_offset, self.lastPathModel.endPoint.y - y_offset);
            angle = angleBetweenLines(_lastPathModel.startPoint, _lastPathModel.endPoint, _lastSecPathModel.startPoint, _lastSecPathModel.endPoint);

            self.lastPathModel.startPoint = self.lastSecPathModel.startPoint;
            _degreeUpDown = self.lastPathModel.startPoint.y - self.lastPathModel.endPoint.y;
            _samePoint = self.lastPathModel.startPoint;
        }else if (A1B2 < KDregree_D){
            x_offset = self.lastPathModel.startPoint.x - self.lastSecPathModel.endPoint.x;
            y_offset = self.lastPathModel.startPoint.y - self.lastSecPathModel.endPoint.y;
            _anotherPoint = CGPointMake(self.lastPathModel.endPoint.x - x_offset, self.lastPathModel.endPoint.y - y_offset);
            angle = angleBetweenLines(_lastPathModel.startPoint, _lastPathModel.endPoint, _lastSecPathModel.endPoint, _lastSecPathModel.startPoint);

            self.lastPathModel.startPoint = self.lastSecPathModel.endPoint;
            _degreeUpDown = self.lastPathModel.startPoint.y - self.lastPathModel.endPoint.y;
            _samePoint = self.lastPathModel.startPoint;
        }else if (A2B1 < KDregree_D){
            x_offset = self.lastPathModel.endPoint.x - self.lastSecPathModel.startPoint.x;
            y_offset = self.lastPathModel.endPoint.y - self.lastSecPathModel.startPoint.y;
            _anotherPoint = CGPointMake(self.lastPathModel.startPoint.x - x_offset, self.lastPathModel.startPoint.y - y_offset);
            angle = angleBetweenLines(_lastPathModel.endPoint, _lastPathModel.startPoint, _lastSecPathModel.startPoint, _lastSecPathModel.endPoint);

            self.lastPathModel.endPoint = self.lastSecPathModel.startPoint;
            _degreeUpDown = self.lastPathModel.endPoint.y - self.lastPathModel.startPoint.y;
            _samePoint = self.lastPathModel.endPoint;
        }else{
            x_offset = self.lastPathModel.endPoint.x - self.lastSecPathModel.endPoint.x;
            y_offset = self.lastPathModel.endPoint.y - self.lastSecPathModel.endPoint.y;
            _anotherPoint = CGPointMake(self.lastPathModel.startPoint.x - x_offset, self.lastPathModel.startPoint.y - y_offset);
            angle = angleBetweenLines(_lastPathModel.startPoint, _lastPathModel.endPoint, _lastSecPathModel.startPoint, _lastSecPathModel.endPoint);

            self.lastPathModel.endPoint = self.lastSecPathModel.endPoint;
            _degreeUpDown = self.lastPathModel.endPoint.y - self.lastPathModel.startPoint.y;
            _samePoint = self.lastPathModel.endPoint;
        }
        //[self.pathArray replaceObjectAtIndex:_pathArray.count - 1 withObject:_lastPathModel];
        [_pathArray removeLastObject];
        if (_path) {
            UIBezierPath * _oldPath = nil;
            _oldPath = [UIBezierPath bezierPath];//记录这条线的起始点
            [_oldPath moveToPoint:_samePoint];
            [_oldPath addLineToPoint:_anotherPoint];
            //获取当前绘制的曲线
            PainterLineModel * model = [[PainterLineModel alloc]initWithPainterInfo:_lineWidth withColor:_lineColor withPath:_oldPath startPoint:_samePoint endPoint:_anotherPoint];
            model.isDegree = YES;
            [self.pathArray addObject:model];
        }
        UILabel * lable = [self createDegreeLab];
        lable.text = [NSString stringWithFormat:@"%.0f°",angle];
        [self.degreeArr addObject:lable];
        if (_degreeUpDown > 0 ) {//下方
            lable.center = CGPointMake(_samePoint.x, _samePoint.y + 20);
        }else{
            lable.center = CGPointMake(_samePoint.x, _samePoint.y - 20);
        }
        
    }
    
    
    
}
//两个点之间的距离
CGFloat distanceBetweenPoints (CGPoint first, CGPoint second) {
    CGFloat deltaX = second.x - first.x;
    CGFloat deltaY = second.y - first.y;
    return sqrt(deltaX*deltaX + deltaY*deltaY );
};

//两个点之间的角度
CGFloat angleBetweenPoints(CGPoint first, CGPoint second) {
    CGFloat height = second.y - first.y;
    CGFloat width = first.x - second.x;
    CGFloat rads = atan(height/width);
    return radiansToDegrees(rads);
    //degs = degrees(atan((top - bottom)/(right - left)))
}

//两条线之间的角度
CGFloat angleBetweenLines(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint line2End) {
    
    CGFloat a = line1End.x - line1Start.x;
    CGFloat b = line1End.y - line1Start.y;
    CGFloat c = line2End.x - line2Start.x;
    CGFloat d = line2End.y - line2Start.y;
    
    CGFloat rads = acos(((a*c) + (b*d)) / ((sqrt(a*a + b*b)) * (sqrt(c*c + d*d))));
    
    return radiansToDegrees(rads);
    
}



#pragma mark - Touch Method

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    NSLog(@"touchesBegan");
    _isDelete = NO;
    UITouch * touch = [touches anyObject];
    _endPoint = _startPoint = [touch locationInView:self.view];
//    _startPoint.x -= _nLeftOffset;
//    _startPoint.y = _nTopOffSet;
    _endPoint = _startPoint;
    _mouseMoved = false;
    _path = CGPathCreateMutable();
    CGPathMoveToPoint(_path, nil, _startPoint.x, _startPoint.y);
    
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    NSLog(@"touchesMoved");
    
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    _mouseMoved = true;
    _movePoint = location;
//    _movePoint.x -= _nLeftOffset;
//    _movePoint.y -= _nTopOffSet;
    if (_path) {//获取当前点，并将点添加到path中
        CGPathAddLineToPoint(_path, nil, _movePoint.x, _movePoint.y);
    }
    [self.drawLayer setNeedsDisplay];
}
//在触摸结束的时候开始一个动画（图片层的移动），首先应该创建一个动画帧 动画，然后设置相应的参数 最后给要设置的涂层加上动画
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    NSLog(@"touchesEnded");
    _isDelete = NO;

    if (!_mouseMoved) {
        return;
    }
    _mouseMoved = false;
    UITouch * touch = [touches anyObject];
    _endPoint = [touch locationInView:self.view];
//    _endPoint.x -= _nLeftOffset;
//    _endPoint.y -= _nTopOffSet;
    
    if (_path) {
        UIBezierPath * _oldPath = nil;
//        _oldPath = [UIBezierPath bezierPathWithCGPath:_path];
//        CGPathRelease(_path);
        _oldPath = [UIBezierPath bezierPath];//记录这条线的起始点
        [_oldPath moveToPoint:_startPoint];
        [_oldPath addLineToPoint:_endPoint];
        
        //获取当前绘制的曲线
        PainterLineModel * model = [[PainterLineModel alloc]initWithPainterInfo:_lineWidth withColor:_lineColor withPath:_oldPath startPoint:_startPoint endPoint:_endPoint];
        [self.pathArray addObject:model];
        [self.drawLayer setNeedsDisplay];
    }
    
}

#pragma mark - CALayerDelegate

-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx{

    NSLog(@"drawLayer");
    
    if (_mouseMoved) {
        //画直线(边画边显示)
        CGContextSetLineWidth(ctx, _lineWidth);
        CGContextSetStrokeColorWithColor(ctx, [_lineColor CGColor]);
        CGMutablePathRef tmpPath = CGPathCreateMutable();
        CGPathMoveToPoint(tmpPath, nil, _startPoint.x, _startPoint.y);
        CGPathAddLineToPoint(tmpPath, nil, _movePoint.x, _movePoint.y);
        CGContextAddPath(ctx, tmpPath);
        CGPathRelease(tmpPath);
        //执行绘画
        CGContextDrawPath(ctx, kCGPathStroke);
    }else{//结束画线以后判断最后两条线的距离然后近的话就连起来并且计算角度
        [self compareLastTwoPathinContext:ctx];
    }
    
    //遍历旧的路径（下面的是画完后全部显示的）
    for (PainterLineModel * model in self.pathArray) {
        CGContextAddPath(ctx, model.linePath.CGPath);
        CGContextSetLineWidth(ctx, model.lineWidth);
        CGContextSetStrokeColorWithColor(ctx, [model.lineColor CGColor]);
        CGContextSetLineCap(ctx, kCGLineCapRound);
        CGContextDrawPath(ctx, kCGPathStroke);
    }
    
}



#pragma mark - Lazy Load

-(UILabel *)createDegreeLab{
    UILabel * lable = [[UILabel alloc]initWithFrame:CGRectMake(IPHONE_WIDTH - 60, 40, 80, 25)];
    lable.textColor = self.lineColor;
    lable.backgroundColor = [UIColor clearColor];
    lable.textAlignment = NSTextAlignmentCenter;
    lable.font = [UIFont systemFontOfSize:20];
    [self.view addSubview:lable];
    return lable;
}
//degreeArr
-(NSMutableArray *)degreeArr{
    if (!_degreeArr) {
        _degreeArr = [NSMutableArray array];
    }
    return _degreeArr;
}

-(NSMutableArray *)pathArray{
    if (!_pathArray) {
        _pathArray = [NSMutableArray array];
    }
    return _pathArray;
}

-(CALayer *)drawLayer{
    if (!_drawLayer) {
        _drawLayer = [[CALayer alloc]init];
        _drawLayer.bounds = self.view.bounds;
        _drawLayer.position = self.view.layer.position;
        _drawLayer.anchorPoint = self.view.layer.anchorPoint;
        _drawLayer.delegate = self;
    }
    return _drawLayer;
}

-(CALayer *)rectLayer{
    if (!_rectLayer) {
        _rectLayer = [[CALayer alloc]init];
        _rectLayer.backgroundColor = [[UIColor blackColor] CGColor];
        _rectLayer.bounds = CGRectMake(0, 0, 30, 30);
        _rectLayer.position = CGPointMake(100, 100);
    }
    return _rectLayer;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
