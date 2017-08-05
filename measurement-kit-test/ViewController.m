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

-(void)do_update_logs:(NSString *)entry {
    self.logsTextView.text = [self.logsTextView.text
                              stringByAppendingString:[
                              entry stringByAppendingString:@"\n"]];
    [self.logsTextView
     scrollRangeToVisible:NSMakeRange([self.logsTextView.text
                                       length], 0)];

}

-(void)update_logs:(NSNotification *)notification {
    NSDictionary *user_info = [notification userInfo];
    if (user_info == nil) {
        return;
    }
    NSString *entry = [user_info objectForKey:@"message"];
    if (entry == nil) {
        return;
    }
    [self do_update_logs:entry];
}

-(void)update_progress:(NSNotification *)notification {
    NSDictionary *user_info = [notification userInfo];
    if (user_info == nil) {
        return;
    }
    NSNumber *progress = [user_info objectForKey:@"percentage"];
    if (progress == nil) {
        return;
    }
    NSString *action = [user_info objectForKey:@"message"];
    if (action == nil) {
        return;
    }
    NSString *entry = [NSString stringWithFormat:@"[%.1f%%] %@",
                       [progress doubleValue] * 100.0, action];
    [self do_update_logs:entry];
}

-(void)update_speed:(NSNotification *)notification {
    NSDictionary *user_info = [notification userInfo];
    if (user_info == nil) {
        return;
    }
    NSNumber *elapsed = [user_info objectForKey:@"elapsed"];
    NSString *elapsed_unit = [user_info objectForKey:@"elapsed_unit"];
    NSNumber *speed = [user_info objectForKey:@"speed"];
    NSString *speed_unit = [user_info objectForKey:@"speed_unit"];
    if (elapsed == nil || elapsed_unit == nil || speed == nil ||
        speed_unit == nil) {
        return;
    }
    self.statusLabel.text =
        [NSString stringWithFormat:@"%8.2f %@ %10.2f %@\n",
         [elapsed doubleValue], elapsed_unit, [speed doubleValue], speed_unit];
}

-(void)update_json:(NSNotification *)notification {
    NSDictionary *user_info = [notification userInfo];
    if (user_info == nil) {
        return;
    }
    NSString *entry = [user_info objectForKey:@"entry"];
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
