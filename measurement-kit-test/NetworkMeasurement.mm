// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import "NetworkMeasurement.h"

#import "measurement_kit/common.hpp"
#import "measurement_kit/common/nlohmann/json.hpp"
#import "measurement_kit/nettests.hpp"

@implementation NetworkMeasurement

+(void) run:(BOOL)verbose {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *geoip_asn = [bundle pathForResource:@"GeoIPASNum" ofType:@"dat"];
    NSString *geoip_country = [bundle pathForResource:@"GeoIP" ofType:@"dat"];

    // Note: the emulator does not cope well with receiving
    // a signal of type SIGPIPE when the debugger is attached
    // See http://stackoverflow.com/questions/1294436

    mk::nettests::NdtTest()

        // In production MK_LOG_INFO is recommended
        .set_verbosity((verbose) ? MK_LOG_DEBUG : MK_LOG_INFO)

        // Make sure we are not going to write any file on the disk
        .set_option("no_file_report", "1")

        // Properly route information regarding percentage of completion
        .on_progress([](double prog, const char *s) {
            NSDictionary *user_info = @{
                @"percentage": [NSNumber numberWithDouble:prog],
                @"message": [NSString stringWithUTF8String:s]
            };
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"update_progress"
                 object:nil userInfo:user_info];
            });
        })

        // Properly route structured events occurring during the test
        .on_event([self](const char *s) {
            /*
             * Note: `nlohmann::json` is part of measurement-kit. You can
             * perform parsing here without wondering too much about possible
             * exceptions because the caller would filter exceptions caused
             * e.g. by parsing JSON or accessing nonexistent JSON fields.
             */
            nlohmann::json doc = nlohmann::json::parse(s);
            double elapsed = doc["elapsed"][0];
            std::string elapsed_unit = doc["elapsed"][1];
            double speed = doc["speed"][0];
            std::string speed_unit = doc["speed"][1];
            NSDictionary *user_info = @{
                @"speed": [NSNumber numberWithDouble:speed],
                @"speed_unit": [NSString
                                stringWithUTF8String:speed_unit.c_str()],
                @"elapsed": [NSNumber numberWithDouble:elapsed],
                @"elapsed_unit": [NSString
                                  stringWithUTF8String:elapsed_unit.c_str()]
            };
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"update_speed"
                 object:nil userInfo:user_info];
            });
        })

        // Properly route generic log messages emitted during the test
        .on_log([self](uint32_t severity, const char *s) {
            NSDictionary *user_info = @{
                @"message": [NSString stringWithUTF8String:s],
                @"severity": [NSNumber numberWithLong:severity]
            };
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"update_logs"
                 object:nil userInfo:user_info];
            });
        })

        // GeoIP files used to infer country and ISP ASnum
        .set_option("geoip_country_path", [geoip_country UTF8String])
        .set_option("geoip_asn_path", [geoip_asn UTF8String])

        // Properly route function containing structured test results
        .on_entry([self](std::string s) {
            NSDictionary *user_info = @{
                @"entry": [NSString stringWithUTF8String:s.c_str()]
            };
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"update_json"
                 object:nil userInfo:user_info];
            });
        })

        // This basically runs the test in a background MK thread and
        // calls the callback passed as argument when complete
        .start([self]() {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"test_complete" object:nil];
            });
        });
}

@end
