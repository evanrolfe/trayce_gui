Pod::Spec.new do |s|
    s.name             = 'trayce'
    s.version          = '1.5.0'
    s.summary          = 'Trayce macOS FFI plugin'
    s.description      = <<-DESC
    A Flutter plugin that uses FFI for macOS.
    DESC
    s.homepage         = 'https://your-repo.com'
    s.license          = { :file => '../LICENSE' }
    s.author           = { 'Your Name' => 'your@email.com' }
    s.source           = { :path => '.' }
    s.vendored_frameworks = 'trayce.framework'
    s.platform         = :osx, '10.14'
  end
