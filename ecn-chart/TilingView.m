//
//  TilingView.m
//  trading-chart
//
//  Created by Stas Buldakov on 09.11.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import "TilingView.h"
#import "GraphicHost.h"
#import "Graphic.h"

@implementation TilingView

-(id)init {
    self = [super init];
    if(self) {
        self.contentsScale = [UIScreen mainScreen].scale;
        self.allowsEdgeAntialiasing = NO;
    }
    return self;
}

-(__kindof CAAnimation *)animationForKey:(NSString *)key {
    return nil;
}


-(id<CAAction>)actionForKey:(nonnull NSString *)aKey
{
    return nil;
}

-(void)drawInContext:(CGContextRef)ctx {
    CGRect rect = self.frame;
    CGContextClearRect(ctx, rect);
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0.0 alpha:0.2].CGColor);
    CGContextSetLineWidth(ctx, 0.5);
    
    CGFloat candleWidth = [self.dataSource candleWidth];
    CGFloat offsetForCandles = [self.dataSource offsetForCandles] - candleWidth;
    
    int rows = self.frame.size.width / 24.0;
    int cols = self.frame.size.height / 24.0;
    for(int x = 0; x<rows; x++) {
        for(int y = 0; y<cols; y++) {
            CGContextMoveToPoint(ctx, (x+1)*24.0 + offsetForCandles, 0);
            CGContextAddLineToPoint(ctx, (x+1)*24.0 + offsetForCandles, self.frame.size.height);
            CGContextMoveToPoint(ctx, 0, (y+1)*24.0);
            CGContextAddLineToPoint(ctx, self.frame.size.width, (y+1)*24.0);
        }
    }
    
    CGContextStrokePath(ctx);
}





@end
