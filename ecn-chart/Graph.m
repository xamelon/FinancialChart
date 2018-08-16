//
//  Graph.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/15/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "Graph.h"
#import <UIKit/UIKit.h>
#import "Graphic.h"
#import "VerticalAxis.h"

@implementation Graph

-(id)init {
    self = [super init];
    if(self) {
        self.backgroundColor = [UIColor clearColor].CGColor;
        self.contentsScale = [UIScreen mainScreen].scale;
        self.shouldRasterize = NO;
        self.rasterizationScale = [UIScreen mainScreen].scale;
        self.graphics = [[NSMutableArray alloc] init];
        
    }
    return self;
}

-(id<CAAction>)actionForKey:(nonnull NSString *)aKey
{
    return nil;
}

-(void)drawInContext:(CGContextRef)ctx {
    if(self.topLineWidth > 0.0) {
        CGContextSetLineWidth(ctx, self.topLineWidth);
        CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor.CGColor);
        CGContextMoveToPoint(ctx, 0.0, 0.0);
        CGContextAddLineToPoint(ctx, self.frame.size.width, 0.0);
        CGContextStrokePath(ctx);
    }
}

-(void)reloadData {
    if(self.verticalAxis.superlayer == nil) {
        [self addSublayer:self.verticalAxis];
    }
    if([self.verticalAxis.superlayer isEqual:self]) {
        self.verticalAxis.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        [self.verticalAxis setNeedsDisplay];
    }
    CGFloat horizontalOffset = 0.0;
    if(self.verticalAxis) {
        horizontalOffset = self.verticalAxis.axisOffset + 5;
    }
    for(__kindof Graphic *graphic in self.graphics) {
        if(graphic.superlayer == nil) {
            [self addSublayer:graphic];
        }
        
        graphic.frame = CGRectMake(0, 0, self.frame.size.width-horizontalOffset, self.frame.size.height);
        [graphic setNeedsDisplay];
    }
    [self setNeedsDisplay]; 
}

-(NSDecimalNumber *)minValue {
    NSDecimalNumber *minValue = [NSDecimalNumber minimumDecimalNumber];
    for(Graphic *graphic in self.graphics) {
        NSDecimalNumber *graphicMinValue = [graphic minValue];
        if([minValue compare:graphicMinValue] == NSOrderedAscending) minValue = graphicMinValue;
    }
    return minValue;
}

-(NSDecimalNumber *)maxValue {
    NSDecimalNumber *maxValue = [NSDecimalNumber maximumDecimalNumber];
    for(Graphic *graphic in self.graphics) {
        NSDecimalNumber *graphicMaxValue = [graphic maxValue];
        if([maxValue compare:graphicMaxValue] == NSOrderedDescending) maxValue = graphicMaxValue;
    }
    return maxValue;
}

@end
