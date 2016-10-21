// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import <UIKit/UIKit.h>
#import "NetworkMeasurement.h"

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *finalLogs;
@property (weak, nonatomic) IBOutlet UITextView *progressLogs;
@property (weak, nonatomic) IBOutlet UITextView *testLogs;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *runButton;
@property (strong, nonatomic) NetworkMeasurement *selectedMeasurement;

@end

