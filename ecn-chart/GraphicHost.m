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
#import "Graphic.h"

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
@property (strong, nonatomic) Graph *mainGraph;
@property (strong, nonatomic) NSMutableArray *graphs;
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
        self.graphs = [[NSMutableArray alloc] init];
    }
    return self;
}

-(instancetype)init {
    self = [super init];
    if(self) {
    }
    return self;
}

-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    CGContextClearRect(ctx, layer.frame);
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
    
    if(!self.mainGraph) {
        self.mainGraph = [[Graph alloc] init];
        self.mainGraph.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        self.mainGraph.dataSource = self;
        self.mainGraph.padding = 20.0;
        [self.layer addSublayer:self.mainGraph];
        
        CandleGraphic *candleGraphic = [[CandleGraphic alloc] init];
        candleGraphic.hostedGraph = self.mainGraph;
        [self.mainGraph.graphics addObject:candleGraphic];
        
        VerticalAxis *priceAxis = [[VerticalAxis alloc] init];
        priceAxis.hostedGraph = self.mainGraph;
        self.mainGraph.verticalAxis = priceAxis;
    }
    
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
    [self.mainGraph setNeedsDisplay];
    
}

-(void)reloadData {
    CGFloat contentWidth = ([self candleWidth] * 2 * [self.dataSource numberOfItems] + offset);
    CGRect graphicOffset = self.mainGraph.frame;
    
    CGFloat offsetX = self.scrollView.contentOffset.x;
    CGFloat mainAxisOffset = self.mainGraph.verticalAxis.axisOffset;
    CGFloat bottomOffset = self.graphs.count * 100;
    [self.mainGraph setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height-bottomOffset)];
    [self.timeline setFrame:CGRectMake(0, 0, self.frame.size.width-mainAxisOffset, self.frame.size.height)];
    self.scrollView.frame = CGRectMake(0, 0, self.frame.size.width-mainAxisOffset, self.frame.size.height);
    //}
    for(int i = 0; i<self.graphs.count; i++) {
        float yPosition = self.frame.size.height-(i+1)*100;
        float height = 100.0;
        if(i == 0) {
            yPosition -= 10;
        } else {
            height -= 10;
        }
        Graph *graph = self.graphs[i];
        graph.frame = CGRectMake(0, yPosition, self.frame.size.width, height);
        [graph reloadData];
    }
    
    graphicOffset.origin.x = offsetX;
    [self.timeline setNeedsDisplay];
    [self.scrollView setContentSize:CGSizeMake(contentWidth, self.frame.size.height)];
    
    [self.mainGraph reloadData];
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
        CGPoint offset = self.scrollView.contentOffset;
        float setOffset = minCandle * [self candleWidth] * 2;
        if(setOffset != setOffset) {
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

-(void)addIndicator:(__kindof Graphic *)indicator {
    if([indicator graphicType] == GraphicTypeMain) {
        indicator.hostedGraph = self.mainGraph;
        [self.mainGraph.graphics addObject:indicator];
    } else if([indicator graphicType] == GraphicTypeBottom) {
        Graph *graph = [[Graph alloc] init];
        graph.dataSource = self;
        graph.topLineWidth = 2.0;
        [self.graphs addObject:graph];
        
        VerticalAxis *axis = [[VerticalAxis alloc] init];
        axis.hostedGraph = graph;
        axis.majorTicksCount = 4;
        graph.verticalAxis = axis;
        
        indicator.hostedGraph = graph;
        [graph.graphics addObject:indicator];
        
        [self.layer addSublayer:graph];
    }
    [self reloadData];
}

-(void)deleteIndicator:(__kindof Graphic *)indicator {
    for(__kindof Graphic *graphic in self.mainGraph.graphics) {
        if([graphic isEqual:indicator]) {
            [indicator removeFromSuperlayer];
            [self.mainGraph.graphics removeObject:indicator];
        }
    }
    Graph *graphToDelete;
    for(Graph *graph in self.graphs) {
            if([indicator.hostedGraph isEqual:graph]) {
                graphToDelete = graph;
            }
        
    }
    if(graphToDelete) {
        [graphToDelete removeFromSuperlayer];
        [self.graphs removeObject:graphToDelete];
    }
    [self reloadData];
}

-(NSMutableArray *)indicators {
    NSMutableArray *indicators = [[NSMutableArray alloc] init];
    for(__kindof Graphic *graphic in self.mainGraph.graphics) {
        if(![graphic isKindOfClass:[CandleGraphic class]]) {
            [indicators addObject:graphic];
        }
    }
    for(Graph *graph in self.graphs) {
        for(__kindof Graphic *graphic in graph.graphics) {
            [indicators addObject:graphic];
        }
    }
    return indicators;
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
    
    CGFloat maxOffset = self.mainGraph.frame.size.width - [self offsetForCandles];
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
    CGFloat mainAxisOffset = self.mainGraph.verticalAxis.axisOffset;
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
    }
}

@end
