# Barebone MK iOS app

You need to have [CocoaPods](https://cocoapods.org/) installed and
obviously also [Xcode](https://developer.apple.com/xcode/) installed.

Open the Terminal and run the following commands. They would download and
cross compile [MK](https://github.com/measurement-kit/measurement-kit) for
iOS devices, as well as other dependencies, and open the Xcode workspace
where the app, MK, and said depeendencies would be compiled.

```
pod install
open measurement-kit-test.xcworkspace
```
