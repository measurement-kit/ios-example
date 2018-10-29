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
     addObserver:self selector:@selector(handle_event:)
     name:@"event" object:nil];

    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(test_complete)
     name:@"test_complete" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)runTest:(id)sender {
    /*
     * Note: after the test we will make the textViews editable to allow
     * the user to select all logs and share with us.
     */
    [self.runButton setEnabled:NO];
    [self.resultsJsonTextView setEditable:FALSE];
    [self.resultsJsonTextView setText:@"{}"];
    [self.logsTextView setEditable:FALSE];
    [self.logsTextView setText:@""];
    [NetworkMeasurement run:self.verboseSwitch.isOn];
}

-(void)handle_event:(NSNotification *)notification {
    NSDictionary *evinfo = [notification userInfo];
    if (evinfo == nil) {
        return;
    }
    //NSLog(@"Got event: %@", evinfo); // Uncomment when debugging
    NSString *key = [evinfo objectForKey:@"key"];
    NSDictionary *value = [evinfo objectForKey:@"value"];
    if (key == nil || value == nil) {
        return;
    }
    if ([key isEqualToString:@"log"]) {
        [self update_logs:value];
    } else if ([key isEqualToString:@"status.progress"]) {
        [self update_progress:value];
    } else if ([key isEqualToString:@"status.update.performance"]) {
        [self update_speed:value];
    } else if ([key isEqualToString:@"measurement"]) {
        [self update_json:value];
    } else {
        NSLog(@"unused event: %@", evinfo);
    }
}

-(void)do_update_logs:(NSString *)entry {
    self.logsTextView.text = [self.logsTextView.text
                              stringByAppendingString:[
                              entry stringByAppendingString:@"\n"]];
    [self.logsTextView
     scrollRangeToVisible:NSMakeRange([self.logsTextView.text
                                       length], 0)];
}

-(void)update_logs:(NSDictionary *)value {
    NSString *message = [value objectForKey:@"message"];
    if (message == nil) {
        return;
    }
    [self do_update_logs:message];
}

-(void)update_progress:(NSDictionary *)value {
    NSNumber *percentage = [value objectForKey:@"percentage"];
    NSString *message = [value objectForKey:@"message"];
    if (percentage == nil || message == nil) {
        return;
    }
    NSString *entry = [NSString stringWithFormat:@"[%.1f%%] %@",
                       [percentage doubleValue] * 100.0, message];
    [self do_update_logs:entry];
}

-(void)update_speed:(NSDictionary *)value {
    NSNumber *elapsed = [value objectForKey:@"elapsed"];
    NSNumber *speed = [value objectForKey:@"speed_kbps"];
    if (elapsed == nil || speed == nil) {
        return;
    }
    NSString *elapsed_unit = @"s";
    NSString *speed_unit = @"Kbit/s";
    self.statusLabel.text = [NSString stringWithFormat:@"%8.2f %@ %10.2f %@\n",
         [elapsed doubleValue], elapsed_unit, [speed doubleValue], speed_unit];
}

-(void)update_json:(NSDictionary *)value {
    NSString *entry = [value objectForKey:@"json_str"];
    if (entry == nil) {
        return;
    }
    [self.resultsJsonTextView setText:entry];
    [self.resultsJsonTextView
     scrollRangeToVisible:NSMakeRange([self.resultsJsonTextView.text
                                       length], 0)];
}

-(void)test_complete {
    [self.runButton setEnabled:YES];
    [self.resultsJsonTextView setEditable:TRUE];
    [self.logsTextView setEditable:TRUE];
}

@end
