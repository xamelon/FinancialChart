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

@interface SARIndicator()

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
    CGFloat candleWidth = [self.dataSource candleWidth];
    CGFloat offsetForCandles = [self.dataSource offsetForCandles];
    NSInteger count = [self.dataSource candleCount];
    NSLog(@"Offset Candle: %f", offsetForCandles);
    if(count > self.indicatorValues.count) {
        NSMutableArray *appendingArray = [[NSMutableArray alloc] init];
        for(int i = self.indicatorValues.count; i<count; i++) {
            [appendingArray addObject:@{
                                        @"sarValue": @(-1.0),
                                        @"af": @(0.02),
                                        @"risingTrend": @(YES),
                                        @"ep": @(0.0)
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
        float currentX = candleWidth + (2 * candleWidth * j) + offsetForCandles;
        float currentY = [self yPositionForIndex:i];
        CGContextAddEllipseInRect(ctx, CGRectMake(currentX-candleWidth/4.0, currentY-candleWidth/4.0, candleWidth/2.0, candleWidth/2.0));
        
        j++;
    }
    CGContextStrokePath(ctx);
    
    
}

-(NSDictionary *)valueForIndex:(NSInteger)index {
    NSDictionary *sarValue = self.indicatorValues[index];
    NSNumber *value = sarValue[@"sarValue"];
    if(value.floatValue == -1.0) {
        Tick *tick = [self.dataSource tickForIndex:index];
        if(index == 0) {
            NSDictionary *dict = @{
                                   @"sarValue": @(tick.min),
                                   @"af": @(0.02),
                                   @"ep": @(tick.max),
                                   @"risingTrend": @(YES)
                                   };
            [self.indicatorValues replaceObjectAtIndex:index withObject:dict];
            return dict;
        }
        NSDictionary *previousSar = [self valueForIndex:index-1];
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
        NSDictionary *dict = @{
                               @"sarValue": @(newSar),
                               @"af": @(af),
                               @"ep": @(previousEp),
                               @"risingTrend": @(trend)
                               };
        [self.indicatorValues replaceObjectAtIndex:index withObject:dict];
        return dict;
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

-(CGFloat)yPositionForIndex:(NSInteger)index {
    NSDictionary *value = [self valueForIndex:index];
    float sarValue = [value[@"sarValue"] floatValue];
    CGFloat minValue = [self.dataSource minValue];
    CGFloat maxValue = [self.dataSource maxValue];
    CGFloat y1 = 20+(self.frame.size.height-40) * (1 - (sarValue - minValue)/(maxValue - minValue));
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
        if([number[@"sarValue"] floatValue] > maxValue) maxValue = [number[@"sarValue"] floatValue];
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
            if([number[@"sarValue"] floatValue] < minValue) minValue = [number[@"sarValue"] floatValue];
        }
    }
    return minValue;
}

@end
