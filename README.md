# Barebone Measurement Kit iOS app

Instructions for building the experimental barebone [Measurement
Kit](https://github.com/measurement-kit/measurement-kit) (MK)
iOS app with support for the [NDT network performance
test](https://github.com/ndt-project/ndt/).

## Dependencies

You need to have [CocoaPods](https://cocoapods.org/) installed and
obviously also [Xcode](https://developer.apple.com/xcode/) installed.

In addition, you also need to have [GNUPG](https://www.gnupg.org/)
installed. This is used to verify binaries downloaded from GitHub for
integrity and authenticity. Binaries are signed by Simone Basso with
PGP key Id `7733D95B` and fingerprint `7388` `77AA` `6C82` `9F26` `A431`
`C5F4` `80B6` `9127` `7733` `D95B`. If you have [Homebrew](http://brew.sh/)
installed, you can install GNUPG (and specifically its newest incarnation
`gpg2`) by running this command in the terminal

    brew install gpg2

## Adding key used to sign binaries

For the build procedure to succeed, you need to add the key used to
sign binaries (mentioned above) to your GNUPG keyring. To this end, run
the following command in the terminal

    gpg2 --recv-keys 7733D95B

## Build procedure

Open the Terminal and run the following commands. They would download and
cross compile [MK](https://github.com/measurement-kit/measurement-kit) for
iOS devices, as well as other dependencies, and open the Xcode workspace
where the app, MK, and said depeendencies would be compiled.

```
pod install --verbose
open measurement-kit-test.xcworkspace
```

## Updating to a new version of MK

This app is based on the frequently updated `feature/ndt` branch of
Measurement Kit. Thus, it would make sense, from time to time, to
rebuild the app using a more up to date version of such branch. To
this end, you can try this procedure

1. close Xcode

2. get rid of `Podfile`, `Podfile.lock`, and `Pods`

3. follow the build procedure described above

## Known bugs

Sometimes, during the upload test, the app receives the `SIGPIPE` Unix
signal. MK code correctly handles this signal. But, when the app is run
attached to the debugger, the debugger will nonetheless pause upon the
receipt of such signal. My suggestion is to instruct Xcode to run the
app on a device and then, once the app is installed on device, disconnect
the device from your computer and run from device.
