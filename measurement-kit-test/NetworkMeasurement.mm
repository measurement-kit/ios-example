// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import "NetworkMeasurement.h"

#import "measurement_kit/common.hpp"

#include <arpa/inet.h>
#include <ifaddrs.h>
#include <resolv.h>
#include <dns.h>

static void setup_idempotent() {
    static bool initialized = false;
    if (!initialized) {

        // Set the logger verbose and make sure it logs on the "logcat"
        mk::set_verbosity(1);
        // XXX Ok to call NSLog() from another thread?
        mk::on_log([](uint32_t, const char *s) {
            NSLog(@"%s", s);
        });

        // Remember that we have initialized
        initialized = true;
    }
}

@implementation NetworkMeasurement

-(id) init {
    self = [super init];
    self.logLines = [[NSMutableArray alloc] init];
    self.finished = FALSE;
    return self;
}

-(void) run {
    // Nothing to do here
}

-(NSString*) getDate{
    NSDateFormatter *dateformatter=[[NSDateFormatter alloc]init];
    [dateformatter setDateFormat:@"dd-MM-yyyy HH:mm:ss"];
    return [dateformatter stringFromDate:[NSDate date]];
}


@end


@implementation DNSInjection : NetworkMeasurement

-(id) init {
    self = [super init];
    self.name = @"dns_injection";
    return self;
}

- (void) run {
    setup_idempotent();
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:@"hosts" ofType:@"txt"];
    mk::ooni::DnsInjectionTest()
        .set_backend("8.8.8.8:53")
        .set_input_file_path([path UTF8String])
        .set_verbosity(1)
        .on_log([self](uint32_t, const char *s) {
            NSString *current = [NSString stringWithFormat:@"%@: %@", [super getDate], [NSString stringWithUTF8String:s]];
            NSLog(@"%s", s);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.logLines addObject:current];
            });
        })
        .run([self]() {
            NSLog(@"dns_injection testEnded");
            dispatch_async(dispatch_get_main_queue(), ^{
                self.finished = TRUE;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshLog" object:nil];
            });
        });
}


@end

@implementation HTTPInvalidRequestLine : NetworkMeasurement

-(id) init {
    self = [super init];
    self.name = @"http_invalid_request_line";
    return self;
}

-(void) run {
    setup_idempotent();
    mk::ooni::HttpInvalidRequestLineTest()
    .set_backend("http://www.google.com/")
    .set_verbosity(1)
    .set_options("dns/nameserver", "8.8.8.1")
    .on_log([self](uint32_t, const char *s) {
        // XXX OK to send messages to object from another thread?
        NSString *current = [NSString stringWithFormat:@"%@: %@", [super getDate],
                             [NSString stringWithUTF8String:s]];
        NSLog(@"%s", s);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.logLines addObject:current];
        });
    })
    .run([self]() {
        NSLog(@"http_invalid_request_line testEnded");
        dispatch_async(dispatch_get_main_queue(), ^{
            self.finished = TRUE;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshLog" object:nil];
        });
    });
}

@end

@implementation TCPConnect : NetworkMeasurement

-(id) init {
    self = [super init];
    self.name = @"tcp_connect";
    return self;
}

-(void) run {
    setup_idempotent();

    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:@"hosts" ofType:@"txt"];

    mk::ooni::TcpConnectTest()
    .set_port("80")
    .set_input_file_path([path UTF8String])
    .set_verbosity(1)
    .set_options("dns/nameserver", "8.8.8.1")
    .on_log([self](uint32_t, const char *s) {
        NSString *current = [NSString stringWithFormat:@"%@: %@", [super getDate],
                             [NSString stringWithUTF8String:s]];
        NSLog(@"%s", s);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.logLines addObject:current];
        });
    })
    .run([self]() {
        NSLog(@"tcp_connect testEnded");
        dispatch_async(dispatch_get_main_queue(), ^{
            self.finished = TRUE;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshLog" object:nil];
        });
    });
}

@end
