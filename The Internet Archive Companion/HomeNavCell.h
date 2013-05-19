//
//  HomeNavCell.h
//  The Internet Archive Companion
//
//  Created by Hunter on 2/9/13.
//  Copyright (c) 2013 Hunter Lee Brown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"

@interface HomeNavCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet AsyncImageView *navImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sectionCellBackground;
@property (weak, nonatomic) IBOutlet UIImageView *plainCellBackground;

@end
