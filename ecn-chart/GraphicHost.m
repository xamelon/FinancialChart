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
@property (strong, nonatomic) TilingView *tiling;
@property (strong, nonatomic) TimeLine *timeline;
@property (strong, nonatomic) PriceView *priceView;
@property (strong, nonatomic) Graphic *graphic;
@end

@implementation GraphicHost {
    NSInteger minCandle;
    NSInteger maxCandle;
    
}


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
    if(!self.scrollView.superview) {
        [self addSubview:self.scrollView];
    }
    if(!self.tiling) {
        self.tiling = [[TilingView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
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
    maxCandle = (self.frame.size.width - [self candleWidth]/2) / (2 * [self candleWidth]);
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    CGFloat contentWidth = (self.dataSource.numberOfItems / self.candlesPerCell) * self.cellSize + offset;
    [self.scrollView setContentSize:CGSizeMake(contentWidth, self.frame.size.height)];
    if(contentWidth < self.frame.size.width) {
        contentWidth = self.frame.size.width;
        if([self.delegate respondsToSelector:@selector(needAdditionalData)]) {
            [self.delegate needAdditionalData];
        }
    }
    self.timeline.frame = CGRectMake(0, 0, contentWidth, self.frame.size.height);
    self.tiling.frame = CGRectMake(0, 0, contentWidth, self.frame.size.height);
    self.priceView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [self.graphic setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    [self.tiling setNeedsDisplay];
    [self.timeline setNeedsDisplay];
    [self.graphic setNeedsDisplay];
    
}

-(void)reloadData {
    CGFloat contentWidth = (self.dataSource.numberOfItems / self.candlesPerCell) * self.cellSize + offset;
    [self.scrollView setContentSize:CGSizeMake(contentWidth, self.frame.size.height)];
    self.timeline.frame = CGRectMake(0, 0, contentWidth, self.frame.size.height);
    self.tiling.frame = CGRectMake(0, 0, contentWidth, self.frame.size.height);
    [self.graphic setNeedsDisplay];;
    [self.priceView setNeedsDisplay];
    [self.timeline setNeedsDisplay];
    
}

-(void)reloadLastTick {
    [self reloadData];
    [self.scrollView scrollRectToVisible:CGRectMake(self.scrollView.contentSize.width-100, 0, 100, 100) animated:YES];
}

-(Candle *)candleAtPosition:(CGFloat)x {
    CGPoint point = CGPointMake(x, 1);
    for(UIView *view in self.scrollView.subviews) {
        if([view pointInside:point withEvent:nil] && [view isKindOfClass:[Candle class]]) {
            return (Candle *)view;
        }
    }
    return nil;
}

-(Candle *)invisibleView {
    CGRect frame = CGRectMake(self.scrollView.contentOffset.x, self.scrollView.contentOffset.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    for(UIView *view in self.scrollView.subviews) {
        if(!CGRectIntersectsRect(frame, view.frame) && [view isKindOfClass:[Candle class]]) {
            return (Candle *)view;
        }
    }
    return nil;
}

-(void)setupCandle:(Candle *)prevCandle withTick:(Tick *)tick forPosition:(CGRect)position {
    if(!prevCandle) {
        Candle *candle = [[Candle alloc] initWithMax:self.maxValue min:self.minValue candle:tick frame:position];
        [self.scrollView addSubview:candle];
    } else {
        prevCandle.frame = position;
        prevCandle.max = tick.max;
        prevCandle.min = tick.min;
        prevCandle.open = tick.open;
        prevCandle.close = tick.close;
        prevCandle.date = [NSDate dateWithTimeIntervalSince1970:tick.date];
        [prevCandle setNeedsDisplay];
    }
}

-(void)scale:(UIPinchGestureRecognizer *)gesture {
    if(gesture.velocity > 0) {
        if(self.candlesPerCell > 1) {
            self.candlesPerCell -= 1;
        }
    } else {
        if(self.candlesPerCell < 12) {
            self.candlesPerCell += 1;
        }
    }
    minCandle = [self minCandle];
    maxCandle = [self maxCandle];
    NSLog(@"Candles per cell: %f", self.candlesPerCell);
    NSArray *subviews = [self.scrollView.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.class == %@", [Candle class]]];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self reloadData];
    [self layoutSubviews];
}

-(CGFloat)cellSize {
    return 24.0;
}

#pragma mark UIScrollViewDelegate;
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat offsetX = self.scrollView.contentOffset.x;
    minCandle = (offsetX - [self candleWidth]/2) / (2 * [self candleWidth]);
    NSInteger count = [self candleCount];
    CGFloat maxOffset = self.scrollView.contentOffset.x + self.frame.size.width;
    maxCandle = (maxOffset - [self candleWidth]/2) / (2 * [self candleWidth]);
    if(maxCandle > count) {
        maxCandle = count;
    }
    CGRect graphicOffset = self.graphic.frame;
    graphicOffset.origin.x = offsetX;
    [self.graphic setFrame:graphicOffset];
    [self reloadData];
    NSLog(@"Current candle: %d", minCandle);
}

-(CGFloat)offsetForCandles {
    int cellCount = self.scrollView.contentOffset.x / 24;
    CGFloat off = self.scrollView.contentOffset.x - 24 * cellCount;
    CGFloat offset = self.candleWidth - off;
    NSLog(@"Cell count: %f", off);
    NSLog(@"Offset: %f", offset);
    return offset;
}

#pragma mark TimeLineDataSource

-(NSDate *)dateAtPosition:(CGFloat)x {
    int i = (x - [self candleWidth] / 2 ) / (2 * [self candleWidth]);
    if(self.candleCount == 0) return nil;
    Tick *tick = [self tickForIndex:i];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:tick.date];
    return date;;
}

#pragma mark PracieViewDataSource
-(CGFloat)priceForY:(CGFloat)y {
    float minP = [self getMinValue];
    float maxP = [self getMaxValue];
    float H = self.frame.size.height;
    float price = (-((y-20)/(H-40)) + 1) * (maxP - minP) + minP;
    NSLog(@"EQUAL: %d", y == (20+(H-40) * (1 - (price - minP)/(maxP - minP))));
    return price;
}

#pragma mark GraphicDataSource
-(CGFloat)getMaxValue {
    self.maxValue = 0;
    NSInteger candleCount = [self.dataSource numberOfItems];
    if(maxCandle > candleCount) return 1.0;
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

-(Tick *)tickForIndex:(NSInteger)i {
    NSInteger count = [self.dataSource numberOfItems];
    if(count == 0 || i > count) return nil;
    return [self.dataSource candleForIndex:i];
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
    CGFloat candleSize = cellSize / self.candlesPerCell;
    candleSize -= candleSize / 2;
    return candleSize;
}


#pragma mark Observer
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if([object isEqual:self.scrollView] && [keyPath isEqualToString:@"contentSize"]) {
        NSLog(@"Update content size");
        self.timeline.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        [self.timeline setNeedsDisplay];
        [self.tiling setNeedsDisplay];
    }
}

@end
