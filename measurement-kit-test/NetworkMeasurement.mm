// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import "NetworkMeasurement.h"

#include <memory>

#import "measurement_kit/ffi.h"

// XXX This should be part of the FFI API
namespace x {
class TaskDeleter {
  public:
    void operator()(mk_task_t *task) noexcept { mk_task_destroy(task); }
};
using TaskUptr = std::unique_ptr<mk_task_t, TaskDeleter>;

class EventDeleter {
  public:
    void operator()(mk_event_t *event) noexcept { mk_event_destroy(event); }
};
using EventUptr = std::unique_ptr<mk_event_t, EventDeleter>;
} // namespace x

@implementation NetworkMeasurement

+(void) run:(BOOL)verbose {
  // Note: the emulator does not cope well with receiving
  // a signal of type SIGPIPE when the debugger is attached
  // See http://stackoverflow.com/questions/1294436

  // Serialize the settings to a JSON string.
  NSString *serialized_settings = nil;
  {
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
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:settings
                    options:0 error:&error];
    if (error != nil) {
      NSLog(@"Cannot serialize settings to JSON");
      return;
    }
    // Using initWithData because data is not terminated by zero.
    serialized_settings = [[NSString alloc] initWithData:data
                           encoding:NSUTF8StringEncoding];
    if (serialized_settings == nil) {
      NSLog(@"Cannot convert serialized JSON to string");
      return;
    }
  }
  //NSLog(@"settings: %@", serialized_settings); // Uncomment when debugging

  // The task runs in a background thread.
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      x::TaskUptr taskp{mk_task_start([serialized_settings UTF8String])};
      while (!mk_task_is_done(taskp.get())) {
        // Extract an event from the task queue and unmarshal it.
        NSDictionary *evinfo = nil;
        {
          x::EventUptr eventp{mk_task_wait_for_next_event(taskp.get())};
          if (!eventp) {
            NSLog(@"Cannot extract event");
            break;
          }
          const char *s = mk_event_serialize(eventp.get());
          if (s == nullptr) {
            NSLog(@"Cannot serialize event");
            break;
          }
          // Here it's important to specify freeWhenDone because we control
          // the lifecycle of the data object using `eventp`.
          NSData *data = [NSData dataWithBytesNoCopy:(void *)s length:strlen(s)
                          freeWhenDone:NO];
          NSError *error = nil;
          evinfo = [NSJSONSerialization JSONObjectWithData:data
                    options:0 error:&error];
          if (error != nil) {
            NSLog(@"Cannot parse serialized JSON event");
            break;
          }
        }
        assert(evinfo != nil);
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
