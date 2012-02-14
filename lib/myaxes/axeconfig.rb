require "yaml"

class AxeConfig < Hash

  attr_reader :targets, :config

  def initialize(options)
    @config = Hash.new
    @options = options
    @targets = Hash.new
  end

  def read(config)
    user = @options['user']
    ip = @options['ip']
    #password = @options['password']
    group = @options['group']

    puts "Configfile (#{config}) not found" unless File.readable?(config)

    begin
      @config = YAML.load_file(config)
    rescue Exception => errmsg
      puts "Configfile format error: #{errmsg}"
    end

    @config['Targets'].each_key do |target|
      if @config['Targets'][target]['query'].include? group
        @config['Targets'][target]['query'][group].each do |query|
          query.to_s.gsub!('{ip}', ip).gsub!('{user}', user)
        end
        @targets["#{@config['Targets'][target]['hostname']}"] = @config['Targets'][target]['query'][group]
      end
    end

    self.config
  end


end