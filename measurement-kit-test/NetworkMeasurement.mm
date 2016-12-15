// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import "NetworkMeasurement.h"

#import "measurement_kit/nettests.hpp"

@implementation NetworkMeasurement

+(void) run {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *geoip_asn = [bundle pathForResource:@"GeoIPASNum" ofType:@"dat"];
    NSString *geoip_country = [bundle pathForResource:@"GeoIP" ofType:@"dat"];

    // Note: the emulator does not cope well with receiving
    // a signal of type SIGPIPE when the debugger is attached
    // See http://stackoverflow.com/questions/1294436

    mk::nettests::MultiNdtTest()

        // Set verbosity level such that we see what's happening but many
        // debugging related info isn't shown to the user
        .set_verbosity(MK_LOG_INFO)

        // Make sure we are not going to write any file on the disk
        .set_options("no_file_report", "1")

        // Properly route information regarding percentage of completion
        .on_progress([](double prog, const char *s) {
            NSString *os = [NSString stringWithFormat:@"[%.1f%%] %s",
                            prog * 100.0, s];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"update_logs" object:os];
            });
        })

        // Properly route structured events occurring during the test
        .on_event([self](const char *s) {
            nlohmann::json doc = nlohmann::json::parse(s);
            if (doc["type"] != "download-speed") {
                return;
            }
            double elapsed = doc["elapsed"][0];
            std::string elapsed_unit = doc["elapsed"][1];
            double speed = doc["speed"][0];
            std::string speed_unit = doc["speed"][1];
            NSString *os = [NSString stringWithFormat:@"%8.2f %s %10.2f %s\n",
                             elapsed, elapsed_unit.c_str(), speed,
                             speed_unit.c_str()];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"update_speed" object:os];
            });
        })

        // Properly route generic log messages emitted during the test
        .on_log([self](uint32_t /*type*/, const char *s) {
            NSString *os = [NSString stringWithUTF8String:s];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"update_logs" object:os];
            });
        })

        // GeoIP files used to infer country and ISP ASnum
        .set_options("geoip_country_path", [geoip_country UTF8String])
        .set_options("geoip_asn_path", [geoip_asn UTF8String])

        // Properly route function containing structured test results
        .on_entry([self](std::string s) {
            NSString *os = [NSString stringWithUTF8String:s.c_str()];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"update_json" object:os];
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
