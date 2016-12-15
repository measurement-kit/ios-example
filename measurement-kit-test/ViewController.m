// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import "ViewController.h"

@interface ViewController ()
@end

@implementation ViewController

- (id)init {
    self = [super init];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Network speedt test";

    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(update_logs:)
     name:@"update_logs" object:nil];

    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(update_speed:)
     name:@"update_speed" object:nil];

    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(update_json:)
     name:@"update_json" object:nil];

    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(test_complete)
     name:@"test_complete" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)runTest:(id)sender{
    [self.runButton setEnabled:NO];
    [self.resultsJsonTextView setText:@"{}"];
    self.speedLabel.text = @"0.0 kbit/s";
    [NetworkMeasurement run];
}

-(void)update_logs:(NSNotification *)notification{
    NSString *log = [notification object];
    self.statusLabel.text = log;
}

-(void)update_speed:(NSNotification *)notification{
    NSString *log = [notification object];
    self.speedLabel.text = log;
}

-(void)update_json:(NSNotification *)notification{
    NSString *log = [notification object];
    [self.resultsJsonTextView setText:log];
    [self.resultsJsonTextView
     scrollRangeToVisible:NSMakeRange([self.resultsJsonTextView.text
                                       length], 0)];
}

-(void)test_complete{
    [self.runButton setEnabled:YES];
}

@end
