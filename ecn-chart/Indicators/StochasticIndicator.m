//
//  StochasticIndicator.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/17/18.
//  Copyright © 2018 Galament. All rights reserved.
//
// REFERENCE: https://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:stochastic_oscillator_fast_slow_and_full

#import "StochasticIndicator.h"
#import "Graph.h"
#import "Tick.h"
#import <UIKit/UIKit.h>
#import "GraphicParam.h"

@interface StochasticIndicator() {
    NSMutableArray *hiddenParams;
}

@property (strong, nonatomic) NSMutableArray *indicatorValues;

@end

@implementation StochasticIndicator



-(void)reloadData {
    self.indicatorValues = [NSMutableArray new];
    NSInteger candleCount = [self.hostedGraph.dataSource candleCount];
    if(candleCount > self.indicatorValues.count) {
        self.indicatorValues = [[NSMutableArray alloc] init];
        for(int i = 0; i<candleCount; i++) {
            NSDictionary *value = [self valueForIndex:i];
            [self.indicatorValues addObject:value];
        }
    }
    [self setNeedsDisplay];
}

-(void)drawInContext:(CGContextRef)ctx {
    CGFloat candleWidth = [self.hostedGraph.dataSource candleWidth];
    NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    CGFloat offsetForCandles = [self.hostedGraph.dataSource offsetForCandles];
    
    CGContextSetLineWidth(ctx, 1.0);
    CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor.CGColor);
    int j = 0;
    for(int i = visibleRange.location; i<visibleRange.location+visibleRange.length; i++) {
        NSDictionary *value = self.indicatorValues[i];
        float kValue = [value[@"k"] floatValue];
        float currentX = candleWidth + (2 * candleWidth * j) + offsetForCandles;
        float currentY = [self yPositionForValue:kValue];
        if(j == 0) {
            CGContextMoveToPoint(ctx, currentX, currentY);
        } else {
            CGContextAddLineToPoint(ctx, currentX, currentY);
        }
        j++;
    }
    CGContextStrokePath(ctx);
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor);
    j = 0;
    for(int i = visibleRange.location; i<visibleRange.location+visibleRange.length; i++) {
        NSDictionary *value = self.indicatorValues[i];
        float kValue = [value[@"d"] floatValue];
        float currentX = candleWidth + (2 * candleWidth * j) + offsetForCandles;
        float currentY = [self yPositionForValue:kValue];
        if(j == 0) {
            CGContextMoveToPoint(ctx, currentX, currentY);
        } else {
            CGContextAddLineToPoint(ctx, currentX, currentY);
        }
        j++;
    }
    CGContextStrokePath(ctx);
    
}

-(NSDictionary *)valueForIndex:(NSInteger)index {
    GraphicParam *kPeriod = hiddenParams[0];
    GraphicParam *dPeriod = hiddenParams[1];
    GraphicParam *slowing = hiddenParams[2];
    NSInteger kPeriodValue = kPeriod.value.integerValue;
    NSInteger dPeriodValue = dPeriod.value.integerValue;
    NSInteger slowingValue = slowing.value.integerValue;
    NSDictionary *value;
    if(index >= self.indicatorValues.count) {
        NSNumber *k = [NSNumber numberWithFloat:0.0];
        NSNumber *d = [NSNumber numberWithFloat:0.0];
        if(index > kPeriodValue) {
            Tick *tick = [self.hostedGraph.dataSource tickForIndex:index];
            float max = 0.0;
            float min = HUGE_VALF;;
            for(int i = index-(kPeriodValue-1); i<=index; i++) {
                Tick *t = [self.hostedGraph.dataSource tickForIndex:i];
                if(t.max > max) max = t.max;
                if(t.min < min) min = t.min;
            }
            float kValue = ((tick.close - min) / (max - min)) * 100;
            k = [NSNumber numberWithFloat:kValue];
        }
        if(index >kPeriodValue+dPeriodValue) {
            float dValue = 0.0;
            for(int i = index-(dPeriodValue-1); i<index; i++) {
                NSDictionary *value = self.indicatorValues[i];
                NSNumber *previousK = value[@"k"];
                dValue += previousK.floatValue;
            }
            dValue += k.floatValue;
            dValue = dValue/slowingValue;
            d = [NSNumber numberWithFloat:dValue];
        }
        value = @{
                  @"k": k,
                  @"d": d
                  };
        
    } else {
        value = self.indicatorValues[index];
    }
    return value;
}

-(NSDecimalNumber *)minValue {
    /* NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    NSArray *array = [self.indicatorValues subarrayWithRange:visibleRange];
    NSArray *kValues = [array valueForKey:@"k"];
    NSArray *dValues = [array valueForKey:@"d"];
    NSNumber *minK = [kValues valueForKeyPath:@"@min.self"];
    NSNumber *minD = [dValues valueForKeyPath:@"@min.self"];
    if(minD.floatValue > minK.floatValue) {
        return minK;
    } else {
        return minD;
    } */
    return [NSDecimalNumber decimalNumberWithString:@"0.0"];
}

-(NSDecimalNumber *)maxValue {
    /* NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    NSArray *array = [self.indicatorValues subarrayWithRange:visibleRange];
    NSArray *kValues = [array valueForKey:@"k"];
    NSArray *dValues = [array valueForKey:@"d"];
    NSNumber *minK = [kValues valueForKeyPath:@"@max.self"];
    NSNumber *minD = [dValues valueForKeyPath:@"@max.self"];
    if(minD.floatValue < minK.floatValue) {
        return minK;
    } else {
        return minD;
    } */
    return [NSDecimalNumber decimalNumberWithString:@"100.0"];
}

-(NSMutableArray <GraphicParam *> *)params {
    if(!hiddenParams) {
        hiddenParams = [[NSMutableArray alloc] init];
        GraphicParam *kPeriod = [[GraphicParam alloc] init];
        kPeriod.name = @"%K Period";
        kPeriod.value = @"14";
        [hiddenParams addObject:kPeriod];
        GraphicParam *dPeriod = [[GraphicParam alloc] init];
        dPeriod.name = @"%D Period";
        dPeriod.value =@"3";
        [hiddenParams addObject:dPeriod];
        GraphicParam *slow = [[GraphicParam alloc] init];
        slow.name =@"Slowing";
        slow.value =@"3";
        [hiddenParams addObject:slow];
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
    return @"Stochastic";
}

@end
