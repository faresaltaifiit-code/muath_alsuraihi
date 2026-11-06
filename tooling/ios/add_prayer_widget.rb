require 'xcodeproj'
require 'fileutils'

root = File.expand_path('../..', __dir__)
ios = File.join(root, 'ios')
source = File.join(root, 'tooling/ios/PrayerWidget')
destination = File.join(ios, 'PrayerWidget')
FileUtils.mkdir_p(destination)
%w[PrayerWidget.swift Info.plist Widget.entitlements].each { |name| FileUtils.cp(File.join(source, name), destination) }
FileUtils.cp(File.join(source, 'Runner.entitlements'), File.join(ios, 'Runner', 'PrayerWidget.entitlements'))
project = Xcodeproj::Project.open(File.join(ios, 'Runner.xcodeproj'))
runner = project.targets.find { |target| target.name == 'Runner' } or abort 'Runner target missing'
abort 'PrayerWidget target already exists' if project.targets.any? { |target| target.name == 'PrayerWidget' }
widget = project.new_target(:app_extension, 'PrayerWidget', :ios, '16.0')
group = project.main_group.new_group('PrayerWidget', 'PrayerWidget')
swift = group.new_file('PrayerWidget.swift')
group.new_file('Info.plist')
group.new_file('Widget.entitlements')
widget.source_build_phase.add_file_reference(swift)
widget.frameworks_build_phase.add_file_reference(project.frameworks_group.new_file('System/Library/Frameworks/WidgetKit.framework', :sdk_root))
widget.frameworks_build_phase.add_file_reference(project.frameworks_group.new_file('System/Library/Frameworks/SwiftUI.framework', :sdk_root))
widget.build_configurations.each do |config|
  config.build_settings.merge!(
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.faresaltaifi.muathalsuraihi.PrayerWidget',
    'PRODUCT_NAME' => 'PrayerWidget',
    'INFOPLIST_FILE' => 'PrayerWidget/Info.plist',
    'CODE_SIGN_ENTITLEMENTS' => 'PrayerWidget/Widget.entitlements',
    'SWIFT_VERSION' => '5.0',
    'IPHONEOS_DEPLOYMENT_TARGET' => '16.0',
    'TARGETED_DEVICE_FAMILY' => '1,2',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
    'SKIP_INSTALL' => 'YES',
    'MARKETING_VERSION' => '1.1.1',
    'CURRENT_PROJECT_VERSION' => ENV.fetch('GITHUB_RUN_NUMBER', '1'),
    'FLUTTER_BUILD_NAME' => '1.1.1',
    'FLUTTER_BUILD_NUMBER' => ENV.fetch('GITHUB_RUN_NUMBER', '1')
  )
end
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/PrayerWidget.entitlements'
end
runner.add_dependency(widget)
embed = runner.new_copy_files_build_phase('Embed App Extensions')
embed.dst_subfolder_spec = '13'
embed.add_file_reference(widget.product_reference, true)
project.save
