//
//  StochRSIIndicator.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/20/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "StochRSIIndicator.h"
#import "Graph.h"
#import "Tick.h"
#import "GraphicParam.h"

@interface StochRSIIndicator() {
    NSMutableArray *hiddenParams;
}

@property (strong, nonatomic) NSMutableArray <NSDictionary *> *indicatorValues;

@end

@implementation StochRSIIndicator



-(void)reloadData {
    self.indicatorValues = [NSMutableArray new];
    [self setNeedsDisplay];
}

-(void)drawInContext:(CGContextRef)ctx {
    CGContextClearRect(ctx, self.frame);
    NSInteger candleCount = [self.hostedGraph.dataSource candleCount];
    NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    if(candleCount >= self.indicatorValues.count) {
        self.indicatorValues = [[NSMutableArray alloc] init];
        for(int i = 0; i<candleCount; i++) {
            NSDictionary *dict = [self valueForIndex:i];
            [self.indicatorValues addObject:dict];
        }
    }
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    NSArray *array = [self.indicatorValues subarrayWithRange:visibleRange];
    NSInteger j = 0;
    for(NSDictionary *dict in array) {
        NSNumber *rsi = dict[@"stochRSI"];
        CGFloat currentX = [self xPositionForIteration:j];
        CGFloat currentY = [self yPositionForValue:rsi.floatValue];
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
        NSNumber *stochRSI = [NSNumber numberWithFloat:0.0];
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
                float emaGainValue = ((previousGain.floatValue * (periodValue - 1)) + gain.floatValue) / periodValue;
                float emaLossValue = ((previousLoss.floatValue * (periodValue - 1)) + loss.floatValue) / periodValue;
                emaGain = [NSNumber numberWithFloat:emaGainValue];
                emaLoss = [NSNumber numberWithFloat:emaLossValue];
                rs = emaGainValue / emaLossValue;
            }
            
            float rsiValue = 100 - ( 100 / (1 + rs));
            rsi = [NSNumber numberWithFloat:rsiValue];
            NSArray *subarray = [self.indicatorValues subarrayWithRange:NSMakeRange(index-(periodValue-1), periodValue-1)];
            NSArray *rsiValues = [subarray valueForKey:@"rsi"];
            rsiValues = [rsiValues arrayByAddingObject:rsi];
            NSNumber *maxRSI = [rsiValues valueForKeyPath:@"@max.self"];
            NSNumber *minRSI = [rsiValues valueForKeyPath:@"@min.self"];
            float stochRSIValue = (rsiValue - minRSI.floatValue) / (maxRSI.floatValue - minRSI.floatValue);
            stochRSI = [NSNumber numberWithFloat:stochRSIValue];
        }
        indicatorValue = @{
                           @"gain": gain,
                           @"loss": loss,
                           @"rsi": rsi,
                           @"emaGain": emaGain,
                           @"emaLoss": emaLoss,
                           @"stochRSI": stochRSI
                           };
        Tick *tick = [self.hostedGraph.dataSource tickForIndex:index];
        
        
    } else {
        indicatorValue = self.indicatorValues[index];
    }
    
    return indicatorValue;
}

-(NSString *)name {
    return @"Stochastic RSI";
}

-(NSDecimalNumber *)minValue {
    return [NSDecimalNumber decimalNumberWithString:@"0.0"];
}

-(NSDecimalNumber *)maxValue {
    return [NSDecimalNumber decimalNumberWithString:@"1.0"];
}

-(GraphicType)graphicType {
    return GraphicTypeBottom;
}

-(NSMutableArray <GraphicParam *> *)params {
    if(!hiddenParams) {
        hiddenParams = [[NSMutableArray alloc] init];
        GraphicParam *period = [[GraphicParam alloc] init];
        period.name = @"Period";
        period.type = GraphicParamTypeNumber;
        period.value = @"14";
        [hiddenParams addObject:period];
    }
    
    return hiddenParams;
}

-(void)setParams:(NSMutableArray<GraphicParam *> *)params {
    hiddenParams = params;
}
@end
