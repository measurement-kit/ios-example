// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import "ViewController.h"

@implementation ViewController

- (id)init {
    self = [super init];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(update_logs:)
     name:@"update_logs" object:nil];

    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(update_progress:)
     name:@"update_progress" object:nil];

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

- (IBAction)runTest:(id)sender {
    [self.runButton setEnabled:NO];
    [self.resultsJsonTextView setText:@"{}"];
    [self.logsTextView setText:@""];
    [NetworkMeasurement run:self.verboseSwitch.isOn];
}

-(void)update_logs:(NSNotification *)notification {
    NSString *entry = [[notification userInfo] objectForKey:@"message"];
    self.logsTextView.text = [self.logsTextView.text
                              stringByAppendingString:[
                              entry stringByAppendingString:@"\n"]];
    [self.logsTextView
     scrollRangeToVisible:NSMakeRange([self.logsTextView.text
                                       length], 0)];
}

-(void)update_progress:(NSNotification *)notification {
    NSDictionary *user_info = [notification userInfo];
    NSNumber *progress = [user_info objectForKey:@"percentage"];
    NSString *action = [user_info objectForKey:@"message"];
    self.statusLabel.text = [NSString stringWithFormat:@"[%.1f%%] %@",
                             [progress doubleValue] * 100.0, action];
}

-(void)update_speed:(NSNotification *)notification {
    NSDictionary *user_info = [notification userInfo];
    self.statusLabel.text =
        [NSString stringWithFormat:@"%8.2f %@ %10.2f %@\n",
         [[user_info objectForKey:@"elapsed"] doubleValue],
         [user_info objectForKey:@"elapsed_unit"],
         [[user_info objectForKey:@"speed"] doubleValue],
         [user_info objectForKey:@"speed_unit"]];
}

-(void)update_json:(NSNotification *)notification {
    NSString *entry = [[notification userInfo] objectForKey:@"entry"];
    [self.resultsJsonTextView setText:entry];
    [self.resultsJsonTextView
     scrollRangeToVisible:NSMakeRange([self.resultsJsonTextView.text
                                       length], 0)];
}

-(void)test_complete {
    [self.runButton setEnabled:YES];
}

@end
