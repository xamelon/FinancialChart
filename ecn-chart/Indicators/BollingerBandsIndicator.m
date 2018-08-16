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

@interface BollingerBandsIndicator()

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

-(void)drawInContext:(CGContextRef)ctx {
    CGRect frame = self.frame;
    NSRange visibleRange = NSMakeRange(0, 0);
    CGFloat candleWidth = [self.dataSource candleWidth];
    CGFloat offsetForCandles = [self.dataSource offsetForCandles];
    NSInteger count = [self.dataSource candleCount];
    NSLog(@"Offset Candle: %f", offsetForCandles);
    if(count > self.indicatorValues.count) {
        NSMutableArray *appendingArray = [[NSMutableArray alloc] init];
        for(NSInteger i = self.indicatorValues.count; i<count; i++) {
            [appendingArray addObject:@{
                                        @"mid": @(-1.0),
                                        @"top": @(-1.0),
                                        @"bot": @(-1.0)
                                        }];
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
    CGContextSetStrokeColorWithColor(ctx, UIColor.greenColor.CGColor);
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
    
    CGContextSetStrokeColorWithColor(ctx, UIColor.redColor.CGColor);
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
    NSDictionary *dict = self.indicatorValues[index];
    NSNumber *mid = dict[@"mid"];
    if(mid.floatValue == -1.0) {
        if(index <= 20) {
            NSDictionary *dict = @{
                                   @"mid": @0.0,
                                   @"top": @0.0,
                                   @"bot": @0.0
                                   };
            [self.indicatorValues replaceObjectAtIndex:index withObject:dict];
            return dict;
        } else {
            //calculating sma
            float sma = 0.0;
            for(int i = index-19; i<=index; i++) {
                Tick *tick = [self.dataSource tickForIndex:i];
                sma += tick.close;
            }
            sma = sma/20.0;
            NSDictionary *dict = @{
                                   @"mid": @(sma),
                                   @"top": @0.0,
                                   @"bot": @0.0
                                   };
            [self.indicatorValues replaceObjectAtIndex:index withObject:dict];
            
            float deviation = [self standardDeviationForIndex:index];
            //calculating standard price deviation
            float topLine = sma + deviation * 2;
            float botLine = sma - deviation * 2;
            dict = @{
                                   @"mid": @(sma),
                                   @"top": @(topLine),
                                   @"bot": @(botLine)
                                   };
            [self.indicatorValues replaceObjectAtIndex:index withObject:dict];
        }
    }
    
    return dict;
}

-(float)standardDeviationForIndex:(NSInteger)index {
    NSRange range = NSMakeRange(index, 20);
    NSDictionary *dict = [self valueForIndex:index];
    float sma = [dict[@"mid"] floatValue];
    float deviation = 0.0;
    for(NSInteger i = index-19; i<=index; i++) {
        Tick *tick = [self.dataSource tickForIndex:i];
        float sum = tick.close - sma;
        deviation += sum * sum;
    }
    deviation = deviation/20.0;
    
    return sqrtf(deviation);
}


-(CGFloat)yPositionForValue:(float)value {
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
    for(NSDictionary *number in array) {
        if([number[@"top"] floatValue] > maxValue) maxValue = [number[@"top"] floatValue];
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
        for(NSDictionary *number in array) {
            if([number[@"bot"] floatValue] < minValue) minValue = [number[@"bot"] floatValue];
        }
    }
    return minValue;
}

@end
