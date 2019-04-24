#
# Be sure to run `pod lib lint MethodAspects.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MethodAspects'
  s.version          = '0.1.0'
  s.summary          = '切面编程'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
相比Aspects增加几点功能：类方法和实例方法可同时进行拦截，方法拦截可根据需要调用原super方法，支持结构体参数传递。
                       DESC

  s.homepage         = 'https://github.com/youlianchun/MethodAspects'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'youlianchun' => 'youlianchunios@163.com' }
  s.source           = { :git => 'https://github.com/youlianchun/MethodAspects.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'MethodAspects/Classes/**/*'
  
  # s.resource_bundles = {
  #   'MethodAspects' => ['MethodAspects/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
