// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import "NetworkMeasurement.h"

#import "measurement_kit/nettest.hpp"

// You can write less by using a `using namespace` declaration.
using namespace mk::nettest;

// Specialize Nettest to route the events you care about. Since all tests
// run as Nettest, you do not need to specialize a class per test.
class NettestRouter : public Nettest {
 public:
  using Nettest::Nettest;

  // Properly route information regarding percentage of completion
  void on_status_progress(StatusProgressEvent event) override {
    NSDictionary *user_info = @{
      @"percentage": [NSNumber numberWithDouble:event.percentage],
      @"message": [NSString stringWithUTF8String:event.message.data()]
    };
    // Route event to the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter]
        postNotificationName:@"update_progress"
        object:nil userInfo:user_info];
    });
  }

  // Properly route performance events
  void on_status_update_performance(StatusUpdatePerformanceEvent event) override {
    NSDictionary *user_info = @{
      @"speed": [NSNumber numberWithDouble:event.speed_kbps],
      @"speed_unit": @"kbit/s",
      @"elapsed": [NSNumber numberWithDouble:event.elapsed],
      @"elapsed_unit": @"s",
    };
    // Route event to the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter]
        postNotificationName:@"update_speed"
        object:nil userInfo:user_info];
    });
  }

  // Properly route generic log messages emitted during the test
  void on_log(LogEvent event) override {
    NSDictionary *user_info = @{
      @"message": [NSString stringWithUTF8String:event.message.data()],
      @"log_level": [NSString stringWithUTF8String:event.log_level.data()]
    };
    // Route event to the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter]
        postNotificationName:@"update_logs"
        object:nil userInfo:user_info];
    });
  }

  // Properly route function containing structured test results
  void on_measurement(MeasurementEvent event) override {
    NSDictionary *user_info = @{
      @"entry": [NSString stringWithUTF8String:event.json_str.data()]
    };
    // Route event to the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter]
        postNotificationName:@"update_json"
        object:nil userInfo:user_info];
    });
  }
};

@implementation NetworkMeasurement

+(void) run:(BOOL)verbose {
  // Note: the emulator does not cope well with receiving
  // a signal of type SIGPIPE when the debugger is attached
  // See http://stackoverflow.com/questions/1294436

  // Create nettest specific settings and configure them.
  mk::nettest::NdtSettings config;
  // GeoIP files used to infer country and ISP ASNum
  config.geoip_country_path = [[[NSBundle mainBundle] pathForResource:@"GeoIP"
                              ofType:@"dat"] UTF8String];
  config.geoip_asn_path = [[[NSBundle mainBundle] pathForResource:@"GeoIPASNum"
                          ofType:@"dat"] UTF8String];
  // In production MK_LOG_INFO is recommended
  config.log_level = (verbose) ? mk::nettest::log_level_debug
                               : mk::nettest::log_level_info;
  // Make sure we are not going to write any file on the disk
  config.no_file_report = true;

  // Submit the job of running the nettest on a background queue.
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NettestRouter nettest{config};
      nettest.run();
      // Notify the main thread that we are now complete
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
          postNotificationName:@"test_complete" object:nil];
        });
    });
}

@end
