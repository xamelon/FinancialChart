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
#import "Graphic.h"

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
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextMoveToPoint(context, 0, rect.size.height-10);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height-10);
    int cols = self.frame.size.width / 24.0;
    CGFloat candleWidth = [self.dataSource candleWidth];
    CGFloat offsetForCandles = [self.dataSource offsetForCandles] - candleWidth;
    NSInteger countOfTwoCells = [self.dataSource countOfTwoCells];
    
    //You SHOULD NOT change this code
    if(countOfTwoCells % 2 != 0) {
        offsetForCandles -= 24;
    }
    for(int x = 0; x<cols+1; x=x+2) {
        CGContextMoveToPoint(context, x*24 + offsetForCandles, self.frame.size.height-10);
        CGContextAddLineToPoint(context, x*24 + offsetForCandles, self.frame.size.height-10-lineHeight);
        NSDate *date = [NSDate date];
        if([self.dataSource respondsToSelector:@selector(dateAtPosition:)]) {
            CGFloat position = x*24 +  countOfTwoCells*24;
            if(countOfTwoCells % 2 == 0) {
                position -= ([self.dataSource offsetForCandles] - candleWidth);
            } else {
                position += ([self.dataSource offsetForCandles] - candleWidth);
            }
            date = [self.dataSource dateAtPosition:position];
        } 
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"HH:mm"];
        NSString *dateTxt = [df stringFromDate:date];;
        CGSize size = [dateTxt sizeWithAttributes:@{
                                                    NSFontAttributeName: [UIFont fontWithName:@"MuseoSansCyrl-500" size:8.0]
                                                    }];
        
        NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];
        
        [dateTxt drawAtPoint:CGPointMake((x*24 + offsetForCandles) - size.width/2, self.frame.size.height - 10)
              withAttributes:@{
                               NSFontAttributeName: [UIFont fontWithName:@"MuseoSansCyrl-500" size:8.0],
                               NSForegroundColorAttributeName: [UIColor blackColor]
                               }];
    }
    CGContextStrokePath(context);
    
}

@end
