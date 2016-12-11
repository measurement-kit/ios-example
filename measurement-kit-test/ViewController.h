// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import <UIKit/UIKit.h>
#import "NetworkMeasurement.h"

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UITextView *resultsJsonTextView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *runButton;
@property (strong, nonatomic) NetworkMeasurement *selectedMeasurement;

@end

