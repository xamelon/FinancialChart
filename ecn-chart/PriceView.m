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
    CGContextMoveToPoint(context, rect.size.width - 12 - 25 - 5, 0);
    CGContextAddLineToPoint(context, rect.size.width - 12 - 25 - 5, self.frame.size.height);
    int rows = self.frame.size.height / 24;
    for(int y = 0; y<rows; y++) {
        CGContextMoveToPoint(context, rect.size.width - 8 - 25 - 5, y*24);
        CGContextAddLineToPoint(context, rect.size.width - 16 - 25 - 5, y*24);
        NSString *text = @"Price";
        if([self.datasource respondsToSelector:@selector(priceForY:)]) {
            CGFloat price = [self.datasource priceForY:(y*24)];
            text = [NSString stringWithFormat:@"%*.*f", [self lengthForFloat:price], [self precisionForFloat:price], price];
        }
        
        CGSize size = [text sizeWithAttributes:@{
                                                 NSFontAttributeName: [UIFont fontWithName:@"MuseoSansCyrl-500" size:8.0],
                                                 }];
        [text drawAtPoint:CGPointMake(rect.size.width - 12 - 25, (y*24)-size.height/2)
           withAttributes:@{
                            NSFontAttributeName: [UIFont fontWithName:@"MuseoSansCyrl-500" size:8.0],
                            NSForegroundColorAttributeName: [UIColor blackColor]
                            }];
    }
    
    CGContextStrokePath(context);
}

-(int)lengthForFloat:(float)number {
    int tort = (int)number;
    int numberLength = 0;
    do {
        numberLength++;
        tort /= 10;
    } while(tort);
    return numberLength;
}

-(int)precisionForFloat:(float)number {
    int precision = [self lengthForFloat:number];
    return 5-precision > 0 ? 5-precision : 0;
}



@end
