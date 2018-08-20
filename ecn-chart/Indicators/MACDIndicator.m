//
//  MACDIndicator.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/15/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "MACDIndicator.h"
#import "VerticalAxis.h"
#import "Graph.h"
#import <UIKit/UIKit.h>
#import "Tick.h"
#import "GraphicParam.h"

typedef enum ValueType : NSInteger {
    ValueTypeMACD = 0,
    ValueTypeSignal,
    ValueTypeHistogram,
    ValueTypeShortEMA,
    ValueTypeLongEMA
} ValueType;

@interface MACDIndicator() {
    NSMutableArray *hiddenParams;
}

@property (strong, nonatomic) NSMutableArray <NSDictionary *> *indicatorValues;

@end

@implementation MACDIndicator

-(id)init {
    self = [super init];
    if(self) {
    }
    return self;;
}

-(void)drawInContext:(CGContextRef)ctx {
    CGContextClearRect(ctx, self.frame);
    NSRange visibleRange = NSMakeRange(0, 0);
    CGFloat candleWidth = [self.hostedGraph.dataSource candleWidth];
    CGFloat offsetForCandles = [self.hostedGraph.dataSource offsetForCandles];
    NSInteger count = [self.hostedGraph.dataSource candleCount];
    if(count > self.indicatorValues.count) {
        self.indicatorValues = [[NSMutableArray alloc] init];
        for(int i = 0; i<count; i++) {
            NSDictionary *dict = [self valueForIndex:i];
            [self.indicatorValues addObject:dict];
        }
    }
    if(self.hostedGraph.dataSource && [self.hostedGraph.dataSource respondsToSelector:@selector(currentVisibleRange)]) {
        visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    }
    int j = 0;
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.0 green:(122.0/255.0) blue:1.0 alpha:1.0].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    //draw macd line
    for(NSInteger i = visibleRange.location; i<visibleRange.location + visibleRange.length; i++) {
        NSDictionary *dict = [self valueForIndex:i];
        float currentX = candleWidth + (2 * candleWidth * j) + offsetForCandles;
        float macdValue = [dict[@"signal"] floatValue];
        float currentY = [self yPositionForValue:macdValue];
        if(j == 0) {
            CGContextMoveToPoint(ctx, currentX, currentY);
        } else {
            CGContextAddLineToPoint(ctx, currentX, currentY);
        }
        j++;
    }
    CGContextStrokePath(ctx);
    CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor.CGColor);
    j=0;
    for(NSInteger i = visibleRange.location; i<visibleRange.location + visibleRange.length; i++) {
        NSDictionary *dict = [self valueForIndex:i];
        float currentX = candleWidth + (2 * candleWidth * j) + offsetForCandles;
        float macdValue = [dict[@"macd"] floatValue];
        float currentY = [self yPositionForValue:macdValue];
        if(j == 0) {
            CGContextMoveToPoint(ctx, currentX, currentY);
        } else {
            CGContextAddLineToPoint(ctx, currentX, currentY);
        }
        j++;
    }
    CGContextStrokePath(ctx);
    j=0;
    CGContextSetFillColorWithColor(ctx, UIColor.redColor.CGColor);
    for(NSInteger i = visibleRange.location; i<visibleRange.location + visibleRange.length; i++) {
        NSDictionary *dict = [self valueForIndex:i];
        float currentX = candleWidth + (2 * candleWidth * j) + offsetForCandles;
        float macdValue = [dict[@"histogram"] floatValue];
        float currentY = [self yPositionForValue:macdValue];
        float zeroY = [self yPositionForValue:0.0];
        if(macdValue > 0.0) {
            CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:20.0/255.0 green:(160.0/255.0) blue:66.0/255.0 alpha:1.0].CGColor);
        } else {
            CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:(255.0/255.0) green:(70.0/255.0) blue:37.0/255.0 alpha:1.0].CGColor);
        }
        float y1 = currentY > zeroY ? zeroY : currentY;
        float y2 = currentY > zeroY ? currentY : zeroY;
        CGContextAddRect(ctx, CGRectMake(currentX, y2, candleWidth, y1-y2));
        j++;
        CGContextFillPath(ctx);
    }
    
}

-(NSDictionary *)valueForIndex:(NSInteger)index {
    NSDictionary *indicatorValue;
    if(index >= self.indicatorValues.count) {
        NSNumber *shortEma, *longEma, *signal, *histogram, *macd;
        
        
            if(index < 12) {
                shortEma = [NSNumber numberWithFloat:0.0];
            } else if(index == 12) {
                float shortEmaVlaue = [self calculateSMAForIndex:index withPeriod:12];
                shortEma = [NSNumber numberWithFloat:shortEmaVlaue];
            } else {
                float shortEmaValue = [self calculateEMAForIndex:index withPeriod:12 forType:ValueTypeShortEMA];
                shortEma = [NSNumber numberWithFloat:shortEmaValue];
            }
        
        
            if(index < 26) {
                longEma = [NSNumber numberWithFloat:0.0];
            } else if(index == 26) {
                float longEmaValue = [self calculateSMAForIndex:index withPeriod:26];
                longEma = [NSNumber numberWithFloat:longEmaValue];
            } else {
                float longEmaValue = [self calculateEMAForIndex:index withPeriod:26 forType:ValueTypeLongEMA];
                longEma = [NSNumber numberWithFloat:longEmaValue];
            }
        
        float macdValue = shortEma.floatValue - longEma.floatValue;
        macd = [NSNumber numberWithFloat:macdValue];
        
            if(index < 35) {
                signal = [NSNumber numberWithFloat:0.0];
            } else if(index == 35) {
                float sma = 0.0;
                for(int i = index-34; i<index; i++) {
                    NSDictionary *indicatorValue = self.indicatorValues[i];
                    float value = [indicatorValue[@"macd"] floatValue];
                    sma += value;
                }
                sma += macdValue;
                sma = sma / 9.0;
                signal = [NSNumber numberWithFloat:sma];
            } else {
                NSDictionary *value = self.indicatorValues[index-1];
                float previousEMA = [value[@"signal"] floatValue];;
                float multiplier = 2.0 / (9.0 + 1.0);
                float signalValue = (macdValue - previousEMA) * multiplier + previousEMA;
                signal = [NSNumber numberWithFloat:signalValue];
            }
        
        
        
        float histogramValue = macdValue - signal.floatValue;
        histogram = [NSNumber numberWithFloat:histogramValue];
        
        indicatorValue = @{
                               @"shortEMA": shortEma,
                               @"longEMA": longEma,
                               @"signal": signal,
                               @"histogram": histogram,
                               @"macd": macd
                               };
    } else {
        indicatorValue = self.indicatorValues[index];
    }
    return indicatorValue;;
}

-(float)calculateSMAForIndex:(NSInteger)index withPeriod:(NSInteger)period {
    float sma = 0.0;
    for(int i = index - (period - 1); i<=index; i++) {
        Tick *tick = [self.hostedGraph.dataSource tickForIndex:i];
        sma += tick.close;
    }
    sma = sma/period;
    return sma;
}

-(float)calculateEMAForIndex:(NSInteger)index withPeriod:(NSInteger)period forType:(ValueType)type {
    NSDictionary *value = self.indicatorValues[index-1];
    NSString *emaKey;
    if(type == ValueTypeLongEMA) emaKey = @"longEMA";
    else if(type == ValueTypeShortEMA) emaKey = @"shortEMA";
    NSNumber *previousEMA = value[emaKey];
    Tick *tick = [self.hostedGraph.dataSource tickForIndex:index];
    float multiplier = 2.0 / (period + 1.0);
    float emaValue = (tick.close - previousEMA.floatValue) * multiplier + previousEMA.floatValue;
    return emaValue;
}

-(CGFloat)yPositionForValue:(float)value {
    CGFloat minValue = [self.hostedGraph minValue].floatValue;
    CGFloat maxValue = [self.hostedGraph maxValue].floatValue;
    CGFloat y1 = 20+(self.frame.size.height-40) * (1 - (value - minValue)/(maxValue - minValue));
    return y1;
}
-(NSDecimalNumber *)minValue {
    NSRange currentVisibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    NSArray <NSDictionary *> *values = [self.indicatorValues subarrayWithRange:currentVisibleRange];
    float minValue = 0.0;
    for(NSDictionary *dict in values) {
        NSNumber *macd = dict[@"macd"];
        NSNumber *signal = dict[@"signal"];
        NSNumber *histogram = dict[@"histogram"];
        if(minValue < fabsf(macd.floatValue)) minValue = fabsf(macd.floatValue);
        if(minValue < fabsf(signal.floatValue)) minValue = fabsf(signal.floatValue);
        if(minValue < fabsf(histogram.floatValue)) minValue = fabsf(histogram.floatValue);
    }
    
    
    return [[NSDecimalNumber alloc] initWithFloat:-minValue];
}

-(NSDecimalNumber *)maxValue {
    
    return [[self minValue] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1.0"]];
}

-(NSMutableArray <GraphicParam *> *) params {
    if(!hiddenParams) {
        hiddenParams = [[NSMutableArray alloc] init];
        GraphicParam *fast = [[GraphicParam alloc] init];
        fast.name = @"Fast EMA";
        fast.value = @"12";
        fast.type = GraphicParamTypeNumber;
        [hiddenParams addObject:fast];
        GraphicParam *slow = [[GraphicParam alloc] init];
        slow.name = @"Slow";
        slow.value = @"26";
        slow.type = GraphicParamTypeNumber;
        [hiddenParams addObject:slow];
        GraphicParam *sma = [[GraphicParam alloc] init];
        sma.name = @"MACD SMA";
        sma.value = @"9";
        sma.type = GraphicParamTypeNumber;
        [hiddenParams addObject:sma];
    }
    return hiddenParams;
}

-(void)setParams:(NSMutableArray<GraphicParam *> *)params {
    hiddenParams = params;
}

-(GraphicType)graphicType {
    return GraphicTypeBottom;
}

-(NSString *)name {
    return @"MACD";
}

@end
