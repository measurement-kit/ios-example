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
    self.title = @"TEST";
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(refreshTestLogs:) name:@"refreshTestLogs"
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(testComplete) name:@"testComplete"
     object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)runTest:(id)sender{
    [self.runButton setEnabled:NO];
    [self.testLogs setText:@""];
    self.selectedMeasurement = [[NdtTest alloc] init];
    [self.selectedMeasurement run];
}

-(void)refreshTestLogs:(NSNotification *)notification{
    NSString *log = [notification object];
    log = [log stringByAppendingString:@"\n"];
    self.testLogs.text = [[self.testLogs text] stringByAppendingString:log];
}


-(void)testComplete{
    [self.runButton setEnabled:YES];
}

@end
