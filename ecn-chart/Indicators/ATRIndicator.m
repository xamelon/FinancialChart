//
//  ATRIndicator.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/20/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "ATRIndicator.h"
#import "Graph.h"
#import "Tick.h"
#import <UIKit/UIKit.h>
#import "GraphicParam.h"

@interface ATRIndicator() {
    NSMutableArray *hiddenParams;
}

@property (strong, nonatomic) NSMutableArray <NSDictionary *> *indicatorValues;

@end

@implementation ATRIndicator



-(void)reloadData {
    self.indicatorValues = [NSMutableArray new];
    NSInteger candleCount = [self.hostedGraph.dataSource candleCount];
    if(candleCount >= self.indicatorValues.count) {
        self.indicatorValues = [[NSMutableArray alloc] init];
        for(int i = 0; i<candleCount; i++) {
            NSDictionary *value = [self valueForIndex:i];
            [self.indicatorValues addObject:value];
        }
    }
    [self setNeedsDisplay];
}

-(void)drawInContext:(CGContextRef)ctx {
    NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    NSInteger candleCount = [self.hostedGraph.dataSource candleCount];
    CGFloat candleWidth = [self.hostedGraph.dataSource candleWidth];
    CGFloat offsetForCandles = [self.hostedGraph.dataSource offsetForCandles];
    CGContextBeginPath(ctx);
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    int j = 0;
    for(NSInteger i = visibleRange.location; i<visibleRange.location+visibleRange.length; i++) {
        NSDictionary *value = self.indicatorValues[i];
        NSNumber *atrValue = value[@"atr"];
        CGFloat currentX = candleWidth + (2 * candleWidth * j) + offsetForCandles;
        CGFloat currentY = [self yPositionForValue:atrValue.floatValue];
        if(j==0) {
            CGContextMoveToPoint(ctx, currentX, currentY);
        } else {
            CGContextAddLineToPoint(ctx, currentX, currentY);
        }
        j++;
    }
    
    CGContextStrokePath(ctx);
    
}

-(NSDictionary *)valueForIndex:(NSInteger)index {
    GraphicParam *period = hiddenParams[0];
    NSInteger periodValue = period.value.integerValue;
    NSDictionary *value;
    if(index >= self.indicatorValues.count) {
        NSNumber *tr = [NSNumber numberWithFloat:0.0];
        NSNumber *atr = [NSNumber numberWithFloat:0.0];
        if(index == 0) {
            Tick *tick = [self.hostedGraph.dataSource tickForIndex:index];
            float trValue = tick.max - tick.close;
            tr = [NSNumber numberWithFloat:trValue];
        }
        if(index > 0) {
            Tick *tick = [self.hostedGraph.dataSource tickForIndex:index];
            Tick *previousTick = [self.hostedGraph.dataSource tickForIndex:index-1];
            float trValue = [self calculateTRWithTick:tick previousTick:previousTick];
            tr = [NSNumber numberWithFloat:trValue];
        }
        if(index == periodValue) {
            float atrValue = 0.0;
            for(int i = 0; i<index-1; i++) {
                NSDictionary *dict = self.indicatorValues[i];
                NSNumber *atr = dict[@"tr"];
                atrValue += atr.floatValue;
            }
            atrValue += tr.floatValue;
            atrValue = atrValue / periodValue;
            atr = [[NSNumber alloc] initWithFloat:atrValue];
        } else if(index > periodValue) {
            NSDictionary *previousValue = self.indicatorValues[index-1];
            NSNumber *previousAtr = previousValue[@"atr"];
            float atrValue = previousAtr.floatValue * (periodValue-1);
            atrValue += tr.floatValue;
            atrValue = atrValue / periodValue;
            atr = [NSNumber numberWithFloat:atrValue];
        }
        value = @{
                  @"tr": tr,
                  @"atr": atr
                  };
    } else {
        value = self.indicatorValues[index];
    }
    
    return value;
}


-(float)calculateTRWithTick:(Tick *)tick previousTick:(Tick *)previousTick {
    float tr = 0.0;
    float highMinusLow = tick.max - tick.min;
    float lastCloseMinusHigh = fabsf(previousTick.close - tick.max);
    float lastCloseMinusLow = fabsf(previousTick.close - tick.min);
    tr = MAX(highMinusLow, lastCloseMinusLow);
    tr = MAX(tr, lastCloseMinusHigh);
    return tr;
}

-(NSDecimalNumber *)minValue {
    NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    if(visibleRange.location > self.indicatorValues.count || visibleRange.location + visibleRange.length > self.indicatorValues.count) {
        return [NSDecimalNumber decimalNumberWithString:@"0.0"];
    }
    NSArray *array = [self.indicatorValues subarrayWithRange:visibleRange];
    NSArray *atrValues = [array valueForKey:@"atr"];
    NSNumber *maxNumber = [atrValues valueForKeyPath:@"@min.self"];
    return maxNumber;
}

-(NSDecimalNumber *)maxValue {
    NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    if(visibleRange.location > self.indicatorValues.count || visibleRange.location + visibleRange.length > self.indicatorValues.count) {
        return [NSDecimalNumber decimalNumberWithString:@"0.0"];
    }
    NSArray *array = [self.indicatorValues subarrayWithRange:visibleRange];
    NSArray *atrValues = [array valueForKey:@"atr"];
    NSNumber *maxNumber = [atrValues valueForKeyPath:@"@max.self"];
    return maxNumber;
}

-(NSMutableArray <GraphicParam *> *)params {
    if(!hiddenParams) {
        hiddenParams = [[NSMutableArray alloc] init];
        GraphicParam *period = [[GraphicParam alloc] init];
        period.name = NSLocalizedString(@"Period", nil);
        period.value = @"14";
        period.type = GraphicParamTypeNumber;
        [hiddenParams addObject:period];
    }
    
    return hiddenParams;
}

-(void)setParams:(NSMutableArray<GraphicParam *> *)params {
    hiddenParams = params;
}

-(NSString *)name {
    return @"ATR";
}

-(GraphicType)graphicType {
    return GraphicTypeBottom;
}

-(NSString *)description {
    GraphicParam *period = hiddenParams[0];
    NSString *description = [NSString stringWithFormat:@"ATR(%@)", period.value];
    return description;
}

@end
