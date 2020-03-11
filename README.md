# RainbowBar

Progress bar with wild animation for notched status bar

![gif demo](https://github.com/DistilleryTech/RainbowBar/blob/master/demo.gif)

## Install

### CocoaPods

To integrate `RainbowBar` into your project add the following to your `Podfile`:

```ruby
platform :ios, '13.0'
use_frameworks!

pod 'RainbowBar'
```

## Usage

```swift
import SwiftUI
import Combine
import RainbowBar

var animatedSignal = PassthroughSubject<Bool, Never>()

RainbowBar(waveEmitPeriod: 0.3,
                       visibleWavesCount: 3,
                       waveColors: [.red, .green, .blue],
                       backgroundColor: .white,
                       animated: animatedSignal)
```
