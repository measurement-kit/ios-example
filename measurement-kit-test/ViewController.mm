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
     addObserver:self selector:@selector(refreshLog) name:@"refreshLog"
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

-(void)refreshLog{
    [self.testLogs setText:[[self.selectedMeasurement logLines]
                           componentsJoinedByString:@"\n"]];
}

-(void)testComplete{
    [self.runButton setEnabled:YES];
    [self.testLogs setText:[[self.selectedMeasurement logLines]
                           componentsJoinedByString:@"\n"]];
}

@end
