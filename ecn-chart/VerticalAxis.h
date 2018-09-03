//
//  VerticalAxis.h
//  ecn-chart
//
//  Created by Stas Buldakov on 8/15/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
@class Graph;

NS_ASSUME_NONNULL_BEGIN

@interface VerticalAxis : CALayer

@property (weak, nonatomic) Graph *hostedGraph;
@property (assign, nonatomic) NSInteger majorTicksCount;
@property (assign, nonatomic) CGFloat globalAxisOffset;
@property (assign, nonatomic) CGFloat axisOffset;

@end

NS_ASSUME_NONNULL_END
