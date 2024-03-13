platform :ios, '13.0'
use_frameworks!

pod 'GoogleMLKit/FaceDetection'
#pod 'GoogleMLKit/TextRecognition'
pod 'lottie-ios', '3.5.0'
pod 'Siesta', '~> 1.0'
pod "Device", '~> 3.3.0'
#pod 'Schedule', '~> 2.0'

post_install do |installer|
  xcode_base_version = `xcodebuild -version | grep 'Xcode' | awk '{print $2}' | cut -d . -f 1`

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # For xcode 15+ only
      if config.base_configuration_reference && Integer(xcode_base_version) >= 15
        xcconfig_path = config.base_configuration_reference.real_path
        xcconfig = File.read(xcconfig_path)
        xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
        File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
      end
    end
  end
end

target 'NubariumSDK' do
end
