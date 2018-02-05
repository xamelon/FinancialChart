//
//  PriceView.m
//  ecn-chart
//
//  Created by Stas Buldakov on 01.12.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import "PriceView.h"

@interface PriceView()

@property (strong, nonatomic) CAGradientLayer* gradientLayer;

@end

@implementation PriceView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        
        self.backgroundColor = [UIColor clearColor];
        [self setUserInteractionEnabled:NO];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    NSDate *date1 = [NSDate date];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextMoveToPoint(context, 12, 0);
    CGContextAddLineToPoint(context, 12, self.frame.size.height);
    int rows = self.frame.size.height / 24;
    for(int y = 0; y<rows; y++) {
        CGContextMoveToPoint(context, 8, y*24);
        CGContextAddLineToPoint(context, 16, y*24);
        NSString *text = @"Price";
        if([self.datasource respondsToSelector:@selector(priceForY:)]) {
            CGFloat price = [self.datasource priceForY:(y*24)];
            NSLog(@"Price: %f", price);
            text = [NSString stringWithFormat:@"%f", price];
        }
        
        CGSize size = [text sizeWithAttributes:@{
                                                 NSFontAttributeName: [UIFont fontWithName:@"MuseoSansCyrl-500" size:8.0],
                                                 }];
        [text drawAtPoint:CGPointMake(17, (y*24)-size.height/2)
           withAttributes:@{
                            NSFontAttributeName: [UIFont fontWithName:@"MuseoSansCyrl-500" size:8.0],
                            NSForegroundColorAttributeName: [UIColor blackColor]
                            }];
    }
    
    CGContextStrokePath(context);
    NSLog(@"Time interval: %f",[[NSDate date] timeIntervalSinceDate:date1]);
    NSLog(@"End");
}


@end
