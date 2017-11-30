//
//  TilingView.m
//  trading-chart
//
//  Created by Stas Buldakov on 09.11.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import "TilingView.h"


@implementation TilingView

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context, rect);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.0 alpha:0.2].CGColor);
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = 1.0;
    int rows = self.frame.size.width / 24;
    int cols = self.frame.size.height / 24;
    for(int x = 0; x<rows; x++) {
        for(int y = 0; y<cols; y++) {
            [path moveToPoint:CGPointMake((x+1)*24, 0)];
            [path addLineToPoint:CGPointMake((x+1)*24, self.frame.size.height)];
            [path moveToPoint:CGPointMake(0, (y+1)*24)];
            [path addLineToPoint:CGPointMake(self.frame.size.width, (y+1)*24)];
        }
    }
    [path closePath];
    [path stroke];
    
    CGContextStrokePath(context);
}



@end
