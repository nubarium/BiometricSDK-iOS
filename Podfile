platform :ios, '13.0'
use_frameworks!

pod 'lottie-ios', '3.5.0'
pod 'Siesta', '~> 1.0'
pod 'Device', '~> 3.3.0'

target 'NubariumSDK' do
end

post_install do |installer|
  xcode_base_version = `xcodebuild -version | grep 'Xcode' | awk '{print $2}' | cut -d . -f 1`

  projects = installer.generated_projects
  projects << installer.pods_project if installer.respond_to?(:pods_project)

  projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        # 1) Fix DT_TOOLCHAIN_DIR for Xcode 15+
        if config.base_configuration_reference && Integer(xcode_base_version) >= 15
          xcconfig_path = config.base_configuration_reference.real_path
          if File.exist?(xcconfig_path)
            xcconfig = File.read(xcconfig_path)
            xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
            File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
          end
        end

        # 2) Force iOS 13.0 minimum deployment target
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'

        # 3) Remove bad arclite linker flags if injected
        flags = config.build_settings['OTHER_LDFLAGS']
        if flags.is_a?(Array)
          config.build_settings['OTHER_LDFLAGS'] =
            flags.reject { |f| f.to_s.include?('arclite') }
        elsif flags.is_a?(String)
          config.build_settings['OTHER_LDFLAGS'] =
            flags.split(/\s+/).reject { |f| f.include?('arclite') }
        end

        # 4) Clean library search paths pointing to arc/libarclite
        paths = config.build_settings['LIBRARY_SEARCH_PATHS']
        if paths.is_a?(Array)
          config.build_settings['LIBRARY_SEARCH_PATHS'] =
            paths.reject { |p| p.to_s.include?('usr/lib/arc') }
        elsif paths.is_a?(String)
          config.build_settings['LIBRARY_SEARCH_PATHS'] =
            paths.split(/\s+/).reject { |p| p.include?('usr/lib/arc') }
        end
      end
    end
  end
end
