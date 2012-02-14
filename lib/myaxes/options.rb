require "optparse"

class Options

  attr_reader :options

  def initialize
    @options = Hash.new

    @options['mode'] = 'log'
    @options['log'] = $stdout

    end

  def parse
    OptionParser.new do |opt|
      opt.separator ""
      opt.separator "Usage: myaxes -g <group> -a <ip> -u <username> -p <password>[-H <hostnames>]"
      opt.separator ""
      opt.separator "shell> myaxes -g web -a 192.168.0.101 -u web301 -p qwerty"
      opt.separator ""
      opt.separator ""
      opt.separator "Options:"
      opt.separator "-------------"
      opt.on('-g', '--group GROUPNAME', 'Group from config') { |val| @options['group'] = val }
      opt.on('-a', '--address IP-ADDRESS', 'Ip address') { |val| @options['ip'] = val }
      opt.on('-u', '--user USERNAME', 'Username') { |val| @options['user'] = val }
      opt.on('-p', '--password PASSWORD', 'Password') { |val| @options['password'] = val }
      opt.on('-H', '--hosts HOSTNAME_X,HOSTNAME_Y,HOSTNAME_Z', Array, 'Other Hosts(not from config)')  { |val| @options['hosts'] = val }
      opt.separator ""
      opt.on_tail('-h', '--help')           { puts opt; exit }

      opt.parse!
    end

    self.options

  end

end