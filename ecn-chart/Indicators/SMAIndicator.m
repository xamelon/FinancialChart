//
//  SMAIndicator.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/14/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "SMAIndicator.h"
#import "Tick.h"

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
    
    CGContextSetStrokeColorWithColor(ctx, UIColor.blueColor.CGColor);
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
        if(index <= 5) {
            return 0.0;
        } else {
            double sum = 0.0;
            for(NSInteger i = index-4; i<=index; i++) {
                Tick *tick = [self.dataSource tickForIndex:i];
                sum += tick.close;
            }
            NSNumber *number = [NSNumber numberWithDouble:sum/5.0];
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
        return 0.0; 
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
