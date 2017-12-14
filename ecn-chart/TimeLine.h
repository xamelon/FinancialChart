//
//  TimeLine.h
//  ecn-chart
//
//  Created by Stas Buldakov on 30.11.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GraphicHost;

@protocol TimeLineDataSource <NSObject>

-(NSDate *)dateAtPosition:(CGFloat)x;

@end

@interface TimeLine : UIView

@property (weak, nonatomic) id <TimeLineDataSource> dataSource;

@end
