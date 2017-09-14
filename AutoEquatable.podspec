Pod::Spec.new do |s|
  s.name             = 'AutoEquatable'
  s.version          = '1.3'
  s.summary          = 'Convenient protocol that allows all types to easily and safely conform to Equatable.'

  s.description      = <<-DESC
    AutoEquatable provides a confenient and future proof way of conforming to Equatable. Compares all of a types properties to evaluate Equatable. There is no risk of forgetting to add new properties to the `==(lhs:rhs:)` operation if more properties are added.
                       DESC

  s.homepage         = 'https://github.com/Rivukis/AutoEquatable'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Brian Radebaugh' => 'Rivukis@gmail.com' }
  s.source           = { :git => 'https://github.com/Rivukis/AutoEquatable.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.source_files = 'AutoEquatable.playground/Sources/AutoEquatable.swift'
end