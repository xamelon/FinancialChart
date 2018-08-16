//
//  GraphicHost.m
//  trading-chart
//
//  Created by Stas Buldakov on 03.11.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import "GraphicHost.h"
#import "Candle.h"
#import "Tick.h"
#import "TimeLine.h"
#import "PriceView.h"
#import "Graph.h"
#import "CandleGraphic.h"
#import "VerticalAxis.h"
#import "MACDIndicator.h"
#import "RSIIndicator.h"

static const float offset = 0.0;
const float maxScale = 3.0;
const float minScale = 0.5;
@interface GraphicHost() <UIScrollViewDelegate, TimeLineDataSource, PriceViewDataSource, GraphDataSource>

@property CGFloat maxValue;
@property CGFloat minValue;
@property (strong, nonatomic) UIScrollView *scrollView;
@property CGFloat scale;
@property CGFloat candlesPerCell;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinch;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPress;
@property (strong, nonatomic) TimeLine *timeline;
@property (strong, nonatomic) Graph *graph;
@property (strong, nonatomic) Graph *indicatorGraph;
@end

@implementation GraphicHost {
    NSInteger minCandle;
    NSInteger maxCandle;
    NSInteger scalingIndexCandle;
}

const float kRightOffset = 62;


-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self setupView];
    }
    return self;
}

-(instancetype)init {
    self = [super init];
    if(self) {
    }
    return self;
}


-(void)setupView {
    self.scale = 1.0;
    self.candlesPerCell = 4;
    if(!self.scrollView) {
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    }
    [self.scrollView setContentSize:CGSizeMake(self.frame.size.width * 3, self.frame.size.height)];
    self.scrollView.delegate = self;
    self.scrollView.bounces = YES;
    self.pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scale:)];
    [self addGestureRecognizer:self.pinch];
    self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:self.longPress];
    if(!self.scrollView.superview) {
        [self addSubview:self.scrollView];
    }
    
    if(!self.timeline) {
        self.timeline = [[TimeLine alloc] init];
        self.timeline.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        self.timeline.dataSource = self;
        [self.layer addSublayer:self.timeline];
        
    }
    
    if(!self.graph) {
        self.graph = [[Graph alloc] init];
        self.graph.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        self.graph.dataSource = self;
        [self.layer addSublayer:self.graph];
        
        CandleGraphic *candleGraphic = [[CandleGraphic alloc] init];
        candleGraphic.hostedGraph = self.graph;
        [self.graph.graphics addObject:candleGraphic];
        
        VerticalAxis *priceAxis = [[VerticalAxis alloc] init];
        priceAxis.hostedGraph = self.graph;
        self.graph.verticalAxis = priceAxis;
        
        
    }
    
    self.indicatorGraph = [[Graph alloc] init];
    self.indicatorGraph.frame = CGRectMake(0, self.frame.size.height-100, self.frame.size.width, 100);
    self.indicatorGraph.dataSource = self;
    self.indicatorGraph.topLineWidth = 2.0;
    [self.layer addSublayer:self.indicatorGraph];
    
    RSIIndicator *rsi = [[RSIIndicator alloc] init];
    rsi.hostedGraph = self.indicatorGraph;
    [self.indicatorGraph.graphics addObject:rsi];
    
    VerticalAxis *indicatorAxis = [[VerticalAxis alloc] init];
    indicatorAxis.majorTicksCount = 5;
    indicatorAxis.hostedGraph = self.indicatorGraph;
    self.indicatorGraph.verticalAxis = indicatorAxis;
    
    
    
    
    
    [self bringSubviewToFront:self.scrollView];
    minCandle = 0;
    maxCandle = 0;
    [self addObserver:self forKeyPath:@"bounds" options:0 context:nil];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    int candlesPerCell = (int)floor(self.candlesPerCell);
    if(candlesPerCell == 0) candlesPerCell = 1;
    
    NSInteger tt = [self.dataSource numberOfItems];
    CGFloat contentWidth = tt * self.cellSize*2 + offset;
    [self.scrollView setContentSize:CGSizeMake(contentWidth, self.frame.size.height)];
    [self.graph setNeedsDisplay];
    
}

-(void)reloadData {
    CGFloat contentWidth = ([self candleWidth] * 2 * [self.dataSource numberOfItems] + offset);
    CGRect graphicOffset = self.graph.frame;
    
    CGFloat offsetX = self.scrollView.contentOffset.x;
    CGFloat mainAxisOffset = self.graph.verticalAxis.axisOffset;
    [self.graph setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height-100)];
    [self.indicatorGraph setFrame:CGRectMake(0, self.frame.size.height-100, self.frame.size.width, 100)];
    [self.timeline setFrame:CGRectMake(0, 0, self.frame.size.width-mainAxisOffset, self.frame.size.height)];
    
    self.scrollView.frame = CGRectMake(0, 0, self.frame.size.width-mainAxisOffset, self.frame.size.height);
    //}
    
    NSLog(@"Scroll view frame size: %f", self.scrollView.frame.size.width);
    graphicOffset.origin.x = offsetX;
    [self.timeline setNeedsDisplay];
    [self.scrollView setContentSize:CGSizeMake(contentWidth, self.frame.size.height)];
    
    [self.graph reloadData];
    [self.indicatorGraph reloadData];
}

-(void)reloadLastTick {
   [self reloadData];
}

-(void)scale:(UIPinchGestureRecognizer *)gesture {
    
    CGPoint scalePoint = [gesture locationInView:self];
    if(gesture.state == UIGestureRecognizerStateBegan) {
        scalingIndexCandle = [self candleIndexForPoint:scalePoint];
        
        
    } else if(gesture.state == UIGestureRecognizerStateChanged) {
        
        int startScale = (int)floor(self.candlesPerCell);
        if(gesture.velocity > 0) {
            if(self.candlesPerCell > 1) {
                self.candlesPerCell -= 0.2;
            } else {
                return;
            }
        } else {
            if(self.candlesPerCell < 8) {
               self.candlesPerCell += 0.2;
            } else {
                return;
            }
        }
        int candlesPerCell1 = (int)floor(self.candlesPerCell);
        if(candlesPerCell1 == 0) self.candlesPerCell = 1;
        int endScale = (int)floor(self.candlesPerCell);
        if(endScale == startScale) {
            return;
        }
        Tick *tick = [self.dataSource candleForIndex:scalingIndexCandle];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:tick.date];
        NSLog(@"Tick date: %@", date);
        int candlesPerCell = (int)floor(self.candlesPerCell);
        if(candlesPerCell == 0) candlesPerCell = 1;
        NSInteger maxWidth = ((self.frame.size.width - scalePoint.x) / cellSize) * roundf(candlesPerCell);
        NSInteger minWidth = (scalePoint.x / cellSize) * roundf(candlesPerCell);
        minCandle = scalingIndexCandle - minWidth;
        maxCandle = scalingIndexCandle + maxWidth;
        int candles = self.frame.size.width / ([self candleWidth] * 2);
        if(maxCandle - minCandle -1 < candles) {
            minCandle = maxCandle - candles;
        }
        if(minCandle <= 0) {
            minCandle = 0;
        }
        if(maxCandle >= [self.dataSource numberOfItems]) maxCandle = [self.dataSource numberOfItems];
        NSLog(@"Scale candles: %d %d %d", scalingIndexCandle, minCandle, maxCandle);
        CGPoint offset = self.scrollView.contentOffset;
        float setOffset = minCandle * [self candleWidth] * 2;
        if(setOffset != setOffset) {
            NSLog(@"WTF");
        } else {
            offset.x = minCandle * [self candleWidth] * 2;
        }
        
        self.scrollView.contentOffset = offset;
        
        [self reloadData];

    } else if(gesture.state == UIGestureRecognizerStateEnded) {
        
    }
}

-(void)longPress:(UILongPressGestureRecognizer *)gesture {
    CGPoint selectionPoint = [gesture locationInView:self];
    selectionPoint = [self roundToNearCandlePoint:selectionPoint];
    NSInteger candleIndex = [self candleIndexForPoint:selectionPoint];
    Tick *tick = [self.dataSource candleForIndex:candleIndex];;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:tick.date];
    NSLog(@"Date: %@", date);
    if(gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        
    } else {
    }
    if(self.delegate && [self.delegate respondsToSelector:@selector(longTapAtGraphicWithState:)]) {
        [self.delegate longTapAtGraphicWithState:gesture.state];
    }
}

-(CGFloat)cellSize {
    return cellSize;
}

#pragma mark UIScrollViewDelegate;
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(minCandle < self.dataSource.numberOfItems * 0.3) {
        [self.delegate needAdditionalData];
    }
    minCandle = [self calculateMinCandle];
    maxCandle = [self calculateMaxCandle];
    
    [self reloadData];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(graphicDidScroll)]) {
        [self.delegate graphicDidScroll];
    }
}

-(CGFloat)offsetForCandles {
    int cellCount = self.scrollView.contentOffset.x / cellSize;
    CGFloat off = self.scrollView.contentOffset.x - cellSize * cellCount;
    CGFloat offset = self.candleWidth - off;
    if(off < self.candleWidth/2) {
        
    }
    return offset;
}

#pragma mark TimeLineDataSource

-(NSDate *)dateAtPosition:(CGFloat)x {
    int count = x / cellSize;
    int candlesPerCell = (int)floor(self.candlesPerCell);
    if(candlesPerCell == 0) candlesPerCell = 1;
    NSInteger index = count * floor(candlesPerCell) - 1;
    Tick *tick = [self tickForIndex:index];
    if(!tick) {
        return nil;
    }
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:tick.date];
    return date;;
}

-(NSInteger)countOfTwoCells {
    CGFloat offset = self.scrollView.contentOffset.x;
    int count = offset / cellSize;
    return count;
}

-(NSDateFormatter *)dateFormatter {
    NSDateFormatter *df;
    if(self.dataSource && [self.dataSource respondsToSelector:@selector(dateFormatter)]) {
        df = [self.dataSource dateFormatter];
    }
    if(!df) {
        df = [[NSDateFormatter alloc] init];
        df.timeStyle = NSDateFormatterShortStyle;
    }
    
    return df;
    
    
}

#pragma mark PracieViewDataSource
-(float)priceForY:(CGFloat)y {
    float minP = [self minValue];
    float maxP = [self maxValue];
    float H = self.frame.size.height;
    float price = (-((y-20)/(H-40)) + 1) * (maxP - minP) + minP;
    return price;
}

#pragma mark GraphicDataSource
-(CGFloat)maxValue {
    float maxValue = 0;
    NSInteger candleCount = [self.dataSource numberOfItems];
    if(maxCandle > candleCount) return 0.0;
    for(int i = minCandle; i<maxCandle; i++) {
        Tick *tick = [self.dataSource candleForIndex:i];
        float max = tick.max;
        float open = tick.open;
        float close = tick.close;
        if(maxValue < max) maxValue = max;
    }
    
    return maxValue;
}

-(CGFloat)minValue {
    float minValue = HUGE_VALF;
    NSInteger candleCount = [self.dataSource numberOfItems];
    if(maxCandle > candleCount) return 0.0;
    for(int i = minCandle; i<maxCandle; i++) {
        Tick *tick = [self tickForIndex:i];
        float open = tick.open;
        float close = tick.close;
        float min = tick.min;
        if(minValue > min) minValue = min;
        //NSLog(@"[MIN VALUE]: %f", self.minValue);
    }
    
    return minValue;
}

-(Tick *)candleForPoint:(CGPoint)point {
    NSInteger index = [self candleIndexForPoint:point];
    
    return [self.dataSource candleForIndex:index];
}

-(Tick *)tickForIndex:(NSInteger)i {

    return [self.dataSource candleForIndex:i];
}

-(CGPoint)roundToNearCandlePoint:(CGPoint)point {
    int candles = (point.x - self.candleWidth) / (self.candleWidth * 2);
    CGFloat currentX = self.offsetForCandles + (self.candleWidth * 2) * candles + self.candleWidth;
    point.x = currentX;
    
    return point;
}

-(NSInteger)candleIndexForPoint:(CGPoint)point {
    int candles = point.x / (self.candleWidth * 2);
    
    return minCandle + candles;
}

-(NSInteger)calculateMinCandle {
    int candleCount = (self.scrollView.contentOffset.x + [self offsetForCandles]) / ([self candleWidth] * 2);
    CGFloat allCandlesWidth = candleCount * self.candleWidth * 2;
    minCandle = candleCount+1;
    
    if(minCandle > self.dataSource.numberOfItems) minCandle = 0;
    return minCandle;
}

-(NSInteger)calculateMaxCandle {
    NSInteger count = [self candleCount];
    
    CGFloat maxOffset = self.graph.frame.size.width - [self offsetForCandles];
    int candles = floorf(maxOffset / (self.candleWidth * 2));
    maxCandle = minCandle + candles;
    if(maxCandle > count) {
        maxCandle = count;
    }
    return maxCandle;
}

-(NSInteger)minCandle {
    return minCandle;
}

-(NSInteger)maxCandle {
    return maxCandle;
}

-(NSInteger)candleCount {
    return [self.dataSource numberOfItems];
}

-(CGFloat)candleWidth {
    int candlesPerCell = (int)floor(self.candlesPerCell);
    if(candlesPerCell == 0) candlesPerCell = 1;
    CGFloat candleSize = cellSize / floor(self.candlesPerCell);
    candleSize -= candleSize / 2;
    
    return candleSize;
}

-(ChartType)chartType {
    return self.graphicType;
}

-(void)scrollToEnd {
    [self reloadData];
    NSLog(@"Scroll view frame size: %f", self.scrollView.frame.size.width);
    CGFloat mainAxisOffset = self.graph.verticalAxis.axisOffset;
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentSize.width-self.scrollView.frame.size.width, 0)];
    
}

-(void)scrollToBeginAfterReload {
    int candlesPerCell = (int)floor(self.candlesPerCell);
    if(candlesPerCell == 0) candlesPerCell = 1;
    CGFloat scrollToX = (64 * self.candleWidth * 2) + self.scrollView.contentOffset.x;
    [self.scrollView setContentOffset:CGPointMake(scrollToX, 0) animated:NO];;
}

-(NSNumberFormatter *)numberFormatter {
    if(self.dataSource && [self.dataSource respondsToSelector:@selector(numberFormatter)]) {
        return [self.dataSource numberFormatter];
    }
    return [[NSNumberFormatter alloc] init];
}

#pragma mark IndicatorDataSource
-(NSRange)currentVisibleRange {
    NSInteger minCandle = [self minCandle];
    NSInteger length = [self maxCandle] - minCandle;
    return NSMakeRange(minCandle, length);
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if([object isEqual:self] && [keyPath isEqualToString:@"bounds"]) {
        NSLog(@"Change size of view");
    }
}

@end
