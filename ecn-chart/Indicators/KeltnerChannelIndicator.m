//
//  KeltnerChannelIndicator.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/20/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "KeltnerChannelIndicator.h"
#import "Graph.h"
#import "Tick.h"
#import "GraphicParam.h"

@interface KeltnerChannelIndicator() {
    NSMutableArray *hiddenParams;
}

@property (strong, nonatomic) NSMutableArray <NSDictionary *> *indicatorValues;

@end

@implementation KeltnerChannelIndicator

-(void)drawInContext:(CGContextRef)ctx {
    NSInteger candleCount = [self.hostedGraph.dataSource candleCount];
    CGFloat candleWidth = [self.hostedGraph.dataSource candleWidth];
    CGFloat offsetforCandles = [self.hostedGraph.dataSource offsetForCandles];
    NSRange currentVisibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    if(candleCount >= self.indicatorValues.count) {
        self.indicatorValues = [[NSMutableArray alloc] init];
        for(int i = 0; i<candleCount; i++) {
            NSDictionary *value = [self valueForIndex:i];
            [self.indicatorValues addObject:value];
        }
    }
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    NSArray *subarray = [self.indicatorValues subarrayWithRange:currentVisibleRange];
    //draw top line
    NSArray *topValues = [subarray valueForKey:@"top"];
    NSInteger j = 0;
    for(NSNumber *number in topValues) {
        float currentX = [self xPositionForIteration:j];
        float currentY = [self yPositionForValue:number.floatValue];
        if(j == 0) {
            CGContextMoveToPoint(ctx, currentX, currentY);
        } else {
            CGContextAddLineToPoint(ctx, currentX, currentY);
        }
        j++;
    }
    //draw mid line
    NSArray *midValues = [subarray valueForKey:@"mid"];
    j = 0;
    for(NSNumber *number in midValues) {
        float currentX = [self xPositionForIteration:j];
        float currentY = [self yPositionForValue:number.floatValue];
        if(j == 0) {
            CGContextMoveToPoint(ctx, currentX, currentY);
        } else {
            CGContextAddLineToPoint(ctx, currentX, currentY);
        }
        j++;
    }
    //draw bot line
    NSArray *botValues = [subarray valueForKey:@"bot"];
    j = 0;
    for(NSNumber *number in botValues) {
        float currentX = [self xPositionForIteration:j];
        float currentY = [self yPositionForValue:number.floatValue];
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
    NSDictionary *value;
    if(index >= self.indicatorValues.count) {
        NSNumber *tr = [NSNumber numberWithFloat:0.0];
        NSNumber *atr = [NSNumber numberWithFloat:0.0];
        NSNumber *ema = [NSNumber numberWithFloat:0.0];
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
        if(index == 10) {
            float atrValue = 0.0;
            for(int i = 0; i<index-1; i++) {
                NSDictionary *dict = self.indicatorValues[i];
                NSNumber *atr = dict[@"tr"];
                atrValue += atr.floatValue;
            }
            atrValue += tr.floatValue;
            atrValue = atrValue / 10.0;
            atr = [[NSNumber alloc] initWithFloat:atrValue];
        } else if(index > 10) {
            NSDictionary *previousValue = self.indicatorValues[index-1];
            NSNumber *previousAtr = previousValue[@"atr"];
            float atrValue = previousAtr.floatValue * 9.0;
            atrValue += tr.floatValue;
            atrValue = atrValue / 10.0;
            atr = [NSNumber numberWithFloat:atrValue];
        }
        if(index == 20) {
            float initialEma = 0.0;
            for(NSInteger i = index-19; i<=index; i++) {
                Tick *tick = [self.hostedGraph.dataSource tickForIndex:i];
                initialEma += tick.close;
                
            }
            initialEma = initialEma / 20.0;
            ema = [NSNumber numberWithFloat:initialEma];
        } else if(index > 20) {
            NSDictionary *previousValue = self.indicatorValues[index-1];
            NSNumber *previousEma = previousValue[@"ema"];
            Tick *tick = [self.hostedGraph.dataSource tickForIndex:index];
            float multiplier = (2.0 / (20.0 + 1.0));
            float emaValue = (tick.close - previousEma.floatValue) * multiplier + previousEma.floatValue;
            ema = [NSNumber numberWithFloat:emaValue];
        }
        
        NSNumber *midLine = ema;
        float topLineValue = ema.floatValue + 2.0 * atr.floatValue;
        float botLineValue= ema.floatValue - 2.0 * atr.floatValue;
        NSNumber *topLine = [NSNumber numberWithFloat:topLineValue];
        NSNumber *botLine = [NSNumber numberWithFloat:botLineValue];
        
        
        
        value = @{
                  @"tr": tr,
                  @"atr": atr,
                  @"ema": ema,
                  @"mid": midLine,
                  @"bot": botLine,
                  @"top": topLine
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
    NSRange currentVisibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    if(currentVisibleRange.length == 0) {
        return [NSDecimalNumber decimalNumberWithString:@"0.0"];
    }
    float minValue = HUGE_VALF;
    for(NSInteger i = currentVisibleRange.location; i<currentVisibleRange.location + currentVisibleRange.length; i++) {
        NSDictionary *value = self.indicatorValues[i];
        NSNumber *topLine = value[@"bot"];
        if(topLine.floatValue < minValue) minValue = topLine.floatValue;
    }
    return [[NSDecimalNumber alloc] initWithFloat:minValue];
}

-(NSDecimalNumber *)maxValue {
    NSRange currentVisibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    float maxValue = 0.0;
    for(NSInteger i = currentVisibleRange.location; i<currentVisibleRange.location + currentVisibleRange.length; i++) {
        NSDictionary *value = self.indicatorValues[i];
        NSNumber *topLine = value[@"top"];
        if(topLine.floatValue > maxValue) maxValue = topLine.floatValue;
    }
    
    return [[NSDecimalNumber alloc] initWithFloat:maxValue];
}

-(NSString *)name {
    return @"Keltner Channel";
}

-(NSMutableArray <GraphicParam *> *)params {
    if(!hiddenParams) {
        hiddenParams = [[NSMutableArray alloc] init];
        GraphicParam *emaPeriod = [GraphicParam new];
        emaPeriod.name = @"EMA Period";
        emaPeriod.type  = GraphicParamTypeNumber;
        emaPeriod.value = @"20";
        GraphicParam *multiplier = [GraphicParam new];
        multiplier.name = @"Multiplier";
        multiplier.type = GraphicParamTypeNumber;
        multiplier.value = @"2";
        [hiddenParams addObject:emaPeriod];
        [hiddenParams addObject:multiplier];
    }
    
    return hiddenParams;
}

-(void)setParams:(NSMutableArray<GraphicParam *> *)params {
    hiddenParams = params;
}

-(GraphicType)graphicType {
    return GraphicTypeMain;
}


@end
