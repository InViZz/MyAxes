require "rubygems"
require "net/ssh"
require "net/ssh/gateway"
require "log4r"
require 'myaxes/axeconfig'
require 'myaxes/options'

class MyAxes

  include Log4r

  def initialize(config='~/.myaxes.yml')
    @logger = Logger.new('MyAxes')
    @logger.outputters = Outputter.stdout

    @options = Options.new.parse
    @logger.debug "test #{@options}" if $DEBUG

    @conf = AxeConfig.new(@options)
    @config = @conf.read(config)
    @targets = @conf.targets
    @threads = []

    @ssh_options ={
      :port => @config['Global']['ssh_port'],
    	:verbose => @config['Global']['debug_level'].to_sym,
    	:auth_methods => %w(publickey password keyboard-interactive),
    	:keys => @config['Global']['ssh_keys'],
    	:password => @config['Global']['password']
    }
    @commands_proc = Proc.new { |session, hostname|
      @targets[hostname].each do |query|
        @logger.debug "Query: #{query}" if $DEBUG
        name = hostname.chomp.split(".")[0]
        cmd = "mysql -u #{@config['Targets'][name]['login']} -e '#{query}' -p"
        output = self.exec(session,cmd,name)
        puts "\033[0;32m[*] #{hostname}\033[0m: #{output}"
      end
    }

  end

  def start
    @targets.each_key do |hostname|
      if self.use_gw?
        @threads << Thread.new {
          self.via_gw do |jump_server|
            begin
              jump_server.ssh(hostname, @config['Global']['login'], @ssh_options) do |session|
                @commands_proc.call(session,hostname)
              end
            rescue Net::SSH::Disconnect => errmsg
              warn "#{hostname} : #{errmsg}"
            rescue Net::SSH::AuthenticationFailed => errmsg
              warn "#{hostname} : #{errmsg}"
            rescue Errno::ETIMEDOUT => errmsg
              warn "#{hostname} : #{errmsg}"
            rescue Errno::ECONNREFUSED => errmsg
              warn "#{hostname} : #{errmsg}"
            end
          end
        }
      else
        @threads << Thread.new {
          begin
            Net::SSH.start(hostname, @config['Global']['login'], @ssh_options) do |session|
              @commands_proc.call(session,hostname)
       		  end
       		rescue Net::SSH::Disconnect => errmsg
            warn "#{hostname} : #{errmsg}"
          rescue Net::SSH::AuthenticationFailed => errmsg
            warn "#{hostname} : #{errmsg}"
          rescue Errno::ETIMEDOUT => errmsg
            warn "#{hostname} : #{errmsg}"
          rescue Errno::ECONNREFUSED => errmsg
            warn "#{hostname} : #{errmsg}"
          end
       	}
      end
    end

    @threads.each {|thread|
      thread.join
    }
  end

  def via_gw
    begin
      jump_server = Net::SSH::Gateway.new(@config['Global']['jump_server'], @config['Global']['login'], @ssh_options)

	    @logger.debug "port forwarding ok" if $DEBUG

	    yield jump_server

	  rescue Net::SSH::Disconnect => errmsg
    	warn "Gateway : #{errmsg}"
    rescue Net::SSH::AuthenticationFailed => errmsg
    	warn "Gateway : #{errmsg}"
    rescue Errno::ETIMEDOUT => errmsg
    	warn "Gateway : #{errmsg}"
    rescue Errno::ECONNREFUSED => errmsg
    	warn "Gateway : #{errmsg}"
    end

  end

  def use_gw?
    @config['Global']['use_jump']
  end

  def exec(session,cmd,name)
    channel = session.open_channel do |channel|
      channel.request_pty do |ch, success|
        raise "Could not obtain pty (i.e. an interactive ssh session)" if !success
      end
      channel.exec(cmd) do |ch, success|
        die "could not execute command" unless success
          channel.on_data do |ch, data|
            if data == "Enter password: "
              @logger.debug "DEBUG: Password request" if $DEBUG
              channel.send_data "#{@config['Targets'][name]['password']}\n"
            else
              channel[:result] ||= ""
              channel[:result] << data
            end
          end

          channel.on_extended_data do |ch, type, data|
            raise "SSH command returned on stderr: #{data}"
          end
        end
      end

          # Nothing has actually happened yet. Everything above will respond to the
          # server after each execution of the ssh loop until it has nothing left
          # to process. For example, if the above recieved a password challenge from
          # the server, ssh's exec loop would execute twice - once for the password,
          # then again after clearing the password (or twice more and exit if the
          # password was bad)
      channel.wait

      return channel[:result] # it returns with \r\n at the end
  end

end