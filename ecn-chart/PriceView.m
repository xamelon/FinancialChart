//
//  PriceView.m
//  ecn-chart
//
//  Created by Stas Buldakov on 01.12.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import "PriceView.h"
#import "QuoteHelper.h"

@interface PriceView() {
    CGPoint selectionPoint;
}

@property (strong, nonatomic) CAGradientLayer* gradientLayer;

@end

@implementation PriceView

-(instancetype)init {
    self = [super init];
    if(self) {
        
        self.backgroundColor = [UIColor clearColor].CGColor;
        self.contentsScale = [UIScreen mainScreen].scale;
        self.shouldRasterize = NO;
        CGFloat sizeForView = [self sizeForView];
        
    }
    return self;
}

-(__kindof CAAnimation *)animationForKey:(NSString *)key {
    return nil;
}

-(CGFloat)sizeForView {
    NSString *text;
    float price = [self.datasource priceForY:self.frame.size.height / 2];
    NSNumberFormatter *nf = [self.datasource numberFormatter];
    if(price != price) {
        text = @"";
    } else {
        text = [nf stringFromNumber:[QuoteHelper decimalNumberFromDouble:price]];
    }
    CGSize size = [text sizeWithAttributes:@{
                                             NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:9.0],
                                             }];
    return size.width + 15;
}

-(void)drawInContext:(CGContextRef)ctx {
    NSDate *date1 = [NSDate date];
    CGRect rect = self.frame;
    CGContextRef context = ctx;
    CGContextClearRect(context, rect);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    NSNumberFormatter *nf = [self.datasource numberFormatter];
    int rows = self.frame.size.height / cellSize;
    CGSize textSize = CGSizeZero;
    for(int y = 1; y<=rows; y++) {
       
        NSString *text = @"Price";
        if([self.datasource respondsToSelector:@selector(priceForY:)]) {
            float price = [self.datasource priceForY:(y*cellSize)];
            if(price != price) {
                text = @"";
            } else {
                text = [nf stringFromNumber:[QuoteHelper decimalNumberFromDouble:price]];
            }
        }
        
        CGSize size = [text sizeWithAttributes:@{
                                                 NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:8.0],
                                                 }];
        textSize = size;
        UIGraphicsPushContext(ctx);
        [text drawAtPoint:CGPointMake(rect.size.width - size.width - 5, (y*cellSize)-size.height/2)
           withAttributes:@{
                            NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:8.0],
                            NSForegroundColorAttributeName: [UIColor blackColor]
                            }];
        UIGraphicsPopContext();
        CGContextMoveToPoint(context, rect.size.width - size.width - 13, y*cellSize);
        CGContextAddLineToPoint(context, rect.size.width - size.width - 7, y*cellSize);
    }
    CGContextStrokePath(context);
    if(!CGPointEqualToPoint(selectionPoint, CGPointZero)) {
        
        NSString *text;
        float price = [self.datasource priceForY:selectionPoint.y];
        if(price != price) {
            text = @"";
        } else {
            text = [nf stringFromNumber:[QuoteHelper decimalNumberFromDouble:price]];;
        }
        CGSize size = [text sizeWithAttributes:@{
                                                 NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:9.0],
                                                 }];
        CGContextSetFillColorWithColor(context, [UIColor colorWithRed:(21.0/255.0) green:(126.0/255.0) blue:(251.0/255.0) alpha:1.0].CGColor);
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:(21.0/255.0) green:(126.0/255.0) blue:(251.0/255.0) alpha:1.0].CGColor);
        CGContextFillRect(context, CGRectMake(rect.size.width - size.width - 5, selectionPoint.y-1, 55, size.height + 5));
        UIGraphicsPushContext(ctx);
        [text drawAtPoint:CGPointMake(rect.size.width - size.width - 3, selectionPoint.y+1)
           withAttributes:@{
                            NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:9.0],
                            NSForegroundColorAttributeName: [UIColor whiteColor]
                            }];
        UIGraphicsPopContext();
        
    }
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextMoveToPoint(context, rect.size.width - textSize.width - 10, 0);
    CGContextAddLineToPoint(context, rect.size.width - textSize.width - 10, self.frame.size.height);
    
    CGContextStrokePath(context);
    
}

-(void)drawPriceInPoint:(CGPoint)point {
    selectionPoint = point;
    [self setNeedsDisplay];
}

-(NSString *)formatFloatToString:(float)num {
    NSNumber *number = [NSNumber numberWithFloat:num];
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    [nf setPositiveFormat:@"#.########*0"];
    [nf setUsesSignificantDigits:YES];
    [nf setMaximumSignificantDigits:9];
    [nf setAllowsFloats:YES];
    [nf setAlwaysShowsDecimalSeparator:YES];
    return [nf stringFromNumber:number];
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
