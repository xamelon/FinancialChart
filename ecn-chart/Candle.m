//
//  Candle.m
//  trading-chart
//
//  Created by Stas Buldakov on 03.11.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import "Candle.h"
#import "Tick.h"

@implementation Candle {
    float maxHost;
    float minHost;
}

-(id)initWithMax:(float)max min:(float)min candle:(Tick *)candle frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.max = candle.max;
        self.min = candle.min;
        self.open = candle.open;
        self.close = candle.close;
        self.date = [NSDate dateWithTimeIntervalSince1970:candle.date];
        maxHost = max;
        minHost = min;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGFloat top = 20+(rect.size.height-40) * (1 - (self.close - minHost)/(maxHost - minHost));
    CGFloat bot = 20+(rect.size.height-40) * (1 - (self.open - minHost)/(maxHost - minHost));
    
    CGFloat open = 20+(rect.size.height-40) * (1 - (self.max - minHost)/(maxHost - minHost));
    CGFloat close = 20+(rect.size.height-40) * (1 - (self.min - minHost)/(maxHost - minHost));
    if(self.open < self.close) {
        CGContextSetRGBStrokeColor(context, (233.0/255.0), (77.0/255.0), (37.0/255.0), 1.0);
        CGContextSetRGBFillColor(context, (233.0/255.0), (77.0/255.0), (37.0/255.0), 1.0);
    } else {
        CGContextSetRGBStrokeColor(context, (20.0/255.0), (160.0/255.0), (66.0/255.0), 1.0);
        CGContextSetRGBFillColor(context, (20.0/255.0), (160.0/255.0), (66.0/255.0), 1.0);

    }
    CGContextSetLineWidth(context, 2.0);    
    CGContextMoveToPoint(context, rect.size.width/2, open);
    CGContextAddLineToPoint(context, rect.size.width/2, close);
    CGContextAddRect(context, CGRectMake(0, top, rect.size.width, bot-top));
    CGContextDrawPath(context,kCGPathFillStroke);
    CGContextFillPath(context);
}

@end
