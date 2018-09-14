//
//  CCIIndicator.m
//  ecn-chart
//
//  Created by Stas Buldakov on 9/14/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "CCIIndicator.h"
#import "GraphicParam.h"
#import "Tick.h"
#import "Graph.h"

@interface CCIIndicator() {
    NSMutableArray *hiddenParams;
}

@property (strong, nonatomic) NSMutableArray <NSDictionary *> *indicatorValues;

@end

@implementation CCIIndicator

-(id)init {
    self = [super init];
    if(self) {
        self.indicatorValues = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)reloadData {
    self.indicatorValues = [NSMutableArray new];
    NSInteger count = [self.hostedGraph.dataSource candleCount];
    if(self.indicatorValues.count < count) {
        self.indicatorValues = [[NSMutableArray alloc] init];
        for(NSInteger i = 0; i<count; i++) {
            NSDictionary *value = [self valueForIndex:i];
            [self.indicatorValues addObject:value];
        }
    }
    [self setNeedsDisplay];
}


-(void)drawInContext:(CGContextRef)ctx {
    CGContextClearRect(ctx, self.frame);
    CGFloat offsetForCandles = [self.hostedGraph.dataSource offsetForCandles];
    CGFloat candelWidth = [self.hostedGraph.dataSource candleWidth];
    NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
    
    int j  = 0;
    for(NSInteger i = visibleRange.location; i<visibleRange.location + visibleRange.length; i++) {
        NSDictionary *value = self.indicatorValues[i];
        NSNumber *cci = value[@"cci"];
        float currentX = [self xPositionForIteration:j];
        float currentY = [self yPositionForValue:cci.floatValue];
        if(j == 0) {
            CGContextMoveToPoint(ctx, currentX, currentY);
        } else {
            CGContextAddLineToPoint(ctx, currentX, currentY);
        }
        j++;
    }
    CGContextStrokePath(ctx);
}

-(NSDictionary *)valueForIndex:(NSUInteger)index {
    NSMutableArray *params = self.params;
    GraphicParam *param = params[0];
    float period = param.value.floatValue;
    NSDictionary *value = @{
                            @"sma": [NSNumber numberWithFloat:0.0],
                            @"tp": [NSNumber numberWithFloat:0.0],
                            @"cci": [NSNumber numberWithFloat:0.0],
                            };
    if(index >= self.indicatorValues.count) {
        if(index > period) {
            Tick *tick = [self.hostedGraph.dataSource tickForIndex:index];
            double tp = (tick.max + tick.min + tick.close) / 3.0;
            double sum = 0.0;
            double deviation = 0.0;
            for(NSInteger i = index-(period-1); i<index; i++) {
                Tick *tick = [self.hostedGraph.dataSource tickForIndex:i];
                sum += tick.close;
                NSDictionary *previousValue = self.indicatorValues[i];
                double sma = [previousValue[@"sma"] doubleValue];
                double tpa = [previousValue[@"tp"] doubleValue];
                deviation += fabs(tpa-sma);
            }
            sum += tick.close;
            sum = sum / period;
            
            deviation += fabs(tp - sum);
            deviation = deviation / period;
            float cci = (tp - sum) / (0.015 * deviation);
            value = @{
                     @"tp": [NSNumber numberWithFloat:tp],
                     @"sma": [NSNumber numberWithFloat:sum],
                     @"cci": [NSNumber numberWithFloat:cci]
                     };
        }
    } else {
        value = self.indicatorValues[index];
    }
    
    return value;
}

-(NSDecimalNumber *)minValue {
    NSRange currentVisibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    if(currentVisibleRange.location > self.indicatorValues.count ||
       currentVisibleRange.location + currentVisibleRange.length > self.indicatorValues.count) {
        return [NSDecimalNumber decimalNumberWithString:@"0.0"];
    }
    NSArray <NSDictionary *> *values = [self.indicatorValues subarrayWithRange:currentVisibleRange];
    NSArray *cciValues = [values valueForKeyPath:@"cci"];
    NSNumber *cciMin = [cciValues valueForKeyPath:@"@min.self"];
    if(cciMin.floatValue > -100.0) {
        return [NSDecimalNumber decimalNumberWithString:@"-100.0"];
    }
    return cciMin;
}

-(NSDecimalNumber *)maxValue {
    NSRange currentVisibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    if(currentVisibleRange.location > self.indicatorValues.count ||
       currentVisibleRange.location + currentVisibleRange.length > self.indicatorValues.count) {
        return [NSDecimalNumber decimalNumberWithString:@"0.0"];
    }
    NSArray <NSDictionary *> *values = [self.indicatorValues subarrayWithRange:currentVisibleRange];
    NSArray *cciValues = [values valueForKeyPath:@"cci"];
    NSNumber *cciMin = [cciValues valueForKeyPath:@"@max.self"];
    if(cciMin.floatValue < 100.0) {
        return [NSDecimalNumber decimalNumberWithString:@"100.0"];
    }
    return cciMin;
}

-(NSMutableArray <GraphicParam *> *)params {
    if(!hiddenParams) {
        hiddenParams = [[NSMutableArray alloc] init];
        GraphicParam *period = [[GraphicParam alloc] init];
        period.name = @"Perod";
        period.value = @"20";
        period.type = GraphicParamTypeNumber;
        [hiddenParams addObject:period];
    }
    return hiddenParams;
}

-(void)setParams:(NSMutableArray<GraphicParam *> *)params {
    hiddenParams = params;
}

-(GraphicType)graphicType {
    return GraphicTypeBottom;;
}

-(NSString *)name {
    return  @"CCI";
}


@end
