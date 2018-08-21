//
//  BollingerBandsIndicator.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/14/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "BollingerBandsIndicator.h"
#import "Tick.h"
#import <UIKit/UIKit.h>
#import "Graph.h"
#import "GraphicParam.h"
@interface BollingerBandsIndicator() {
    NSMutableArray *hiddenParams;
}

@property (strong, nonatomic) NSMutableArray <NSDictionary *> *indicatorValues;

@end

@implementation BollingerBandsIndicator

-(id)init {
    self = [super init];
    if(self) {
        self.indicatorValues = [NSMutableArray new];
    }
    
    return self;
}


-(void)reloadData {
    self.indicatorValues = [NSMutableArray new];
    [self setNeedsDisplay];
}


-(void)drawInContext:(CGContextRef)ctx {
    CGRect frame = self.frame;
    NSRange visibleRange = NSMakeRange(0, 0);
    CGFloat candleWidth = [self.hostedGraph.dataSource candleWidth];
    CGFloat offsetForCandles = [self.hostedGraph.dataSource offsetForCandles];
    NSInteger count = [self.hostedGraph.dataSource candleCount];
    if(count > self.indicatorValues.count) {
        self.indicatorValues = [[NSMutableArray alloc] init];
        for(int i = 0; i<count; i++) {
            NSDictionary *value = [self valueForIndex:i];
            [self.indicatorValues addObject:value];
        }
    }
    
    if(self.hostedGraph.dataSource && [self.hostedGraph.dataSource respondsToSelector:@selector(currentVisibleRange)]) {
        visibleRange = [self.hostedGraph.dataSource currentVisibleRange];
    }
    int j = 0;
    
    CGFloat dashes[] = {6, 2};
    CGContextSetLineDash(ctx, 3.0, dashes, 2);
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:10.0].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    
    for(NSInteger i = visibleRange.location; i<visibleRange.location + visibleRange.length; i++) {
        NSDictionary *dict = [self valueForIndex:i];
        float smaValue = [dict[@"mid"] floatValue];
        float currentX = candleWidth + (2 * candleWidth * j) + offsetForCandles;
        float currentY = [self yPositionForValue:smaValue];
        if(j == 0) {
            CGContextMoveToPoint(ctx, currentX, currentY);
        } else {
            CGContextAddLineToPoint(ctx, currentX, currentY);
        }
        
        j++;
    }
    j = 0;
    CGContextStrokePath(ctx);
    CGContextSetLineDash(ctx, 0.0, dashes, 0);
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:10.0].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    
    for(NSInteger i = visibleRange.location; i<visibleRange.location + visibleRange.length; i++) {
        NSDictionary *dict = [self valueForIndex:i];
        float smaValue = [dict[@"top"] floatValue];
        float currentX = candleWidth + (2 * candleWidth * j) + offsetForCandles;
        float currentY = [self yPositionForValue:smaValue];
        if(j == 0) {
            CGContextMoveToPoint(ctx, currentX, currentY);
        } else {
            CGContextAddLineToPoint(ctx, currentX, currentY);
        }
        
        j++;
    }
    CGContextStrokePath(ctx);
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:10.0].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    j = 0;
    for(NSInteger i = visibleRange.location; i<visibleRange.location + visibleRange.length; i++) {
        NSDictionary *dict = [self valueForIndex:i];
        float smaValue = [dict[@"bot"] floatValue];
        float currentX = candleWidth + (2 * candleWidth * j) + offsetForCandles;
        float currentY = [self yPositionForValue:smaValue];
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
    NSDictionary *value = @{
                            @"mid": [NSNumber numberWithFloat:0.0],
                            @"top": [NSNumber numberWithFloat:0.0],
                            @"bot": [NSNumber numberWithFloat:0.0]
                            };
    GraphicParam *period = hiddenParams[0];
    GraphicParam *deviation = hiddenParams[1];
    NSInteger periodValue = period.value.integerValue;
    float deviationValue = deviation.value.floatValue;
    if(index >= self.indicatorValues.count) {
        if(index >= periodValue) {
            //calculating sma
            float sma = 0.0;
            for(NSInteger i = index-(periodValue-1); i<=index; i++) {
                Tick *tick = [self.hostedGraph.dataSource tickForIndex:i];
                sma += tick.close;
            }
            sma = sma/periodValue;
            
            float deviation = 0.0;
            for(NSInteger i = index-(periodValue-1); i<=index; i++) {
                Tick *tick = [self.hostedGraph.dataSource tickForIndex:i];
                float sum = tick.close - sma;
                deviation += sum * sum;
            }
            deviation = deviation/periodValue;
            deviation = sqrt(deviation);
            //calculating standard price deviation
            float topLine = sma + deviation * deviationValue;
            float botLine = sma - deviation * deviationValue;
            value = @{
                     @"mid": [NSNumber numberWithFloat:sma],
                     @"top": [NSNumber numberWithFloat:topLine],
                     @"bot": [NSNumber numberWithFloat:botLine]
                     };
        }
    } else {
        value = self.indicatorValues[index];
    }
    
    return value;
}

-(NSDecimalNumber *)minValue {
    NSRange range = [self.hostedGraph.dataSource currentVisibleRange];
    NSArray *array = [self.indicatorValues subarrayWithRange:range];
    NSArray *botValues = [array valueForKey:@"bot"];
    NSNumber *minValue = [botValues valueForKeyPath:@"@min.self"];
    return minValue;
}

-(NSDecimalNumber *)maxValue {
    NSRange range = [self.hostedGraph.dataSource currentVisibleRange];
    NSArray *array = [self.indicatorValues subarrayWithRange:range];
    NSArray *botValues = [array valueForKey:@"top"];
    NSNumber *minValue = [botValues valueForKeyPath:@"@max.self"];
    return minValue;
}

-(NSMutableArray <GraphicParam *> *)params {
    if(!hiddenParams) {
        hiddenParams = [[NSMutableArray alloc] init];
        GraphicParam *period = [[GraphicParam alloc] init];
        period.name = @"Period";
        period.value = @"14";
        period.type = GraphicParamTypeNumber;
        [hiddenParams addObject:period];
        GraphicParam *deviation = [[GraphicParam alloc] init];
        deviation.name = @"Deviation";
        deviation.type = GraphicParamTypeNumber;
        deviation.value = @"2";
        [hiddenParams addObject:deviation];
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
    return @"Bollinger Bands";
}

@end
