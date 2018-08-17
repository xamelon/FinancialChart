//
//  SMAIndicator.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/14/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "SMAIndicator.h"
#import "Tick.h"
#import "Graph.h"

@interface SMAIndicator()

@property (strong, nonatomic) NSMutableArray *indicatorValues;

@end


@implementation SMAIndicator

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
    
    CGContextSetStrokeColorWithColor(ctx, UIColor.blueColor.CGColor);
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
    NSNumber *value = [NSNumber numberWithFloat:0.0];
    if(index >= self.indicatorValues.count) {
        if(index > 5) {
            double sum = 0.0;
            for(NSInteger i = index-4; i<=index; i++) {
                Tick *tick = [self.hostedGraph.dataSource tickForIndex:i];
                sum += tick.close;
            }
            value = [NSNumber numberWithDouble:sum/5.0];
        }
    } else {
        value = self.indicatorValues[index];
    }
    
    return value;
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


@end
