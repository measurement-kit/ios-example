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
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *geoip_asn = [bundle pathForResource:@"GeoIPASNum" ofType:@"dat"];
    NSString *geoip_country = [bundle pathForResource:@"GeoIP" ofType:@"dat"];
    NSString *ca_cert = [bundle pathForResource:@"cacert" ofType:@"pem"];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *docs_dir = [paths objectAtIndex:0];
    NSString *ofile = [NSString stringWithFormat:@"%@/output.json", docs_dir];

    // Note: the emulator does not cope well with receiving
    // a signal of type SIGPIPE when the debugger is attached
    // See http://stackoverflow.com/questions/1294436

    // XXX: MK_LOG_DEBUG2 sends app to deadlock?!

    mk::ndt::NdtTest()
        .set_options("test_suite", MK_NDT_DOWNLOAD)
        .set_verbosity(MK_LOG_INFO)
        .set_output_file_path([ofile UTF8String])
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
        .set_options("net/ca_bundle_path", [ca_cert UTF8String])
        .set_options("dns/nameserver", "8.8.8.8")
        .set_options("geoip_country_path", [geoip_country UTF8String])
        .set_options("geoip_asn_path", [geoip_asn UTF8String])
        .run([self]() {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.finished = TRUE;
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"testComplete" object:nil];
            });
        });
}

@end
