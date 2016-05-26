// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import <Foundation/Foundation.h>

@interface NetworkMeasurement : NSObject

@property NSString *name;
@property NSNumber *test_id;
@property NSString *status;
@property BOOL finished;
@property NSMutableArray *logLines;

-(void) run;

@end

@interface NdtTest : NetworkMeasurement
@end
