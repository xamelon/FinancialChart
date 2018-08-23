//
//  Graphic.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/15/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "Graphic.h"
#import <UIKit/UIKit.h>
#import "Graph.h"

@implementation Graphic

-(id)init {
    self = [super init];
    if(self) {
        self.backgroundColor = [UIColor clearColor].CGColor;
        self.contentsScale = [UIScreen mainScreen].scale;
        self.shouldRasterize = YES;
        self.rasterizationScale = [UIScreen mainScreen].scale;
        self.drawsAsynchronously = YES;
        
    }
    return self;
}

-(id<CAAction>)actionForKey:(nonnull NSString *)aKey
{
    if([aKey isEqualToString:@"contents"]) {
        return nil;
    }
    return [super actionForKey:aKey];
}

-(CGFloat)yPositionForValue:(float)value {
    CGFloat minValue = [self.hostedGraph minValue].floatValue;
    CGFloat maxValue = [self.hostedGraph maxValue].floatValue;
    CGFloat y1 = self.hostedGraph.padding+(self.frame.size.height-self.hostedGraph.padding * 2) * (1 - (value - minValue)/(maxValue - minValue));
    return y1;
}

-(CGFloat)xPositionForIteration:(NSInteger)iteration {
    CGFloat offsetForCandles = [self.hostedGraph.dataSource offsetForCandles];
    CGFloat candleWidth = [self.hostedGraph.dataSource candleWidth];
    CGFloat currentX = candleWidth + (2 * candleWidth * iteration) + offsetForCandles;
    return currentX;
}

@end
