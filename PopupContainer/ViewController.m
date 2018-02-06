//
//  ViewController.m
//  PopupContainer
//
//  Created by Dalang on 2018/2/5.
//  Copyright © 2018年 Dalang. All rights reserved.
//

#import "ViewController.h"
#import "DLPopupContainer.h"
#import "PopView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(show)];
    [self.view addGestureRecognizer:tap];
    
}

- (void)show
{
    PopView *view = [[[NSBundle mainBundle] loadNibNamed:@"PopView" owner:nil options:nil] lastObject];
    DLPopupContainer *pop = [DLPopupContainer popupContainerWithContentView:view
                                                                   showType:DLPopupContainerShowTypeBounceIn
                                                                dismissType:DLPopupContainerDismissTypeBounceOut
                                                                   maskType:DLPopupContainerMaskTypeDarkBlur
                                             shouldDismissOnBackgroundTouch:YES
                                                shouldDismissOnContentTouch:NO];
    [pop showWithLayout:DLPopupContainerLayoutMake(DLPopupContainerHorizontalLayoutCenter, DLPopupContainerVerticalLayoutCenter) duration:5];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
