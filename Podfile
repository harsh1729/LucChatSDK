# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

# The current MatrixKit pod version
$matrixKitVersion = '0.10.2'

target 'LucChatSDK' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for LucChatSDK

pod 'MatrixKit', $matrixKitVersion
pod 'MatrixSDK/SwiftSupport'
pod 'MatrixSDK/JingleCallStack'

pod 'GBDeviceInfo', '~> 5.2.0'
pod 'Reusable', '~> 4.1'

# Tools
pod 'SwiftGen', '~> 6.1'
pod 'DGCollectionViewLeftAlignFlowLayout', '~> 1.0.4'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    
    # Disable bitcode for each pod framework
    # Because the WebRTC pod (included by the JingleCallStack pod) does not support it.
    # Plus the app does not enable it
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # Force SwiftUTI Swift version to 5.0 (as there is no code changes to perform for SwiftUTI fork using Swift 4.2)
      if target.name.include? 'SwiftUTI'
        config.build_settings['SWIFT_VERSION'] = '5.0'
      end
    end
  end
end
