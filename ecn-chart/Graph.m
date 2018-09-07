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

@interface Graph() <CALayerDelegate> {
    float maxValue;
    float minValue;
    NSRange lastUsedRangeForMinValue;
    NSRange lastUsedRangeForMaxValue;
}

@property (strong, nonatomic) CALayer *descriptionLayer;

@end

@implementation Graph

-(id)init {
    self = [super init];
    if(self) {
        self.backgroundColor = [UIColor clearColor].CGColor;
        self.contentsScale = [UIScreen mainScreen].scale;
        self.shouldRasterize = NO;
        self.rasterizationScale = [UIScreen mainScreen].scale;
        self.graphics = [[NSMutableArray alloc] init];
        
        self.descriptionLayer = [[CALayer alloc] init];
        self.descriptionLayer.frame = CGRectMake(0, 0, 10, 10);
        self.descriptionLayer.contentsScale = [UIScreen mainScreen].scale;
        
        self.descriptionLayer.backgroundColor = [UIColor clearColor].CGColor;
        self.descriptionLayer.delegate = self;
        [self addSublayer:self.descriptionLayer];
        
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
        [self insertSublayer:self.verticalAxis below:self.descriptionLayer];
    }
    if([self.verticalAxis.superlayer isEqual:self]) {
        self.verticalAxis.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        [self.verticalAxis setNeedsDisplay];
    }
    CGFloat horizontalOffset = 0.0;
    if(self.verticalAxis) {
        horizontalOffset = self.verticalAxis.globalAxisOffset + 5;
    }
    for(__kindof Graphic *graphic in self.graphics) {
        if(graphic.superlayer == nil) {
            [self insertSublayer:graphic above:self.verticalAxis];
        }
        
        graphic.frame = CGRectMake(0, 0, self.frame.size.width-horizontalOffset, self.frame.size.height);
        [graphic reloadData];
    }
    [self.descriptionLayer setNeedsDisplay];
    [self setNeedsDisplay]; 
}

-(NSDecimalNumber *)minValue {
    NSRange visibleRange = [self.dataSource currentVisibleRange];
    if(NSEqualRanges(visibleRange, lastUsedRangeForMinValue)) {
        return [[NSDecimalNumber alloc] initWithFloat:minValue];
    }
    lastUsedRangeForMinValue = visibleRange;
    minValue = HUGE_VALF;
    for(Graphic *graphic in self.graphics) {
        NSDecimalNumber *graphicMinValue = [graphic minValue];
        if(graphicMinValue.floatValue < minValue) minValue = graphicMinValue.floatValue;
    }
    return [[NSDecimalNumber alloc] initWithFloat:minValue];
}

-(NSDecimalNumber *)maxValue {
    NSRange visibleRange = [self.dataSource currentVisibleRange];
    if(NSEqualRanges(visibleRange, lastUsedRangeForMaxValue)) {
        return [[NSDecimalNumber alloc] initWithFloat:maxValue];
    }
    lastUsedRangeForMaxValue = visibleRange;
    maxValue = 0.0;
    for(Graphic *graphic in self.graphics) {
        NSDecimalNumber *graphicMaxValue = [graphic maxValue];
        if(maxValue < graphicMaxValue.floatValue) maxValue = graphicMaxValue.floatValue;
    }
    return [[NSDecimalNumber alloc] initWithFloat:maxValue];;
}

#pragma mark - CALayerDelegate
-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if([layer isEqual:self.descriptionLayer]) {
        __kindof Graphic *graphic = self.graphics.firstObject;
        NSString *description = [graphic description];
        if(description.length == 0) return;
        CGSize descriptionSize = [description sizeWithAttributes:@{
                                                                   NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:8.0]
                                                                   }];
        
        descriptionSize.height += 5;
        descriptionSize.width += 5;
        self.descriptionLayer.frame = CGRectMake(0, 0, descriptionSize.width, descriptionSize.height);
        
        CGContextSetLineWidth(ctx, 0.0);
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:0.0 green:(122.0/255.0) blue:1.0 alpha:1.0].CGColor);
        CGContextFillRect(ctx, CGRectMake(0, 0, descriptionSize.width, descriptionSize.height));
        UIGraphicsPushContext(ctx);
        [description drawAtPoint:CGPointMake(2.5, 2.5)
                  withAttributes:@{
                                   NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:8.0],
                                   NSForegroundColorAttributeName: [UIColor whiteColor]
                                   }];
        UIGraphicsPopContext();
        
    }
}

@end
