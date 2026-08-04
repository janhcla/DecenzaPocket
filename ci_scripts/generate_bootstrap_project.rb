#!/usr/bin/env ruby

require "xcodeproj"

output_path = ARGV.fetch(0)
project = Xcodeproj::Project.new(output_path)
target = project.new_target(:application, "DecenzaPocket", :ios, "17.0")

source = project.main_group.new_file("../../ci_scripts/bootstrap/main.m")
target.add_file_references([source])

target.build_configurations.each do |configuration|
  settings = configuration.build_settings
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings["CURRENT_PROJECT_VERSION"] = "1"
  settings["DEVELOPMENT_TEAM"] = "ARQN5UD84L"
  settings["GENERATE_INFOPLIST_FILE"] = "YES"
  settings["INFOPLIST_KEY_CFBundleDisplayName"] = "DecenzaPocket"
  settings["MARKETING_VERSION"] = "1.0"
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.janhagenclausen.DecenzaPocket"
  settings["SUPPORTED_PLATFORMS"] = "iphoneos iphonesimulator"
  settings["TARGETED_DEVICE_FAMILY"] = "1,2"
end

project.save

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(project.path, "DecenzaPocket", true)
