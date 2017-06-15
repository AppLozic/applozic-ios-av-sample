//
//  ViewController.m
//  applozicdemo
//
//  Created by Devashish on 07/10/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
- (IBAction)buttonAction:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonAction:(id)sender {

    [self dismissViewControllerAnimated:YES completion:nil];
    
}

@end
