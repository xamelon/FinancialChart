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

-(instancetype)init {
    self = [super init];
    if(self) {
        self.backgroundColor = [UIColor clearColor].CGColor;
        self.contentsScale = [UIScreen mainScreen].scale;
    }
    return self;
}


-(id<CAAction>)actionForKey:(nonnull NSString *)aKey
{
    return nil;
}

-(void)drawInContext:(CGContextRef)ctx {
    CGRect rect = self.frame;
    CGContextRef context = ctx;
    int cols = self.frame.size.width / cellSize;
    
    CGFloat candleWidth = [self.dataSource candleWidth];
    CGFloat offsetForCandles = [self.dataSource offsetForCandles] - candleWidth;
    NSInteger countOfTwoCells = [self.dataSource countOfTwoCells];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"HH:mm"];
    if(self.dataSource && [self.dataSource respondsToSelector:@selector(dateFormatter)]) {
        df = [self.dataSource dateFormatter];
    }
    
    //for saving current date drawed
    if(countOfTwoCells % 2 != 0) {
        offsetForCandles -= cellSize;
        cols++;
    }
    
    for(int x = 0; x<cols+1; x=x+2) {
        
        
        CGContextSetStrokeColorWithColor(context, UIColor.blackColor.CGColor);
        CGContextMoveToPoint(context, x*cellSize+offsetForCandles, self.frame.size.height-10);
        CGContextAddLineToPoint(context, x*cellSize+offsetForCandles, self.frame.size.height-10-lineHeight);
        CGContextStrokePath(context);
        NSDate *date;
        if([self.dataSource respondsToSelector:@selector(dateAtPosition:)]) {
            CGFloat position = x*cellSize +  countOfTwoCells*cellSize;
            if(countOfTwoCells % 2 == 0) {
                position -= ([self.dataSource offsetForCandles] - candleWidth);
            } else {
                position += ([self.dataSource offsetForCandles] - candleWidth);
            }
            date = [self.dataSource dateAtPosition:position];
        }
        
        NSString *dateTxt = [df stringFromDate:date];;
        if(!date) {
            dateTxt = @"";
        }
        CGSize size = [dateTxt sizeWithAttributes:@{
                                                    NSFontAttributeName: [UIFont fontWithName:@"MuseoSansCyrl-500" size:8.0]
                                                    }];
        UIGraphicsPushContext(ctx);
        [dateTxt drawAtPoint:CGPointMake((x*cellSize + offsetForCandles) - size.width/2, self.frame.size.height - 10)
              withAttributes:@{
                               NSFontAttributeName: [UIFont fontWithName:@"MuseoSansCyrl-500" size:8.0],
                               NSForegroundColorAttributeName: [UIColor blackColor]
                               }];
        UIGraphicsPopContext();
        CGContextSetStrokeColorWithColor(context, UIColor.lightGrayColor.CGColor);
        CGContextMoveToPoint(context, x*cellSize+offsetForCandles, 0);
        CGContextAddLineToPoint(context, x*cellSize+offsetForCandles, self.frame.size.height-10);
        CGContextMoveToPoint(context, (x+1)*cellSize+offsetForCandles, 0);
        CGContextAddLineToPoint(context, (x+1)*cellSize+offsetForCandles, self.frame.size.height-10);
        CGContextStrokePath(context);
    }
    CGContextStrokePath(context);
    CGContextSetStrokeColorWithColor(context, UIColor.blackColor.CGColor);
    CGContextMoveToPoint(context, 0, rect.size.height-10);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height-10);
    CGContextStrokePath(context);
}


@end
