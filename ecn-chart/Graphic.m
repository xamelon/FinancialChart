//
//  Graphic.m
//  ecn-chart
//
//  Created by Stas Buldakov on 01.02.18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "Graphic.h"
#import "Tick.h"

@interface Graphic()

@property (assign, nonatomic) CGFloat minValue;
@property (assign, nonatomic) CGFloat maxValue;


@end

@implementation Graphic

-(id)init {
    self = [super init];
    if(self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
 
-(void)drawRect:(CGRect)rect {
    CGFloat minValue = [self.dataSource getMinValue];
    CGFloat maxValue = [self.dataSource getMaxValue];
    NSInteger minCandle = [self.dataSource minCandle];
    NSInteger maxCandle = [self.dataSource maxCandle];
    CGFloat candleWidth = [self.dataSource candleWidth];
    NSInteger candleCount = [self.dataSource candleCount];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
    CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
    int j = 0;
    CGFloat offsetForCandles = [self.dataSource offsetForCandles];
    for(NSInteger i = minCandle; i<maxCandle; ++i) {
        Tick *tick = [self.dataSource tickForIndex:i];
        float currentX = candleWidth/2 + (2 * candleWidth * j++) + offsetForCandles;
        CGFloat y1 = 20+(self.frame.size.height-40) * (1 - (tick.open - minValue)/(maxValue - minValue));
        CGFloat y2 = 20+(self.frame.size.height-40) * (1 - (tick.close - minValue)/(maxValue - minValue));
        if(tick.open > tick.close) {
            CGContextSetRGBFillColor(context, 233.0/255.0, 77.0/255.0, 37.0/255.0, 1.0);
            CGContextSetRGBStrokeColor(context, 233.0/255.0, 77.0/255.0, 37.0/255.0, 1.0);
        } else {
            CGContextSetRGBFillColor(context, 20.0/255.0, 160.0/255.0, 66.0/255.0, 1.0);
            CGContextSetRGBStrokeColor(context, 20.0/255.0, 160.0/255.0, 66.0/255.0, 1.0);
        }
        CGFloat open = 20+(self.frame.size.height-40) * (1 - (tick.max - minValue)/(maxValue - minValue));
        CGFloat close = 20+(self.frame.size.height-40) * (1 - (tick.min - minValue)/(maxValue - minValue));
        CGRect rect1 = CGRectMake(currentX, MIN(y1, y2), candleWidth, fabs(y1-y2));
        CGContextFillRect(context, rect1);
        CGContextMoveToPoint(context, currentX + candleWidth/2, open);
        CGContextAddLineToPoint(context, currentX + candleWidth/2, close);
        CGContextStrokePath(context);
    }
}


@end