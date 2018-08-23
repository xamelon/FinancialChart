//
//  Graphic.m
//  ecn-chart
//
//  Created by Stas Buldakov on 01.02.18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "CandleGraphic.h"
#import "Tick.h"
#import "QuoteHelper.h"
#import "Graph.h"


@interface CandleGraphic() {
    CGPoint selectionPoint;
    CGFloat maxCandleValue;
    CGFloat minCandleValue;
    UIColor *_redColor;
    UIColor *_greenColor;
    UIColor *_blackColor;
}

@end

@implementation CandleGraphic

-(id)init {
    self = [super init];
    if(self) {
        [self setupLayer];
    }
    
    return self;
}

-(void)setupLayer {
    _redColor = [UIColor colorWithRed:20.0/255.0 green:166.0/255.0 blue:66.0/255.0 alpha:1.0];
    _greenColor = [UIColor colorWithRed:233.0/255.0 green:77.0/255.0 blue:37.0/255.0 alpha:1.0];
    _blackColor = [UIColor blackColor];
}

-(void)drawInContext:(CGContextRef)context {
    maxCandleValue = 0.0;
    minCandleValue = HUGE_VAL;
    
    
    CGRect rect = self.frame;
    CGFloat minValue = [self.hostedGraph.dataSource minValue];
    CGFloat maxValue = [self.hostedGraph.dataSource maxValue];
    NSInteger minCandle = [self.hostedGraph.dataSource minCandle];
    NSInteger maxCandle = [self.hostedGraph.dataSource maxCandle];
    CGFloat candleWidth = [self.hostedGraph.dataSource candleWidth];
    NSInteger candleCount = [self.hostedGraph.dataSource candleCount];
    ChartType chartType =  [self.hostedGraph.dataSource chartType];
    CGContextClearRect(context, rect);
    
    int j = 0;
    CGFloat offsetForCandles = [self.hostedGraph.dataSource offsetForCandles];
    for(NSInteger i = minCandle; i<maxCandle; i++) {
        Tick *tick = [self.hostedGraph.dataSource tickForIndex:i];
        //just calculate minValue and maxValue
        //it's very good place
        if(maxCandleValue < tick.max) maxCandleValue = tick.max;
        if(minCandleValue > tick.min) minCandleValue = tick.min;
        
        float currentX = candleWidth/2 + (2 * candleWidth * j++) + offsetForCandles;
        CGFloat open = [self yPositionForValue:tick.open];
        CGFloat close = [self yPositionForValue:tick.close];
        if(tick.open > tick.close) {
            CGContextSetStrokeColorWithColor(context, _greenColor.CGColor);
            CGContextSetFillColorWithColor(context, _greenColor.CGColor);
        } else {
            CGContextSetStrokeColorWithColor(context, _redColor.CGColor);
            CGContextSetFillColorWithColor(context, _redColor.CGColor);
        }
        if(chartType == ChartTypeLine) {
            CGContextSetStrokeColorWithColor(context, _blackColor.CGColor);
        }
        CGFloat y1 = [self yPositionForValue:tick.max];
        CGFloat y2 = [self yPositionForValue:tick.min];
        if(chartType == ChartTypeLine) {
            if(i == minCandle) {
                CGContextMoveToPoint(context, currentX, open);
            }
            [self drawLine:open close:close y1:y1 y2:y2 currentX:currentX candleWidth:candleWidth context:context];
        } else if(chartType == ChartTypeCandle) {
            [self drawCandle:open close:close y1:y1 y2:y2 currentX:currentX candleWidth:candleWidth context:context];
        } else if(chartType == ChartTypeBar) {
            [self drawBar:open close:close y1:y1 y2:y2 currentX:currentX candleWidth:candleWidth context:context];
        }
    }
    CGContextStrokePath(context);
    if(!CGPointEqualToPoint(selectionPoint, CGPointZero)) {
        CGPoint points[] = {
            CGPointMake(0, selectionPoint.y),
            CGPointMake(self.frame.size.width, selectionPoint.y)
        };
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:(21.0/255.0) green:(126.0/255.0) blue:(251.0/255.0) alpha:1.0].CGColor);
        CGContextAddLines(context, points, 2);
        CGPoint points1[] = {
            CGPointMake(selectionPoint.x, 0),
            CGPointMake(selectionPoint.x, self.frame.size.height)
        };
        CGContextAddLines(context, points1, 2);
        CGContextStrokePath(context);
        if(chartType != ChartTypeLine) {
            Tick *selectedTick = [self.hostedGraph.dataSource candleForPoint:selectionPoint];
            NSString *text = [NSString stringWithFormat:@"Open: %@ Close: %@\nHigh: %@ Low: %@",
                              [QuoteHelper decimalNumberFromDouble:selectedTick.open],
                              [QuoteHelper decimalNumberFromDouble:selectedTick.close],
                              [QuoteHelper decimalNumberFromDouble:selectedTick.max],
                              [QuoteHelper decimalNumberFromDouble:selectedTick.min]];
            CGSize size = [text sizeWithAttributes:@{
                                                     NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:10.0],
                                                     }];
            CGContextSetFillColorWithColor(context, [UIColor colorWithRed:(21.0/255.0) green:(126.0/255.0) blue:(251.0/255.0) alpha:1.0].CGColor);
            CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:(21.0/255.0) green:(126.0/255.0) blue:(251.0/255.0) alpha:1.0].CGColor);
            CGContextFillRect(context, CGRectMake(0, 0, size.width + 10, size.height + 5));
            UIGraphicsPushContext(context);
            [text drawAtPoint:CGPointMake(2.5, 2.5)
               withAttributes:@{
                                NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:8.0],
                                NSForegroundColorAttributeName: [UIColor whiteColor]
                                }];
            UIGraphicsPopContext();
        }
    }
    CGContextStrokePath(context);
}

-(void)drawLinesForSelectionPoint:(CGPoint)point {
    selectionPoint = point;
    [self setNeedsDisplay];
}

-(void)drawCandle:(CGFloat)open close:(CGFloat)close y1:(CGFloat)y1 y2:(CGFloat)y2 currentX:(CGFloat)currentX candleWidth:(CGFloat)candleWidth context:(CGContextRef)context  {
    float openCloseHeight = fabs(open-close);
    if(openCloseHeight <= 0) openCloseHeight = 1;
    
    CGRect rect1 = CGRectMake(currentX, MIN(open, close), candleWidth, openCloseHeight);
    CGContextFillRect(context, rect1);
    CGContextMoveToPoint(context, currentX + candleWidth/2, y1);
    CGContextAddLineToPoint(context, currentX + candleWidth/2, y2);
    CGContextStrokePath(context);
}

-(void)drawBar:(CGFloat)open close:(CGFloat)close y1:(CGFloat)y1 y2:(CGFloat)y2 currentX:(CGFloat)currentX candleWidth:(CGFloat)candleWidth context:(CGContextRef)context {
    CGContextSetLineWidth(context, 1);
    CGContextMoveToPoint(context, currentX - candleWidth/2, open);
    CGContextAddLineToPoint(context, currentX + candleWidth/2, open);
    CGContextMoveToPoint(context, currentX + candleWidth/2, y1);
    CGContextAddLineToPoint(context, currentX + candleWidth/2, y2);
    CGContextMoveToPoint(context, currentX + candleWidth/2, close);
    CGContextAddLineToPoint(context, currentX + candleWidth + candleWidth/2, close);
    CGContextStrokePath(context);
}

-(void)drawLine:(CGFloat)open close:(CGFloat)close y1:(CGFloat)y1 y2:(CGFloat)y2 currentX:(CGFloat)currentX candleWidth:(CGFloat)candleWidth context:(CGContextRef)context {
    CGContextAddLineToPoint(context, currentX+candleWidth/2, close);
}

#pragma mark Graphic overrides
-(NSDecimalNumber *)maxValue {
    NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    float maxValue = 0.0;
    for(NSInteger i = visibleRange.location; i<visibleRange.location + visibleRange.length; i++) {
        Tick *tick = [self.hostedGraph.dataSource tickForIndex:i];
        if(tick.max > maxValue) maxValue = tick.max;
    }
    return [[NSDecimalNumber alloc] initWithFloat:maxValue];
    
}

-(NSDecimalNumber *)minValue {
    NSRange range = [self.hostedGraph.dataSource currentVisibleRange];
    if(range.length == 0.0) {
        return [NSDecimalNumber decimalNumberWithString:@"0.0"];
    }
    float minValue = HUGE_VALF;
    for(NSInteger i = range.location; i<range.location + range.length; i++) {
        Tick *tick = [self.hostedGraph.dataSource tickForIndex:i];
        if(tick.min < minValue) minValue = tick.min;
    }
    return [[NSDecimalNumber alloc] initWithFloat:minValue];
}

@end
