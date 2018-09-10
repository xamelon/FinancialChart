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



-(void)reloadData {
    self.indicatorValues = [NSMutableArray new];
    CGFloat count = [self.hostedGraph.dataSource candleCount];
    if(count > self.indicatorValues.count) {
        self.indicatorValues = [[NSMutableArray alloc] init];
        for(int i = 0; i<count; i++) {
            NSDictionary *indicatorValue = [self valueForIndex:i];
            [self.indicatorValues addObject:indicatorValue];
        }
    }
    [self setNeedsDisplay];
}

-(void)drawInContext:(CGContextRef)ctx {
    CGContextClearRect(ctx, self.frame);
    CGFloat offsetForCandles = [self.hostedGraph.dataSource offsetForCandles];
    CGFloat candleWidth = [self.hostedGraph.dataSource candleWidth];
    
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
    GraphicParam *period = hiddenParams[0];
    NSInteger periodValue = period.value.integerValue;
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
        
        if(index >= periodValue) {
            float averageGain = 0.0;
            float averageLoss = 0.0;
            for(int i = index-(periodValue-1); i<index; i++) {
                NSDictionary *value = self.indicatorValues[i];
                averageGain += [value[@"gain"] floatValue];
                averageLoss += [value[@"loss"] floatValue];
             }
            averageLoss += loss.floatValue;
            averageGain += gain.floatValue;
            averageLoss = averageLoss / periodValue;
            averageGain = averageGain / periodValue;
            emaGain = [NSNumber numberWithFloat:averageGain];
            emaLoss = [NSNumber numberWithFloat:averageLoss];
            float rs = 0.0;
            if(index == periodValue) {
                rs = averageGain / averageLoss;
            } else {
                NSDictionary *value = self.indicatorValues[index-1];
                NSNumber *previousLoss = value[@"emaLoss"];
                NSNumber *previousGain = value[@"emaGain"];
                float emaGainValue = ((previousGain.floatValue * (periodValue-1)) + gain.floatValue) / periodValue;
                float emaLossValue = ((previousLoss.floatValue * (periodValue-1)) + loss.floatValue) / periodValue;
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
        
        
    } else {
        indicatorValue = self.indicatorValues[index];
    }
    
    return indicatorValue;
}

-(NSDecimalNumber *)minValue {
    return [NSDecimalNumber decimalNumberWithString:@"0.0"];
}

-(NSDecimalNumber *)maxValue {
    return [NSDecimalNumber decimalNumberWithString:@"100.0"];
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

-(NSString *)description {
    GraphicParam *period = hiddenParams.firstObject;
    NSString *description = [NSString stringWithFormat:@"RSI(%@)", period.value];
    return description;
}

@end
