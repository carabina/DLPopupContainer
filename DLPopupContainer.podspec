Pod::Spec.new do |s|
  s.name         = "DLPopupContainer"
  s.version      = "0.0.1"
  s.summary      = "Popup custome view."
  s.homepage     = "https://github.com/TheForgottenProgrammer/DLPopupContainer"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Dalang" => "https://github.com/TheForgottenProgrammer" }
  s.source       = { :git => "https://github.com/TheForgottenProgrammer/DLPopupContainer.git", :tag => "#{s.version}" }
  s.source_files = "DLPopupContainer", "DLPopupContainer/**/*.{h,m}"
  s.frameworks   = "UIKit", "Foundation"
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '8.0'
end
