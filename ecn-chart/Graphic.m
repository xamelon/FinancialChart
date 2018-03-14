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
    ChartType chartType =  [self.dataSource chartType];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
    CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
    
    int j = 0;
    CGFloat offsetForCandles = [self.dataSource offsetForCandles];
    for(NSInteger i = minCandle; i<maxCandle; i++) {
        Tick *tick = [self.dataSource tickForIndex:i];
        float currentX = candleWidth/2 + (2 * candleWidth * j++) + offsetForCandles;
        CGFloat open = 20+(self.frame.size.height-40) * (1 - (tick.open - minValue)/(maxValue - minValue));
        CGFloat close = 20+(self.frame.size.height-40) * (1 - (tick.close - minValue)/(maxValue - minValue));
        if(tick.open > tick.close) {
            CGContextSetRGBFillColor(context, 233.0/255.0, 77.0/255.0, 37.0/255.0, 1.0);
            CGContextSetRGBStrokeColor(context, 233.0/255.0, 77.0/255.0, 37.0/255.0, 1.0);
        } else {
            CGContextSetRGBFillColor(context, 20.0/255.0, 160.0/255.0, 66.0/255.0, 1.0);
            CGContextSetRGBStrokeColor(context, 20.0/255.0, 160.0/255.0, 66.0/255.0, 1.0);
        }
        CGFloat y1 = 20+(self.frame.size.height-40) * (1 - (tick.max - minValue)/(maxValue - minValue));
        CGFloat y2 = 20+(self.frame.size.height-40) * (1 - (tick.min - minValue)/(maxValue - minValue));
        if(chartType == ChartTypeLine) {
            if(i == minCandle) {
                CGContextMoveToPoint(context, currentX, open);
            }
            [self drawLine:open close:close y1:y1 y2:y2 currentX:currentX candleWidth:candleWidth context:context];
        } else if(chartType == ChartTypeCandle) {
             [self drawCandle:open close:close y1:y1 y2:y2 currentX:currentX candleWidth:candleWidth context:context];
        } else if(chartType == ChartTypeBar) {
            [self drawBar:open close:close y1:y1 y2:y2 currentX:currentX candleWidth:candleWidth context:context];
        }
        
    }
    CGContextStrokePath(context);
}

-(void)drawCandle:(CGFloat)open close:(CGFloat)close y1:(CGFloat)y1 y2:(CGFloat)y2 currentX:(CGFloat)currentX candleWidth:(CGFloat)candleWidth context:(CGContextRef)context  {
    CGRect rect1 = CGRectMake(currentX, MIN(open, close), candleWidth, fabs(open-close));
    CGContextFillRect(context, rect1);
    CGContextMoveToPoint(context, currentX + candleWidth/2, y1);
    CGContextAddLineToPoint(context, currentX + candleWidth/2, y2);
    CGContextStrokePath(context);
}

-(void)drawBar:(CGFloat)open close:(CGFloat)close y1:(CGFloat)y1 y2:(CGFloat)y2 currentX:(CGFloat)currentX candleWidth:(CGFloat)candleWidth context:(CGContextRef)context {
    CGContextSetLineWidth(context, 1);
    CGContextMoveToPoint(context, currentX - candleWidth/2, open);
    CGContextAddLineToPoint(context, currentX + candleWidth/2, open);
    CGContextMoveToPoint(context, currentX + candleWidth/2, y1);
    CGContextAddLineToPoint(context, currentX + candleWidth/2, y2);
    CGContextMoveToPoint(context, currentX + candleWidth/2, close);
    CGContextAddLineToPoint(context, currentX + candleWidth + candleWidth/2, close);
    CGContextStrokePath(context);
}

-(void)drawLine:(CGFloat)open close:(CGFloat)close y1:(CGFloat)y1 y2:(CGFloat)y2 currentX:(CGFloat)currentX candleWidth:(CGFloat)candleWidth context:(CGContextRef)context {
    CGContextAddLineToPoint(context, currentX, open);
    CGContextAddLineToPoint(context, currentX+candleWidth, close);
}

@end
