require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))
Pod::Spec.new do |s|
  s.name         = "react-native-zebra-bluetooth-printer"
  s.version      = "1.0.8"
  s.summary      = "RNZebraBluetoothPrinter"
  s.description  = <<-DESC
                  RNZebraBluetoothPrinter
                   DESC
  s.homepage     = "https://github.com/anmoljain10/react-native-zebra-bluetooth-printer.git"
  s.authors             = { "Aditya Kumar" => "adityak@geekyants.com",
                            "Anmol Jain"  =>"anmol@geekyants.com"
                           }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/anmoljain10/react-native-zebra-bluetooth-printer.git", :tag => "#{s.version}" }
  s.source_files = "ios/**/*.{h,m,swift}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end

  