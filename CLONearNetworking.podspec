Pod::Spec.new do |s|

  s.name         = "CLONearNetworking"
  s.version      = "1.0.0"
  s.summary      = "A short description of CLONearNetworking."
  s.description  = <<-DESC
                    Cc
                  DESC

  s.homepage     = "https://github.com/ccloveobjc/CLONearNetworking"
  
  s.license      = { :type => 'Copyright', :text =>
        <<-LICENSE
        Copyright 2010-2015 CenterC Inc.
        LICENSE
  }
  
  s.author            = { "TT" => "654974034@qq.com" }

  s.source       = { :git => "https://github.com/ccloveobjc/CLONearNetworking.git", :tag => "#{s.version}" }

  s.requires_arc = true

  s.default_subspec     = 'Core'

  s.subspec 'Core' do |ss|
    ss.frameworks          = "Foundation"
    ss.source_files        = "Classes/Core/**/*.{h,m,mm,hpp,cpp,c}"
  end

  s.subspec 'Bluetooth' do |ss|
    ss.dependency       'CLONearNetworking/Core'
    ss.frameworks          = "CoreBluetooth"
    ss.source_files        = "Classes/Bluetooth/**/*.{h,m,mm,hpp,cpp,c}"
  end
end
