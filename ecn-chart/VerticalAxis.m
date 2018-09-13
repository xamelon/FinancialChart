//
//  VerticalAxis.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/15/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "VerticalAxis.h"
#import <UIKit/UIKit.h>
#import "Graph.h"

@interface VerticalAxis() {
    NSInteger ticksCount;
    
}

@property (strong, nonatomic) NSNumberFormatter *nf;

@end

@implementation VerticalAxis

-(id)init {
    self = [super init];
    if(self) {
        self.backgroundColor = [UIColor clearColor].CGColor;
        self.contentsScale = [UIScreen mainScreen].scale;
        self.shouldRasterize = NO;
        self.rasterizationScale = [UIScreen mainScreen].scale;
    }
    return self;
}

-(id<CAAction>)actionForKey:(nonnull NSString *)aKey
{
    return nil;
}

-(void)drawInContext:(CGContextRef)ctx {
    if(self.majorTicksCount == 0) {
        ticksCount = (self.frame.size.height / cellSize) + 1;
    } else {
        ticksCount = self.majorTicksCount;
    }
    CGContextSetLineWidth(ctx, 1.0);
    NSDecimalNumber *minValue = [self.hostedGraph minValue];
    NSDecimalNumber *maxValue = [self.hostedGraph maxValue];
    
    CGFloat rowHeight = self.frame.size.height / ticksCount;
    NSString *minPriceWidth = [[self.hostedGraph.dataSource numberFormatter] stringFromNumber:maxValue];
    CGSize size = [minPriceWidth sizeWithAttributes:@{
                                                      NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:10.0]
                                                      }];
    
    CGFloat usingAxisOffset = self.axisOffset;
    if(self.globalAxisOffset > 0.0) {
        usingAxisOffset = self.globalAxisOffset;
    }
    
    if([maxValue isEqual:[NSDecimalNumber decimalNumberWithString:@"0.0"]]) {
        usingAxisOffset = 0.0;
        self.axisOffset = 0.0;
    }
    
    CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor.CGColor);
    CGContextMoveToPoint(ctx, self.frame.size.width - usingAxisOffset, 0);
    CGContextAddLineToPoint(ctx, self.frame.size.width - usingAxisOffset, self.frame.size.height);
    
    UIGraphicsPushContext(ctx);
    CGContextStrokePath(ctx);
    for(int y = 1; y<ticksCount; y++) {
        CGContextMoveToPoint(ctx, self.frame.size.width-usingAxisOffset-3, y*rowHeight);
        CGContextAddLineToPoint(ctx, self.frame.size.width-usingAxisOffset+3, y*rowHeight);
        float price = [self calculatePriceForY:y*rowHeight minValue:minValue.floatValue maxValue:maxValue.floatValue];
        NSString *priceText = [[self.hostedGraph.dataSource numberFormatter] stringFromNumber:[[NSDecimalNumber alloc] initWithFloat:price]];
        UIGraphicsPushContext(ctx);
        [priceText drawAtPoint:CGPointMake(self.frame.size.width-usingAxisOffset+6, y*rowHeight - size.height/2.0)
                withAttributes:@{
                                 NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:10.0]
                                 }];
        UIGraphicsPopContext();
    }
    CGContextStrokePath(ctx);
    
    CGContextSetStrokeColorWithColor(ctx, UIColor.lightGrayColor.CGColor);
    for(int y = 0; y<ticksCount; y++) {
        CGContextMoveToPoint(ctx, 0, y*rowHeight);
        CGContextAddLineToPoint(ctx, self.frame.size.width-usingAxisOffset, y*rowHeight);
    }
    CGContextStrokePath(ctx);
    
}

-(float)calculatePriceForY:(float)y minValue:(float)minValue maxValue:(float)maxValue {
    float H = self.frame.size.height;
    float price = (-((y-self.hostedGraph.padding)/(H-self.hostedGraph.padding * 2)) + 1) * (maxValue - minValue) + minValue;
    return price;
}

-(CGFloat)axisOffset {
     NSDecimalNumber *maxValue = [self.hostedGraph maxValue];
    NSString *minPriceWidth = [[self.hostedGraph.dataSource numberFormatter] stringFromNumber:maxValue];
    CGSize size = [minPriceWidth sizeWithAttributes:@{
                                                      NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:10.0]
                                                      }];
    
    return size.width + 6.0;
}



@end
