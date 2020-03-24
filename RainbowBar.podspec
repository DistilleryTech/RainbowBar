#
# Be sure to run `pod lib lint RainbowBar.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RainbowBar'
  s.version          = '0.2.0'
  s.summary          = 'Progress bar for notched status bar.'

  s.description      = <<-DESC
  Progress bar with wild animation for notched status bar. Automatic sizing (height and notch curves) according to device model. Powered by SwiftUI and Combine. Made just for fun and SwiftUI practice) Inspired by https://dribbble.com/shots/3824870-Loading-Animation-for-iPhone-X
                       DESC

  s.homepage         = 'https://github.com/DistilleryTech/RainbowBar'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alex Kubarev' => 'a.kubarev@distillery.com' }
  s.source           = { :git => 'https://github.com/DistilleryTech/RainbowBar.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  s.source_files = 'RainbowBar/Classes/**/*'

  s.frameworks = 'SwiftUI', 'Combine'
  s.dependency 'DeviceKit', '~> 2.0'
end
