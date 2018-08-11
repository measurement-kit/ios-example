// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import "NetworkMeasurement.h"

#include <memory>

#import "measurement_kit/ffi.h"

// Serialize settings to JSON.
static NSString *marshal_settings(NSDictionary *settings) {
  NSString *serialized_settings = nil;
  NSError *error = nil;
  NSData *data = [NSJSONSerialization dataWithJSONObject:settings
                  options:0 error:&error];
  if (error != nil) {
    NSLog(@"Cannot serialize settings to JSON");
    return nil;
  }
  // Using initWithData because data is not terminated by zero.
  serialized_settings = [[NSString alloc] initWithData:data
                          encoding:NSUTF8StringEncoding];
  if (serialized_settings == nil) {
    NSLog(@"Cannot convert serialized JSON to string");
    return nil;
  }
  return serialized_settings;
}

static NSDictionary *wait_for_next_event(mk_unique_task &taskp) {
  mk_unique_event eventp{mk_task_wait_for_next_event(taskp.get())};
  if (!eventp) {
    NSLog(@"Cannot extract event");
    return nil;
  }
  const char *s = mk_event_serialize(eventp.get());
  if (s == nullptr) {
    NSLog(@"Cannot serialize event");
    return nil;
  }
  // Here it's important to specify freeWhenDone because we control
  // the lifecycle of the data object using `eventp`.
  NSData *data = [NSData dataWithBytesNoCopy:(void *)s length:strlen(s)
                  freeWhenDone:NO];
  NSError *error = nil;
  NSDictionary *evinfo = [NSJSONSerialization JSONObjectWithData:data
                          options:0 error:&error];
  if (error != nil) {
    NSLog(@"Cannot parse serialized JSON event");
    return nil;
  }
  return evinfo;
}

@implementation NetworkMeasurement

+(void) run:(BOOL)verbose {
  // Note: the emulator does not cope well with receiving
  // a signal of type SIGPIPE when the debugger is attached
  // See http://stackoverflow.com/questions/1294436

  // Serialize the settings to a JSON string.
  NSBundle *bundle = [NSBundle mainBundle];
  NSDictionary *settings = @{
    @"log_level": (verbose) ? @"DEBUG" : @"INFO",
    @"name": @"Ndt",
    @"options": @{
      @"geoip_country_path": [bundle pathForResource:@"GeoIP" ofType:@"dat"],
      @"geoip_asn_path": [bundle pathForResource:@"GeoIPASNum" ofType:@"dat"],
      @"no_file_report": @1,
    }
  };
  NSString *serialized_settings = marshal_settings(settings);
  if (serialized_settings == nil) {
    return;
  }
  //NSLog(@"settings: %@", serialized_settings); // Uncomment when debugging

  // The task runs in a background thread.
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      mk_unique_task taskp{mk_nettest_start([serialized_settings UTF8String])};
      while (!mk_task_is_done(taskp.get())) {
        // Extract an event from the task queue and unmarshal it.
        NSDictionary *evinfo = wait_for_next_event(taskp);
        if (evinfo == nil) {
          break;
        }
        // Notify the main thread about the latest event.
        dispatch_async(dispatch_get_main_queue(), ^{
          [[NSNotificationCenter defaultCenter]
            postNotificationName:@"event" object:nil userInfo:evinfo];
        });
      }
      // Notify the main thread that the task is now complete
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
          postNotificationName:@"test_complete" object:nil];
      });
  });
}

@end
