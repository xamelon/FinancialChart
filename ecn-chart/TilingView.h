//
//  TilingView.h
//  trading-chart
//
//  Created by Stas Buldakov on 09.11.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GraphicDataSource;

@interface TilingView : UIView

@property (weak, nonatomic) id <GraphicDataSource> dataSource;

@end
