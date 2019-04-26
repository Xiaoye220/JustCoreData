#
# Be sure to run `pod lib lint JustCoreData.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JustCoreData'
  s.version          = '5.0.0'
  s.summary          = 'CoreData extensions'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Xiaoye220/JustCoreData'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Xiaoye220' => '576934532@qq.com' }
  s.source           = { :git => 'https://github.com/Xiaoye220/JustCoreData.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'JustCoreData/Classes/**/*'

  s.swift_version = '5.0'
end
