//
//  SARIndicator.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/14/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "SARIndicator.h"
#import <UIKit/UIKit.h>
#import "Tick.h"
#import "Graph.h"
#import "GraphicParam.h"

@interface SARIndicator() {
    NSMutableArray *hiddenParams;
}

@property (strong, nonatomic) NSMutableArray <NSDictionary *> *indicatorValues;

@end

@implementation SARIndicator

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
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    
    for(NSInteger i = visibleRange.location; i<visibleRange.location + visibleRange.length; i++) {
        NSDictionary *num = self.indicatorValues[i];
        NSNumber *value = num[@"sarValue"];
        float currentX = candleWidth + (2 * candleWidth * j) + offsetForCandles;
        float currentY = [self yPositionForValue:value.floatValue];
        CGContextAddEllipseInRect(ctx, CGRectMake(currentX-candleWidth/4.0, currentY-candleWidth/4.0, candleWidth/2.0, candleWidth/2.0));
        
        j++;
    }
    CGContextStrokePath(ctx);
    
    
}

-(NSDictionary *)valueForIndex:(NSInteger)index {
    NSDictionary *sarValue;
    if(index >= self.indicatorValues.count) {
        Tick *tick = [self.hostedGraph.dataSource tickForIndex:index];
        if(index == 0) {
            sarValue = @{
                       @"sarValue": @(tick.min),
                       @"af": @(0.02),
                       @"ep": @(tick.max),
                       @"risingTrend": @(YES)
                       };
        } else {
            NSDictionary *previousSar = self.indicatorValues[index-1];
            BOOL trend = [previousSar[@"risingTrend"] boolValue];
            float previousSarValue = [previousSar[@"sarValue"] floatValue];
            float previousEp = [previousSar[@"ep"] floatValue];
            float af = [previousSar[@"af"] floatValue];
            
            float newSar = [self sarWithPreviousSar:previousSarValue previousEp:previousEp af:af trend:trend];
            if(trend && tick.max > previousEp) {
                previousEp = tick.max;
                if(af < 0.2) {
                    af += 0.02;
                }
            } else if(!trend && tick.min < previousEp) {
                previousEp = tick.min;
                if(af < 0.2) {
                    af += 0.02;
                }
            }
            
            if(trend && newSar > tick.min) {
                trend = false;
                af = 0.02;
                newSar = previousEp;
                previousEp= tick.min;
            } else if(!trend && newSar < tick.max) {
                trend = true;
                af = 0.02;
                newSar = previousEp;
                previousEp = tick.max;
            }
            sarValue = @{
                                   @"sarValue": @(newSar),
                                   @"af": @(af),
                                   @"ep": @(previousEp),
                                   @"risingTrend": @(trend)
                                   };
        }
    } else {
        sarValue = self.indicatorValues[index];
    }
    
    return sarValue;
}

-(CGFloat)sarWithPreviousSar:(float)previousSar previousEp:(float)ep af:(float)af trend:(BOOL)trend {
    float sar;
    if(trend) {
        sar = previousSar + af*(ep-previousSar);
    } else {
        sar = previousSar - af*(previousSar-ep);
    }
    return sar;
}

-(NSDecimalNumber *)maxValue {
    NSRange range = [self.hostedGraph.dataSource currentVisibleRange];
    NSArray *array = [self.indicatorValues subarrayWithRange:range];
    NSArray *sarValues = [array valueForKey:@"sarValue"];
    NSNumber *maxValue = [sarValues valueForKeyPath:@"@max.self"];
    return maxValue;
}

-(NSDecimalNumber *)minValue {
    NSRange range = [self.hostedGraph.dataSource currentVisibleRange];
    NSArray *array = [self.indicatorValues subarrayWithRange:range];
    NSArray *sarValues = [array valueForKey:@"sarValue"];
    NSNumber *maxValue = [sarValues valueForKeyPath:@"@min.self"];
    return maxValue;
}

-(NSMutableArray <GraphicParam *> *)params {
    if(!hiddenParams) {
        hiddenParams = [[NSMutableArray alloc] init];
        GraphicParam *step = [[GraphicParam alloc] init];
        step.name = NSLocalizedString(@"Step", nil);
        step.value = @"0.02";
        step.type = GraphicParamTypeNumber;
        GraphicParam *maximum = [[GraphicParam alloc] init];
        maximum.name = NSLocalizedString(@"Maximum", nil);
        maximum.value = @"0.2";
        maximum.type = GraphicParamTypeNumber;
        [hiddenParams addObject:step];
        [hiddenParams addObject:maximum];
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
    return @"Parabolic SAR";
}

@end
