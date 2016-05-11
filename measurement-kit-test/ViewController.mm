//
//  ViewController.m
//  measurement-kit-test
//
//  Created by Lorenzo Primiterra on 11/05/16.
//  Copyright © 2016 Measurement kit. All rights reserved.
//

#import "ViewController.h"
#import "MBProgressHUD.h"

#include "measurement_kit/ooni.hpp"

#include "measurement_kit/common.hpp"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLog) name:@"refreshLog" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)runTest:(id)sender{
    [self.runButton setEnabled:NO];
    [self.logView setText:@""];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    int test = 1;
    if (test == 0){
        DNSInjection *dns_injectionMeasurement = [[DNSInjection alloc] init];
        self.selectedMeasurement = dns_injectionMeasurement;
    }
    else if (test == 1) {
        TCPConnect *tcp_connectMeasurement = [[TCPConnect alloc] init];
        self.selectedMeasurement = tcp_connectMeasurement;
    }
    else if (test == 2){
        HTTPInvalidRequestLine *http_invalid_request_lineMeasurement = [[HTTPInvalidRequestLine alloc] init];
        self.selectedMeasurement = http_invalid_request_lineMeasurement;
    }
    [self.selectedMeasurement run];
}

-(void)refreshLog{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self.runButton setEnabled:YES];
    [self.logView setText:[[self.selectedMeasurement logLines] componentsJoinedByString:@"\n"]];
}

@end
