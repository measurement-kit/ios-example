# Barebone Measurement Kit iOS app

⚠️⚠️⚠️⚠️⚠️⚠️⚠️: unused and archived repository!

Instructions for building the experimental barebone [Measurement
Kit](https://github.com/measurement-kit) (MK) iOS app with support
for the [NDT network performance test](
https://github.com/ndt-project/ndt/).

This app will run the MultiNdt test of MK, a network performance test
aiming at measuring the download speed of your network connection using
a single stream download based on the NDT network performance tests.

## Dependencies

You need to have [Carthage](https://github.com/Carthage/Carthage) installed and
obviously also [Xcode](https://developer.apple.com/xcode/) installed.

## Build procedure

Open the Terminal and run the following commands. They would download and
cross compile [MK](https://github.com/measurement-kit/measurement-kit) for
iOS devices, as well as other dependencies, and open the Xcode workspace
where the app, MK, and said depeendencies would be compiled.

```
carthage update
open measurement-kit-test.xcodeproj
```

## Updating to a new version of MK

To update to a new version of MeasurementKit, just run `carthage update`
again. We use a Carthage file always referencing the latest release.

## Known bugs

Sometimes, during the upload test, the app receives the `SIGPIPE` Unix
signal. MK code correctly handles this signal. But, when the app is run
attached to the debugger, the debugger will nonetheless pause upon the
receipt of such signal. My suggestion is to instruct Xcode to run the
app on a device and then, once the app is installed on device, disconnect
the device from your computer and run from device.
