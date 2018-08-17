//
//  RSIIndicator.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/16/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "RSIIndicator.h"
#import <UIKit/UIKit.h>
#import "Graph.h"
#import "Tick.h"
#import "GraphicParam.h"

@interface RSIIndicator(){
    NSMutableArray *hiddenParams;
}

@property (strong, nonatomic) NSMutableArray <NSDictionary *> *indicatorValues;

@end

@implementation RSIIndicator

-(void)drawInContext:(CGContextRef)ctx {
    CGFloat count = [self.hostedGraph.dataSource candleCount];
    CGFloat offsetForCandles = [self.hostedGraph.dataSource offsetForCandles];
    CGFloat candleWidth = [self.hostedGraph.dataSource candleWidth];
    if(count > self.indicatorValues.count) {
        self.indicatorValues = [[NSMutableArray alloc] init];
        for(int i = 0; i<count; i++) {
            NSDictionary *indicatorValue = [self valueForIndex:i];
            [self.indicatorValues addObject:indicatorValue];
        }
    }
    NSRange visibleRange = NSMakeRange(0, 0);
    if(self.hostedGraph.dataSource && [self.hostedGraph.dataSource respondsToSelector:@selector(currentVisibleRange)]) {
        visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    }
    
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:0.3].CGColor);
    float y1 = [self yPositionForValue:30.0];
    float y2 = [self yPositionForValue:70.0];
    CGContextAddRect(ctx, CGRectMake(0, y1, self.frame.size.width, y2-y1));
    CGContextFillPath(ctx);
    
    CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor.CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    int j = 0;
    for(int i = visibleRange.location; i<visibleRange.location+visibleRange.length; i++) {
        NSDictionary *dict = self.indicatorValues[i];
        NSNumber *rsi = dict[@"rsi"];
        float currentX = candleWidth + (2 * candleWidth * j) + offsetForCandles;
        float currentY = [self yPositionForValue:rsi.floatValue];
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
    NSDictionary *indicatorValue;
    if(index >= self.indicatorValues.count) {
        NSNumber *gain = [NSNumber numberWithFloat:0.0];
        NSNumber *loss = [NSNumber numberWithFloat:0.0];
        NSNumber *rsi = [NSNumber numberWithFloat:0.0];
        NSNumber *emaGain = [NSNumber numberWithFloat:0.0];
        NSNumber *emaLoss = [NSNumber numberWithFloat:0.0];
        //calculate gain
        if(index > 0) {
            Tick *tick = [self.hostedGraph.dataSource tickForIndex:index];
            Tick *previousTick = [self.hostedGraph.dataSource tickForIndex:index-1];
            float delta = tick.close - previousTick.close;
            if(delta > 0) {
                gain = [NSNumber numberWithFloat:fabsf(tick.close - previousTick.close)];
            } else {
                loss = [NSNumber numberWithFloat:fabsf(previousTick.close - tick.close)];
            }
        }
        //calculate rs
        
        if(index >= 14) {
            float averageGain = 0.0;
            float averageLoss = 0.0;
            for(int i = index-13; i<index; i++) {
                NSDictionary *value = self.indicatorValues[i];
                averageGain += [value[@"gain"] floatValue];
                averageLoss += [value[@"loss"] floatValue];
             }
            averageLoss += loss.floatValue;
            averageGain += gain.floatValue;
            averageLoss = averageLoss / 14.0;
            averageGain = averageGain / 14.0;
            emaGain = [NSNumber numberWithFloat:averageGain];
            emaLoss = [NSNumber numberWithFloat:averageLoss];
            float rs = 0.0;
            if(index == 14) {
                rs = averageGain / averageLoss;
            } else {
                NSDictionary *value = self.indicatorValues[index-1];
                NSNumber *previousLoss = value[@"emaLoss"];
                NSNumber *previousGain = value[@"emaGain"];
                float emaGainValue = ((previousGain.floatValue * 13.0) + gain.floatValue) / 14.0;
                float emaLossValue = ((previousLoss.floatValue * 13.0) + loss.floatValue) / 14.0;
                emaGain = [NSNumber numberWithFloat:emaGainValue];
                emaLoss = [NSNumber numberWithFloat:emaLossValue];
                rs = emaGainValue / emaLossValue;
            }
            
            float rsiValue = 100 - ( 100 / (1 + rs));
            rsi = [NSNumber numberWithFloat:rsiValue];
        }
        indicatorValue = @{
                           @"gain": gain,
                           @"loss": loss,
                           @"rsi": rsi,
                           @"emaGain": emaGain,
                           @"emaLoss": emaLoss
                           };
        Tick *tick = [self.hostedGraph.dataSource tickForIndex:index];
        NSLog(@"Gain: %@ Loss: %@ RSI: %@ Close: %f", gain, loss, rsi, tick.close);
        
        
    } else {
        indicatorValue = self.indicatorValues[index];
    }
    
    return indicatorValue;
}

-(NSDecimalNumber *)minValue {
    NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    NSArray *array = [self.indicatorValues subarrayWithRange:visibleRange];
    NSArray *gains = [array valueForKey:@"rsi"];
    NSNumber *maxValue = [gains valueForKeyPath:@"@min.self"];
    return maxValue;
}

-(NSDecimalNumber *)maxValue {
    NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    NSArray *array = [self.indicatorValues subarrayWithRange:visibleRange];
    NSArray *gains = [array valueForKey:@"rsi"];
    NSNumber *maxValue = [gains valueForKeyPath:@"@max.self"];
    return maxValue;
}

-(NSMutableArray <GraphicParam *> *)params {
    if(!hiddenParams) {
        hiddenParams = [[NSMutableArray alloc] init];
        GraphicParam *period = [[GraphicParam alloc] init];
        period.name = @"Period";
        period.value = @"14";
        period.type = GraphicParamTypeNumber;
        [hiddenParams addObject:period];
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
    return @"RSI";
}

@end
