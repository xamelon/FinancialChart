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

const float cellSize = 24;
const float offset = 24;
const float maxScale = 3.0;
const float minScale = 0.5;
@interface GraphicHost() <UIScrollViewDelegate, TimeLineDataSource, PriceViewDataSource>

@property CGFloat maxValue;
@property CGFloat minValue;
@property (strong, nonatomic) UIScrollView *scrollView;
@property CGFloat scale;
@property CGFloat candlesPerCell;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinch;
@property (strong, nonatomic) TilingView *tiling;
@property (strong, nonatomic) TimeLine *timeline;
@property (strong, nonatomic) PriceView *priceView;
@end

@implementation GraphicHost


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
    
    if(!self.priceView) {
        self.priceView = [[PriceView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.priceView.datasource = self;
        [self addSubview:self.priceView];
    }
    [self.scrollView addObserver:self forKeyPath:@"contentSize" options:0 context:nil];
    
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
    [self.tiling setNeedsDisplay];
    [self.timeline setNeedsDisplay];
}

-(void)reloadData {
    [self getMaxValue];
    [self getMinvalue];
    CGFloat candleWidth = [self candleWidth];
    NSInteger candleCount = [self.dataSource numberOfItems];
    for(int i = 0; i<candleCount; i++) {
        Tick *tick = [self.dataSource candleForIndex:candleCount-1-i];
        float maxX = self.scrollView.contentOffset.x + self.frame.size.width;
        float currentX = offset - candleWidth/2 + ((candleWidth + candleWidth) * i);
        if(currentX >= maxX) {
            return;
        }
        NSLog(@"Candle index: %d %f", i, currentX);
        Candle *c = [self candleAtPosition:currentX];
        if(c) {
            continue;
        }
        Candle *prevView = [self invisibleView];
        
        [self setupCandle:prevView withTick:tick forPosition:CGRectMake(currentX, 0, candleWidth, self.frame.size.height)];
    }
    
    [self.priceView setNeedsDisplay];
    [self.timeline setNeedsDisplay];
    
}


-(void)getMaxValue {
    self.maxValue = 0;
    NSInteger candleCount = [self.dataSource numberOfItems];
    for(int i = 0; i<candleCount; i++) {
        Tick *tick = [self.dataSource candleForIndex:i];
        float max = tick.max;
        float open = tick.open;
        float close = tick.close;
        if(self.maxValue < max) self.maxValue = max;
        if(self.maxValue < open) self.maxValue = open;
        if(self.maxValue < close) self.maxValue = close;
    }
}

-(void)getMinvalue {
    self.minValue = CGFLOAT_MAX;
    NSInteger candleCount = [self.dataSource numberOfItems];
    for(int i = 0; i<candleCount; i++) {
        Tick *tick = [self.dataSource candleForIndex:i];
        float open = tick.open;
        float close = tick.close;
        float min = tick.min;
        if(self.minValue > min) self.minValue = min;
        if(self.minValue > open) self.minValue = open;
        if(self.minValue > close) self.minValue = close;
    }
}

-(CGFloat)candleWidth {
    CGFloat candleSize = cellSize / self.candlesPerCell;
    candleSize -= candleSize / 2;
    return candleSize;
}

-(Candle *)candleAtPosition:(CGFloat)x {
    for(UIView *view in self.scrollView.subviews) {
        if(view.frame.origin.x == x && [view isKindOfClass:[Candle class]]) {
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
    NSLog(@"Candles per cell: %f", self.candlesPerCell);
    NSArray *subviews = [self.scrollView.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.class == %@", [Candle class]]];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self reloadData];
    [self layoutSubviews];
}

-(CGFloat)cellSize {
    return 24.0;
}

-(void)reloadLastTick {
    CGFloat candleWidth = [self candleWidth];
    NSInteger candleCount = [self.dataSource numberOfItems];
    CGFloat contentWidth = (self.dataSource.numberOfItems / self.candlesPerCell) * self.cellSize + offset;
    [self.scrollView setContentSize:CGSizeMake(contentWidth, self.frame.size.height)];
    Tick *tick = [self.dataSource candleForIndex:candleCount-1];
    NSLog(@"Reloaded tick: %@", tick);
    float maxX = self.scrollView.contentOffset.x + self.frame.size.width;
    NSInteger lastTick = [self.dataSource numberOfItems] - 1;
    float currentX = offset - candleWidth/2 + ((candleWidth + candleWidth) * lastTick);
    if(currentX >= maxX) {
        return;
    }
    Candle *c = [self candleAtPosition:currentX];
    if(c) {
        c.max = tick.max;
        c.min = tick.min;
        c.open = tick.open;
        c.close = tick.close;
        [c setNeedsDisplay];
        return;
    }
    Candle *prevView = [self invisibleView];
    CGSize contentSize = self.scrollView.contentSize;
    contentSize.width = offset;
    [self setupCandle:prevView withTick:tick forPosition:CGRectMake(currentX, 0, candleWidth, self.frame.size.height)];
}

-(void)insertTick:(Tick *)tick {
    CGSize contentSize = self.scrollView.contentSize;
    contentSize.width += 100;
    [self.scrollView setContentSize:contentSize];
}

#pragma mark UIScrollViewDelegate;
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self reloadData];
}

#pragma mark TimeLineDataSource

-(NSDate *)dateAtPosition:(CGFloat)x {
    Candle *candle = [self candleAtPosition:x];
    return candle.date;
}

#pragma mark PracieViewDataSource
-(CGFloat)priceForY:(CGFloat)y {
    float max = self.maxValue;
    float maxY = self.frame.size.height;
    return ((y * max) / maxY);
}

#pragma mark Observer
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if([object isEqual:self.scrollView] && [keyPath isEqualToString:@"contentSize"]) {
        NSLog(@"Update content size");
        [self.timeline setNeedsDisplay];
        [self.tiling setNeedsDisplay];
    }
}

@end
