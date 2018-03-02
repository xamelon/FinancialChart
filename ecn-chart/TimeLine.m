//
//  TimeLine.m
//  ecn-chart
//
//  Created by Stas Buldakov on 30.11.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import "TimeLine.h"
#import "GraphicHost.h"
#import "Candle.h"

const float lineHeight = 5.0;


@implementation TimeLine

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    /* CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextMoveToPoint(context, 0, rect.size.height-10);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height-10);
    int cols = self.frame.size.width / 24.0;
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    for(int x = 1; x<cols; x=x+2) {
        CGContextMoveToPoint(context, x*24, self.frame.size.height-10);
        CGContextAddLineToPoint(context, x*24, self.frame.size.height-10-lineHeight);
        NSDate *date = [NSDate date];
        if([self.dataSource respondsToSelector:@selector(dateAtPosition:)]) {
            date = [self.dataSource dateAtPosition:x*24];
        } 
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"HH:mm"];
        NSString *dateTxt = [df stringFromDate:date];;
        CGSize size = [dateTxt sizeWithAttributes:@{
                                                    NSFontAttributeName: [UIFont fontWithName:@"MuseoSansCyrl-500" size:8.0]
                                                    }];
        
        NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];
        
        [dateTxt drawAtPoint:CGPointMake((x*24) - size.width/2, self.frame.size.height - 10)
              withAttributes:@{
                               NSFontAttributeName: [UIFont fontWithName:@"MuseoSansCyrl-500" size:8.0],
                               NSForegroundColorAttributeName: [UIColor blackColor]
                               }];
    }
    CGContextStrokePath(context); */
}

@end
