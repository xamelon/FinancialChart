//
//  EmaIndicator.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/14/18.
//  Copyright © 2018 Galament. All rights reserved.
//
//
// How to calculate EMA: https://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:moving_averages
//

#import "EmaIndicator.h"
#import "Tick.h"
#import <UIKit/UIKit.h>
#import "Graph.h"
#import "GraphicParam.h"

@interface EmaIndicator() {
    NSMutableArray *hiddenParams;
}

@property (strong, nonatomic) NSMutableArray <NSNumber *> *indicatorValues;

@end

@implementation EmaIndicator

-(id)init {
    self = [super init];
    if(self) {
        self.indicatorValues = [NSMutableArray new];
    }
    
    return self;
}

-(void)drawInContext:(CGContextRef)ctx {
    CGRect frame = self.frame;
    NSRange visibleRange = NSMakeRange(0, 0);
    CGFloat candleWidth = [self.hostedGraph.dataSource candleWidth];
    CGFloat offsetForCandles = [self.hostedGraph.dataSource offsetForCandles];
    NSInteger count = [self.hostedGraph.dataSource candleCount];
    NSLog(@"Offset Candle: %f", offsetForCandles);
    if(count > self.indicatorValues.count) {
        self.indicatorValues = [[NSMutableArray alloc] init];
        for(int i = 0; i<count; i++) {
            NSNumber *value = [self valueForIndex:i];
            [self.indicatorValues addObject:value];
        }
    }
    
    if(self.hostedGraph.dataSource && [self.hostedGraph.dataSource respondsToSelector:@selector(currentVisibleRange)]) {
        visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    }
    int j = 0;
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    
    for(NSInteger i = visibleRange.location; i<visibleRange.location + visibleRange.length; i++) {
        NSNumber *value = self.indicatorValues[i];
        float currentX = candleWidth + (2 * candleWidth * j) + offsetForCandles;
        float currentY = [self yPositionForValue:value.floatValue];
        if(j == 0) {
            CGContextMoveToPoint(ctx, currentX, currentY);
        } else {
            CGContextAddLineToPoint(ctx, currentX, currentY);
        }
        
        j++;
    }
    CGContextStrokePath(ctx);
    
    
}

-(NSNumber *)valueForIndex:(NSInteger)index {
    NSNumber *number = [NSNumber numberWithFloat:0.0];
    if(index >= self.indicatorValues.count) {
        if(index == 10) {
            double sum = 0.0;
            for(NSInteger i = index-9; i<=index; i++) {
                NSLog(@"Index candle %d", i);
                Tick *tick = [self.hostedGraph.dataSource tickForIndex:i];
                sum += tick.close;
            }
            number = [NSNumber numberWithDouble:sum/10.0];
        } else if(index > 10) {
            Tick *tick = [self.hostedGraph.dataSource tickForIndex:index];
            NSNumber *previousEma = self.indicatorValues[index-1];
            float multiplier = (2.0 / (10.0 + 1.0));
            float ema = (tick.close - previousEma.floatValue) * multiplier + previousEma.floatValue;
            NSLog(@"Ema: %f tick.close: %f multiplier: %f", ema, tick.close, multiplier);
            number = [NSNumber numberWithFloat:ema];
        }
    } else {
        number = self.indicatorValues[index];
    }
    
    return number;
}

-(NSDecimalNumber *)minValue {
    NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    NSArray *array = [self.indicatorValues subarrayWithRange:visibleRange];
    NSNumber *maxValue = [array valueForKeyPath:@"@min.self"];
    return maxValue;
}

-(NSDecimalNumber *)maxValue {
    NSRange visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    NSArray *array = [self.indicatorValues subarrayWithRange:visibleRange];
    NSNumber *maxValue = [array valueForKeyPath:@"@max.self"];
    return maxValue;
}

-(NSMutableArray <GraphicParam *> *)params {
    if(!hiddenParams) {
        hiddenParams = [[NSMutableArray alloc] init];
        GraphicParam *param = [[GraphicParam alloc] init];
        param.name = @"Period";
        param.value = @"14";
        param.type = GraphicParamTypeNumber;
        [hiddenParams addObject:param];
    }
    return hiddenParams;
}

-(void)setParams:(NSMutableArray<GraphicParam *> *)params {
    hiddenParams = params;
}

-(GraphicType)graphicType {
    return GraphicTypeMain;
}

-(NSString *)name {
    return @"EMA";
}

@end
