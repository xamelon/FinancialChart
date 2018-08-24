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
#import <mach/mach.h>
#import <mach/mach_time.h>


@interface CandleGraphic() {
    CGPoint selectionPoint;
    CGFloat maxCandleValue;
    CGFloat minCandleValue;
    UIColor *_redColor;
    UIColor *_greenColor;
    UIColor *_blackColor;
    NSRange lastUsedRangeForMaxValue;
    NSRange lastUsedRangeForMinValue;
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
    
    uint64_t startTime = mach_absolute_time();
    static mach_timebase_info_data_t    sTimebaseInfo;

    
    CGRect rect = self.frame;
    NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    NSInteger minCandle = [self.hostedGraph.dataSource minCandle];
    NSInteger maxCandle = [self.hostedGraph.dataSource maxCandle];
    CGFloat candleWidth = [self.hostedGraph.dataSource candleWidth];
    ChartType chartType =  [self.hostedGraph.dataSource chartType];
    CGContextClearRect(context, rect);
    
    int j = 0;
    CGFloat offsetForCandles = [self.hostedGraph.dataSource offsetForCandles];
    for(NSInteger i = minCandle; i<maxCandle; i++) {
        Tick *tick = [self.hostedGraph.dataSource tickForIndex:i];
        if(maxCandleValue < tick.max) maxCandleValue = tick.max;
        if(minCandleValue > tick.min) minCandleValue = tick.min;
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
    if ( sTimebaseInfo.denom == 0 ) {
        (void) mach_timebase_info(&sTimebaseInfo);
    }
    uint64_t endTime = mach_absolute_time();
    endTime = endTime - startTime;
    uint64_t elapsedNano = endTime * sTimebaseInfo.numer / sTimebaseInfo.denom;
    NSLog(@"FPS Time: %f", elapsedNano / 1000000.0);
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
    /* maxCandleValue = 0.0;
    for(NSInteger i = visibleRange.location; i<visibleRange.location + visibleRange.length; i++) {
        Tick *tick = [self.hostedGraph.dataSource tickForIndex:i];
        if(tick.max > maxCandleValue) maxCandleValue = tick.max;
    }
    return [[NSDecimalNumber alloc] initWithFloat:maxCandleValue]; */
    if(NSEqualRanges(lastUsedRangeForMaxValue, visibleRange)) {
        return [[NSDecimalNumber alloc] initWithFloat:maxCandleValue];;
    }
    
    NSArray *array = [self.hostedGraph.dataSource dataForRange:visibleRange];
    NSNumber *maxNumber = [array valueForKeyPath:@"@max.max"];
    maxCandleValue = maxNumber.floatValue;
    lastUsedRangeForMaxValue = visibleRange;
    return maxNumber;
    
}

-(NSDecimalNumber *)minValue {
    NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    /* if(visibleRange.length == 0.0) {
        return [NSDecimalNumber decimalNumberWithString:@"0.0"];
    }
    minCandleValue = HUGE_VALF;
    for(NSInteger i = visibleRange.location; i<visibleRange.location + visibleRange.length; i++) {
        Tick *tick = [self.hostedGraph.dataSource tickForIndex:i];
        if(tick.min < minCandleValue) minCandleValue = tick.min;
    }
    return [[NSDecimalNumber alloc] initWithFloat:minCandleValue]; */
    if(NSEqualRanges(lastUsedRangeForMinValue, visibleRange)) {
        return [[NSDecimalNumber alloc] initWithFloat:minCandleValue];;
    }
    NSArray *array = [self.hostedGraph.dataSource dataForRange:visibleRange];
    NSNumber *maxNumber = [array valueForKeyPath:@"@min.min"];
    //NSLog(@"Call min value: %@", maxNumber);
    minCandleValue = maxNumber.floatValue;
    lastUsedRangeForMinValue = visibleRange;
    return maxNumber;
}

@end
