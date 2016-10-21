// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import "NetworkMeasurement.h"

#import "measurement_kit/ext.hpp"
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

    const char *servers[2] = {
        "neubot.mlab.mlab1.nuq0t.measurement-lab.org",
        "52.43.197.62",
    };
    static int previous_index = 0;
    const char *server_address = servers[previous_index++];
    if (previous_index > 1) {
        previous_index = 0;
    }

    mk::ndt::NdtTest()
        .set_options("test_suite", MK_NDT_DOWNLOAD | MK_NDT_DOWNLOAD_EXT)
        .set_verbosity(MK_LOG_INFO)
        .set_output_filepath([ofile UTF8String])

        // The https collector is currently broken and by default we use
        // another https collector that discards input. Set this one instead
        // such that I can see the results of tests run by you guys.
        //.set_options("collector_base_url", "http://a.collector.test.ooni.io")

        .on_log([self](uint32_t type, const char *s) {
            // Intercept log messages from MK and, in particular, process
            // those log messages formatted as JSON to print speed
            std::string sp = s;
            if ((type & MK_LOG_JSON) != 0) {
                try {
                    nlohmann::json root = nlohmann::json::parse(s);
                    if (root.at("type") == "download-speed") {
                        /*-
                         * For example:
                         *
                         * {
                         *   "type": "download-speed",
                         *   "elapsed": [8.863781, "s"],
                         *   "num_streams": 1,
                         *   "speed": [840.516366, "kbit/s"]
                         * }
                         */
                        double speed_num = root["speed"][0];
                        std::string speed_unit = root["speed"][1];
                        int num_streams = root["num_streams"];
                        std::string tmp = root["type"];
                        tmp += " [";
                        tmp += std::to_string(num_streams);
                        tmp += " conns]: ";
                        tmp += std::to_string(speed_num);
                        tmp += " ";
                        tmp += speed_unit;
                        sp = tmp;
                    } else if (root.find("progress") != root.end()) {
                        /*-
                         * For example:
                         *
                         * {
                         *    "progress": 0.33
                         * }
                         */
                        // Anyway not used by NDT currently
                    } else {
                        // Should not happen
                    }
                } catch (...) {
                    /* FALLTHROUGH */
                }
            }
            NSString *current = [NSString stringWithUTF8String:sp.c_str()];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.logLines addObject:current];
                [[NSNotificationCenter defaultCenter]
                    postNotificationName:@"refreshLog" object:nil];
            });
        })

        // Note: of course this works if we use Google's DNS but perhaps
        // it would be better to use instead the DNS of the device
        .set_options("dns/nameserver", "8.8.8.8")


        .set_options("net/ca_bundle_path", [ca_cert UTF8String])
        .set_options("geoip_country_path", [geoip_country UTF8String])
        .set_options("geoip_asn_path", [geoip_asn UTF8String])

        // In general NDT selects the server to use via the mlabns service
        // but in our specific case we need to select specific servers
        .set_options("address", server_address)

        .on_entry([self](std::string sp) {
            /*
             * Here we tap into the result of the test, a valid JSON that you
             * probably would also like to submit to your collector.
             *
             * The specific way in which the JSON is parsed depends on what
             * we want to extract from it. Here we're trying to do something
             * compatible with speedtest.net's data filtering.
             *
             * Minimal example:
             *
             * {
             *   "ext": {},
             *   "test_keys": {
             *     "test_s2c": [
             *       "connect_times": [ 0.1, 0.2, 0.1 ],
             *       "params": {
             *         "num_streams": 3
             *       },
             *       "receiver_data": [
             *         [123456789.012345, 117843.11]
             *       ]
             *     ],
             *   },
             *   "test_version": "0.0.4"
             * },
             *
             * Note that in receiver_data the first number is the elapsed
             * timestamp and the second is the speed in kbit/s. Connect times
             * are in seconds. There are more keys than this in the result.
             *
             * The code below creates a key named "plume" inside of "ext" and
             * fills it with summary experiments data.
             */
            try {
                nlohmann::json root = nlohmann::json::parse(sp);
                if (root["test_version"] == "0.0.4") {
                    for (auto &test_s2c: root["test_keys"]["test_s2c"]) {
                        // 1. find out test with three connections
                        int num_streams = test_s2c["params"]["num_streams"];
                        if (num_streams != 3) {
                            continue;
                        }
                        auto ext = nlohmann::json::object();
                        // 2. compute the ping
                        std::vector<double> rtts = test_s2c["connect_times"];
                        double sum = 0.0;
                        for (auto &x: rtts) { sum += x; }
                        double ping = 0.0;
                        if (rtts.size() > 0) {
                            ping = sum / rtts.size();
                        }
                        ext["plume"]["ping"] = ping;
                        // 3. compute the download (v1, can be improved!)
                        std::vector<double> speeds;
                        for (auto &x: test_s2c["receiver_data"]) {
                            speeds.push_back(x[1]);
                        }
                        std::sort(speeds.begin(), speeds.end());
                        std::vector<double> good_speeds(
                            // Note: going beyond vector limits would raise
                            // a std::length_error exception
                            speeds.begin() + 6, speeds.end() - 2
                        );
                        sum = 0.0;
                        for (auto &x: good_speeds) { sum += x; };
                        double download;
                        if (good_speeds.size() > 0) {
                            download = sum / good_speeds.size();
                        }
                        ext["plume"]["download"] = download;
                        // 3. upload (FIXME: still to be done)
                        // 4. extra info including vendor and versioning
                        ext["plume"]["num_streams"] = num_streams;
                        ext["plume"]["version"] = "0.0.1";
                        root["test_keys"]["ext"] = ext;
                        // 4. finally rewrite `sp`
                        sp = root.dump(4);
                    }
                } else {
                    // Conservative: we may not know how to handle this
                    // version of the NDT test (some fields may vary)
                }
            } catch (...) {
                // FALLTHROUGH
            }
            NSString *current = [NSString stringWithFormat:@"%@",
                                 [NSString stringWithUTF8String:sp.c_str()]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.logLines addObject:current];
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"refreshLog" object:nil];
            });
        })

        // This basically runs the test in a background MK thread and
        // calls the callback passed as argument when complete
        .run([self]() {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.finished = TRUE;
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"testComplete" object:nil];
            });
        });
}

@end
