Gem::Specification.new do |s|
  s.name        = 'myaxes'
  s.version     = '0.1.1'
  s.date        = '2012-02-13'
  s.summary     = "MyAxes - MysqlAccess =)"
  s.description = "Simple console app for remote execute mysql queries"
  s.authors     = ["InViZz"]
  s.email       = 'morion.estariol@gmail.com'
  s.files       = ["lib/myaxes.rb", "lib/myaxes/axeconfig.rb", "lib/myaxes/options.rb"]
  s.executables << 'myaxes'
  s.add_runtime_dependency 'net-ssh'
  s.add_runtime_dependency 'net-ssh-gateway'
  s.add_runtime_dependency 'log4r'
  s.homepage    = 'https://github.com/InViZz/MyAxes'
end