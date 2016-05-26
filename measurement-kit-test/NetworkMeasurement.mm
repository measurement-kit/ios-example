// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import "NetworkMeasurement.h"
#import "measurement_kit/ndt.hpp"

@implementation NetworkMeasurement

-(id) init {
    self = [super init];
    self.logLines = [[NSMutableArray alloc] init];
    self.finished = false;
    return self;
}

-(void) run { /* to be overriden */ }

@end

@implementation NdtTest : NetworkMeasurement

-(id) init {
    self = [super init];
    self.name = @"ndt";
    return self;
}

-(void) run {
    // Note: the emulator does not cope well with receiving
    // a signal of type SIGPIPE when the debugger is attached
    // See http://stackoverflow.com/questions/1294436

    mk::ndt::NdtTest()
        .set_options("mlabns/base_url", "http://mlab-ns.appspot.com/")
        .set_options("test_suite", MK_NDT_DOWNLOAD)
        .set_verbosity(MK_LOG_INFO)
        .on_log([self](uint32_t, const char *s) {
            NSString *current = [NSString stringWithFormat:@"%@",
                                 [NSString stringWithUTF8String:s]];
            //NSLog(@"%s", s);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.logLines addObject:current];
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"refreshLog" object:nil];
            });
        })
        .set_options("dns/nameserver", "8.8.8.8")
        .run([self]() {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.finished = TRUE;
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"testComplete" object:nil];
            });
        });
}

@end
