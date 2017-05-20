#
# Be sure to run `pod lib lint custom_uikit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'custom_uikit'
  s.version          = '0.1.0'
  s.summary          = 'custom_uikit custom some uikit'
  s.homepage         = 'https://github.com/smalldu/specs'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'duzhe' => '363958265@qq.com' }
  s.source           = { :git => 'https://github.com/smalldu/custom_ui.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.ios.deployment_target = '8.0'
  s.source_files = 'custom_uikit/Classes/**/*'
  # s.resource_bundles = {
  #   'custom_uikit' => ['custom_uikit/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
