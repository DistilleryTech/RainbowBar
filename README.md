# RainbowBar

[![Language][lang-image]][lang-url]
[![License][license-image]][license-url]
[![Platform][platform-image]][cocoapod-url]
[![Pod Version][pod-version-image]][cocoapod-url]

Progress bar with wild animation for notched status bar

## Install

### CocoaPods

To integrate `RainbowBar` into your project add the following to your `Podfile`:

```ruby
platform :ios, '13.0'
use_frameworks!

pod 'Device.swift'
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
