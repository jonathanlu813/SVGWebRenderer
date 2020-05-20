#
# Be sure to run `pod lib lint SVGWebRenderer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SVGWebRenderer'
  s.version          = '0.2.0'
  s.summary          = 'Rendering SVG files into UIImages using WKWebView'

  s.description      = <<-DESC
                       SVGWebRender helps you turn SVG files, either local or remote, into UIImages that can be used with UIKit elements such as UIImageView, leveraging the capability of WKWebView.
                       DESC

  s.homepage         = 'https://github.com/jonathanlu813/SVGWebRenderer'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jonathanlu813' => 'jonathanlu813@gmail.com' }
  s.source           = { :git => 'https://github.com/jonathanlu813/SVGWebRenderer.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/jo_lu_v'

  s.ios.deployment_target = '11.0'
  
  s.swift_version = "4.2"
  s.swift_versions = ['4.0', '4.2', '5.0']
  
  s.frameworks = "UIKit", "WebKit"

  s.source_files = 'SVGWebRenderer/Classes/**/*'
  s.dependency 'Kingfisher', '~> 4.10.0'
  s.dependency 'Alamofire', '~> 5.0.0'
  s.dependency 'CryptoSwift', '~> 1.0'
  
end
