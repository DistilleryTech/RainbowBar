# RainbowBar

Progress bar with wild animation for notched status bar. Automatic sizing (height and notch curves) according to device model. Powered by SwiftUI and Combine. Made just for fun and SwiftUI practice) Inspired by https://dribbble.com/shots/3824870-Loading-Animation-for-iPhone-X 

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
           
animatedSignal.send(true)
```
