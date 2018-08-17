//
//  Graphic.h
//  ecn-chart
//
//  Created by Stas Buldakov on 8/15/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

typedef enum GraphicType : NSInteger {
    GraphicTypeMain = 0,
    GraphicTypeBottom
} GraphicType;

@class Graph;

NS_ASSUME_NONNULL_BEGIN

@interface Graphic : CALayer

@property (weak, nonatomic) Graph *hostedGraph;

-(NSDecimalNumber *)minValue;
-(NSDecimalNumber *)maxValue;
-(CGFloat)yPositionForValue:(float)value;

//need to implement in subclasses
-(GraphicType)graphicType;

@end

NS_ASSUME_NONNULL_END
