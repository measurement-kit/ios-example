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

    /* Note: this experiment is about comparing the performance of one and
       multiple streams using the same server; this is why the server address
       has been explicitly provided below */

    // TODO: we should probably use the device's nameserver, not 8.8.8.8

    mk::ndt::NdtTest()
        .set_options("test_suite", MK_NDT_DOWNLOAD | MK_NDT_DOWNLOAD_EXT)
        .set_verbosity(MK_LOG_INFO)
        .set_output_filepath([ofile UTF8String])
        .on_log([self](uint32_t type, const char *s) {
            NSString *current = [NSString stringWithFormat:@"%@",
                                 [NSString stringWithUTF8String:s]];
            if ((type & MK_LOG_JSON) != 0) {
                NSData *data = [current dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *values = [NSJSONSerialization
                                        JSONObjectWithData:data
                                        options:NSJSONReadingMutableContainers
                                        error:nil];
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"refreshHeader"
                 object:nil userInfo:values];

                NSString *type = [values objectForKey:@"type"];
                if ([type isEqualToString:@"download-speed"]) {
                    NSArray *speed_array = [values objectForKey:@"speed"];
                    NSNumber *speed_num = [speed_array objectAtIndex:0];
                    NSString *speed_unit = [speed_array objectAtIndex:1];
                    NSNumber *num_streams = [values objectForKey:@"num_streams"];
                    current = [NSString stringWithFormat:@"%@ [%@ conn]: %8.0f %@ ",
                               type, num_streams, [speed_num doubleValue],
                               speed_unit];
                } else {
                    // TODO: make final summary easier to read?
                }
                /* FALLTHROUGH */
            }
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
        // TODO: set here the specific testing server
        //.set_options("address", "neubot.mlab.mlab1.iad0t.measurement-lab.org")
        .on_entry([self](std::string s) {
            NSString *current = [NSString stringWithFormat:@"%@",
                                 [NSString stringWithUTF8String:s.c_str()]];
            // TODO: we should probably use the entry to populate
            // a result pane or something fancy...
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.logLines addObject:current];
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"refreshLog" object:nil];
            });
        })
        .run([self]() {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.finished = TRUE;
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"testComplete" object:nil];
            });
        });
}

@end
