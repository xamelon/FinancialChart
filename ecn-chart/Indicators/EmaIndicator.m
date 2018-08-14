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

@interface EmaIndicator()

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
    CGFloat candleWidth = [self.dataSource candleWidth];
    CGFloat offsetForCandles = [self.dataSource offsetForCandles];
    NSInteger count = [self.dataSource candleCount];
    NSLog(@"Offset Candle: %f", offsetForCandles);
    if(count > self.indicatorValues.count) {
        NSMutableArray *appendingArray = [[NSMutableArray alloc] init];
        for(int i = self.indicatorValues.count; i<count; i++) {
            [appendingArray addObject:[NSNumber numberWithDouble:-1.0]];
        }
        self.indicatorValues = [[appendingArray arrayByAddingObjectsFromArray:self.indicatorValues] mutableCopy];
    }
    
    if(self.dataSource && [self.dataSource respondsToSelector:@selector(currentVisibleRange)]) {
        visibleRange = [self.dataSource currentVisibleRange];
    }
    int j = 0;
    
    CGContextSetStrokeColorWithColor(ctx, UIColor.yellowColor.CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    
    for(NSInteger i = visibleRange.location; i<visibleRange.location + visibleRange.length; i++) {
        float currentX = candleWidth + (2 * candleWidth * j) + offsetForCandles;
        float currentY = [self yPositionForIndex:i];
        if(j == 0) {
            CGContextMoveToPoint(ctx, currentX, currentY);
        } else {
            CGContextAddLineToPoint(ctx, currentX, currentY);
        }
        
        j++;
    }
    CGContextStrokePath(ctx);
    
    
}

-(CGFloat)valueForIndex:(NSInteger)index {
    NSNumber *value = self.indicatorValues[index];
    if(value.doubleValue == -1.0) {
        if(index < 10) {
            return 0.0;
        } else if(index == 10) {
            double sum = 0.0;
            for(NSInteger i = index-9; i<=index; i++) {
                NSLog(@"Index candle %d", i);
                Tick *tick = [self.dataSource tickForIndex:i];
                sum += tick.close;
            }
            NSNumber *number = [NSNumber numberWithDouble:sum/10.0];
            [self.indicatorValues replaceObjectAtIndex:index withObject:number];
            return number.floatValue;
        } else {
            Tick *tick = [self.dataSource tickForIndex:index];
            float previousEma = [self valueForIndex:index-1];
            float multiplier = (2.0 / (10.0 + 1.0));
            float ema = (tick.close - previousEma) * multiplier + previousEma;
            NSLog(@"Ema: %f tick.close: %f multiplier: %f", ema, tick.close, multiplier);
            NSNumber *number = [NSNumber numberWithFloat:ema];
            [self.indicatorValues replaceObjectAtIndex:index withObject:number];
            return number.floatValue;
        }
    }
    return value.floatValue;
}

-(CGFloat)yPositionForIndex:(NSInteger)index {
    CGFloat value = [self valueForIndex:index];
    CGFloat minValue = [self.dataSource minValue];
    CGFloat maxValue = [self.dataSource maxValue];
    CGFloat y1 = 20+(self.frame.size.height-40) * (1 - (value - minValue)/(maxValue - minValue));
    return y1;
}

-(CGFloat)maxValueInRange:(NSRange)range {
    if(self.indicatorValues.count == 0) return 0.0;
    if(range.location + range.length > self.indicatorValues.count) {
        NSInteger newLength = self.indicatorValues.count - range.location;
        range = NSMakeRange(range.location, newLength);
    }
    NSArray *array = [self.indicatorValues subarrayWithRange:range];
    
    float maxValue = 0.0;
    for(NSNumber *number in array) {
        if(number.floatValue > maxValue) maxValue = number.floatValue;
    }
    return maxValue;
}

-(CGFloat)minValueInRange:(NSRange)range {
    if(self.indicatorValues.count == 0) return 0.0;
    if(range.location + range.length > self.indicatorValues.count) {
        NSInteger newLength = self.indicatorValues.count - range.location;
        range = NSMakeRange(range.location, newLength);
    }
    NSArray *array = [self.indicatorValues subarrayWithRange:range];
    float minValue = 0.0;
    if(array.count > 0) {
        minValue = CGFLOAT_MAX;
        for(NSNumber *number in array) {
            if(number.floatValue < minValue) minValue = number.floatValue;
        }
    }
    return minValue;
}
@end
