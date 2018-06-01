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
#import "TilingView.h"
#import "TimeLine.h"
#import "PriceView.h"
#import "Graphic.h"

const float cellSize = 24;
const float offset = 24;
const float maxScale = 3.0;
const float minScale = 0.5;
@interface GraphicHost() <UIScrollViewDelegate, TimeLineDataSource, PriceViewDataSource, GraphicDataSource>

@property CGFloat maxValue;
@property CGFloat minValue;
@property (strong, nonatomic) UIScrollView *scrollView;
@property CGFloat scale;
@property CGFloat candlesPerCell;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinch;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPress;
@property (strong, nonatomic) TilingView *tiling;
@property (strong, nonatomic) TimeLine *timeline;
@property (strong, nonatomic) PriceView *priceView;
@property (strong, nonatomic) Graphic *graphic;
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
    self.scrollView.bounces = NO;
    self.pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scale:)];
    [self addGestureRecognizer:self.pinch];
    self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:self.longPress];
    if(!self.scrollView.superview) {
        [self addSubview:self.scrollView];
    }
    if(!self.tiling) {
        self.tiling = [[TilingView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.tiling.dataSource = self;
        [self.scrollView addSubview:self.tiling];
    }
    
    if(!self.timeline) {
        self.timeline = [[TimeLine alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.timeline.dataSource = self;
        [self.scrollView addSubview:self.timeline];
    }
    
    if(!self.graphic) {
        self.graphic = [[Graphic alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.graphic.dataSource = self;
        self.graphic.backgroundColor = [UIColor clearColor];
        [self.scrollView addSubview:self.graphic];
    }
    
    if(!self.priceView) {
        self.priceView = [[PriceView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.priceView.datasource = self;
        [self addSubview:self.priceView];
    }
    [self.scrollView addObserver:self forKeyPath:@"contentSize" options:0 context:nil];
    minCandle = 0;
    maxCandle = 0;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.scrollView.frame = CGRectMake(0, 0, self.frame.size.width - kRightOffset, self.frame.size.height);
    int candlesPerCell = (int)floor(self.candlesPerCell);
    if(candlesPerCell == 0) candlesPerCell = 1;
    CGFloat contentWidth = (self.dataSource.numberOfItems / floor(candlesPerCell)) * self.cellSize + offset;
    [self.scrollView setContentSize:CGSizeMake(contentWidth, self.frame.size.height)];
    
    self.timeline.frame = CGRectMake(0, 0, self.frame.size.width - kRightOffset, self.frame.size.height);
    self.tiling.frame = CGRectMake(0, 0, self.frame.size.width - kRightOffset, self.frame.size.height);
    self.priceView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [self.graphic setFrame:CGRectMake(0, 0, self.frame.size.width - kRightOffset, self.frame.size.height)];
    [self.graphic setNeedsDisplay];
    
}

-(void)reloadData {
    CGFloat contentWidth = ([self candleWidth] * 2 * [self.dataSource numberOfItems] + offset);
    CGRect graphicOffset = self.graphic.frame;
    
    CGFloat offsetX = self.scrollView.contentOffset.x;
    graphicOffset.origin.x = offsetX;
    [self.tiling setFrame:graphicOffset];
    [self.graphic setFrame:graphicOffset];
    [self.timeline setFrame:graphicOffset];
    [self.graphic setNeedsDisplay];;
    [self.priceView setNeedsDisplay];
    [self.timeline setNeedsDisplay];
    [self.scrollView setContentSize:CGSizeMake(contentWidth, self.frame.size.height)];
}

-(void)reloadLastTick {
   [self reloadData];
}



-(void)scale:(UIPinchGestureRecognizer *)gesture {
    
    CGPoint scalePoint = [gesture locationInView:self];
    if(gesture.state == UIGestureRecognizerStateBegan) {
        scalingIndexCandle = [self candleIndexForPoint:scalePoint];
        
        [self.priceView drawPriceInPoint:CGPointZero];
        [self.graphic drawLinesForSelectionPoint:CGPointZero];
        
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
        NSInteger maxWidth = ((self.frame.size.width - scalePoint.x) / 24) * roundf(candlesPerCell);
        NSInteger minWidth = (scalePoint.x / 24) * roundf(candlesPerCell);
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
        [self.graphic drawLinesForSelectionPoint:selectionPoint];
        [self.priceView drawPriceInPoint:selectionPoint];
    } else {
    }
    
}

-(CGFloat)cellSize {
    return 24.0;
}

#pragma mark UIScrollViewDelegate;
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(minCandle < self.dataSource.numberOfItems * 0.3) {
        [self.delegate needAdditionalData];
    }
    minCandle = [self calculateMinCandle];
    maxCandle = [self calculateMaxCandle];
    [self.priceView drawPriceInPoint:CGPointZero];
    [self.graphic drawLinesForSelectionPoint:CGPointZero];
    
    [self reloadData];
}

-(CGFloat)offsetForCandles {
    int cellCount = self.scrollView.contentOffset.x / 24;
    CGFloat off = self.scrollView.contentOffset.x - 24 * cellCount;
    CGFloat offset = self.candleWidth - off;
    if(off < self.candleWidth/2) {
        
    }
    return offset;
}

#pragma mark TimeLineDataSource

-(NSDate *)dateAtPosition:(CGFloat)x {
    int count = x / 24;
    int candlesPerCell = (int)floor(self.candlesPerCell);
    if(candlesPerCell == 0) candlesPerCell = 1;
    NSInteger index = count * floor(candlesPerCell) - 1;
    Tick *tick = [self tickForIndex:index];
    if(!tick) return nil;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:tick.date];
    return date;;
}

-(NSInteger)countOfTwoCells {
    CGFloat offset = self.scrollView.contentOffset.x;
    int count = offset / 24;
    return count;
}

#pragma mark PracieViewDataSource
-(float)priceForY:(CGFloat)y {
    float minP = [self getMinValue];
    float maxP = [self getMaxValue];
    float H = self.frame.size.height;
    float price = (-((y-20)/(H-40)) + 1) * (maxP - minP) + minP;
    return price;
}

#pragma mark GraphicDataSource
-(CGFloat)getMaxValue {
    self.maxValue = 0;
    NSInteger candleCount = [self.dataSource numberOfItems];
    if(maxCandle > candleCount) return 0.0;
    for(int i = minCandle; i<maxCandle; i++) {
        Tick *tick = [self.dataSource candleForIndex:i];
        float max = tick.max;
        float open = tick.open;
        float close = tick.close;
        if(self.maxValue < max) self.maxValue = max;
        if(self.maxValue < open) self.maxValue = open;
        if(self.maxValue < close) self.maxValue = close;
    }
    return self.maxValue;
}

-(CGFloat)getMinValue {
    self.minValue = CGFLOAT_MAX;
    NSInteger candleCount = [self.dataSource numberOfItems];
    if(maxCandle > candleCount) return 0.0;
    for(int i = minCandle; i<maxCandle; i++) {
        Tick *tick = [self.dataSource candleForIndex:i];
        float open = tick.open;
        float close = tick.close;
        float min = tick.min;
        if(self.minValue > min) self.minValue = min;
        if(self.minValue > open) self.minValue = open;
        if(self.minValue > close) self.minValue = close;
        //NSLog(@"[MIN VALUE]: %f", self.minValue);
    }
    return self.minValue;
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
    int cellCount = self.scrollView.contentOffset.x / 24;
    minCandle = cellCount * floor(self.candlesPerCell);
    if(minCandle > self.dataSource.numberOfItems) minCandle = 0;
    return minCandle;
}

-(NSInteger)calculateMaxCandle {
    NSInteger count = [self candleCount];
    
    CGFloat maxOffset = self.scrollView.contentOffset.x + self.graphic.frame.size.width;
    int candles = maxOffset / (self.candleWidth * 2);
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
    [self.scrollView scrollRectToVisible:CGRectMake(self.scrollView.contentSize.width-1, 0, 1, self.scrollView.frame.size.width) animated:NO];
}

-(void)scrollToBeginAfterReload {
    int candlesPerCell = (int)floor(self.candlesPerCell);
    if(candlesPerCell == 0) candlesPerCell = 1;
    CGFloat scrollToX = (64 / floor(candlesPerCell)) * self.cellSize + self.scrollView.contentOffset.x;
    [self.scrollView setContentOffset:CGPointMake(scrollToX, 0) animated:NO];;
}

#pragma mark Observer
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if([object isEqual:self.scrollView] && [keyPath isEqualToString:@"contentSize"]) {
        [self.timeline setNeedsDisplay];
        [self.tiling setNeedsDisplay];
    }
}

@end
