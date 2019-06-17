Pod::Spec.new do |s|

  s.name         = "Spine"
  s.version      = "1.3"
  s.summary      = "Unofficial Spine runtime library for iOS, macOS, tvOS and watchOS"
  s.description  = <<-DESC
                    This library allows you to play animations created with the Spine App: http://esotericsoftware.com
                    Animations are played using the graphics engine SpriteKit.

                    System requirements:
                    ====================
                    iOS 8.0+
                    macOS 10.10+
                    tvOS 9.0+
                    watchOS 3.0+

                    Swift 5.0+

                    See the source at https://github.com/maxgribov/Spine
                   DESC

  s.homepage     = "https://github.com/maxgribov/Spine"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Max Gribov" => "gribov.max@gmail.com" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.tvos.deployment_target = "9.0"
  s.watchos.deployment_target = "3.0"

  s.source       = { :git => "https://github.com/maxgribov/Spine.git", :tag => "v#{s.version}" }

  s.source_files  = "Spine/**/*.swift"
  s.framework  = "SpriteKit"

end
