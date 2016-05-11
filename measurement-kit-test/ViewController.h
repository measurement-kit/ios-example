//
//  ViewController.h
//  measurement-kit-test
//
//  Created by Lorenzo Primiterra on 11/05/16.
//  Copyright © 2016 Measurement kit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkMeasurement.h"

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextView *logView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *runButton;
@property (strong, nonatomic) NetworkMeasurement *selectedMeasurement;

@end

