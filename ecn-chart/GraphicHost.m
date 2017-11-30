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

const float cellSize = 24;
const float offset = 24;
const float maxScale = 3.0;
const float minScale = 0.5;
@interface GraphicHost() <UIScrollViewDelegate>

@property CGFloat maxValue;
@property CGFloat minValue;
@property (strong, nonatomic) UIScrollView *scrollView;
@property CGFloat scale;
@property CGFloat candlesPerCell;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinch;
@property (strong, nonatomic) TilingView *tiling;
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
    self.scrollView.transform = CGAffineTransformMakeScale(-1, 1);
    [self.scrollView setContentSize:CGSizeMake(self.frame.size.width * 3, self.frame.size.height)];
    self.scrollView.delegate = self;
    self.pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scale:)];
    [self addGestureRecognizer:self.pinch];
    if(!self.scrollView.superview) {
        [self addSubview:self.scrollView];
    }
    if(!self.tiling) {
        self.tiling = [[TilingView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [self.scrollView addSubview:self.tiling];
    }
    
    
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    CGFloat contentWidth = (self.dataSource.numberOfItems / self.candlesPerCell) * cellSize + offset;
    [self.scrollView setContentSize:CGSizeMake(contentWidth, self.frame.size.height)];
    if(contentWidth < self.frame.size.width) {
        contentWidth = self.frame.size.width;
        if([self.delegate respondsToSelector:@selector(needAdditionalData)]) {
            [self.delegate needAdditionalData];
        }
    }
    self.tiling.frame = CGRectMake(0, 0, contentWidth, self.frame.size.height);
    [self.tiling setNeedsDisplay];
}

-(void)reloadData {
    [self getMaxValue];
    [self getMinvalue];
    CGFloat candleWidth = [self candleWidth];
    NSInteger candleCount = [self.dataSource numberOfItems];
    for(int i = 0; i<candleCount; i++) {
        Tick *tick = [self.dataSource candleForIndex:i];
        float maxX = self.scrollView.contentOffset.x + self.frame.size.width;
        float currentX = offset - candleWidth/2 + ((candleWidth + candleWidth) * i);
        if(currentX >= maxX) {
            return;
        }
        Candle *c = [self viewAtPosition:currentX];
        if(c) {
            continue;
        }
        Candle *prevView = [self invisibleView];
        
        [self setupCandle:prevView withTick:tick forPosition:CGRectMake(currentX, 0, candleWidth, self.frame.size.height)];
    }
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

-(Candle *)viewAtPosition:(CGFloat)x {
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

#pragma mark UIScrollViewDelegate;
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self reloadData];
}

@end
