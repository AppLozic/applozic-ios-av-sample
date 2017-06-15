//
//  ALNavigationController.h
//  Applozic
//
//  Created by Adarsh Kumar Mishra on 12/7/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface ALNavigationController : UINavigationController

-(void)customNavigationItemClicked:(id)sender withTag:(NSString*)tag;

-(UIView*)getCustomButtonView:(NSString*)tag;

-(NSMutableArray*)getCustomButtons;

@end
