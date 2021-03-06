require "logstash/inputs/base"
require "logstash/namespace"

# Receive events using the lumberjack protocol.
#
# NOTE: THIS PROTOCOL IS STILL A WORK IN PROGRESS
class LogStash::Inputs::Lumberjack < LogStash::Inputs::Base

  config_name "lumberjack"
  plugin_status "experimental"

  # the address to listen on.
  config :host, :validate => :string, :default => "0.0.0.0"

  # the port to listen on.
  config :port, :validate => :number, :required => true

  # ssl certificate to use
  config :ssl_certificate, :validate => :string, :required => true

  # ssl key to use
  config :ssl_key, :validate => :string, :required => true

  # ssl key passphrase to use
  config :ssl_key_passphrase, :validate => :password

  # TODO(sissel): Add CA to authenticate clients with.

  public
  def register
    require "lumberjack/server"

    @logger.info("Starting lumberjack input listener", :address => "#{@host}:#{@port}")
    @lumberjack = Lumberjack::Server.new(:address => @host, :port => @port,
      :ssl_certificate => @ssl_certificate, :ssl_key => @ssl_key,
      :ssl_key_passphrase => @ssl_key_passphrase)
  end # def register

  public
  def run(output_queue)
    @lumberjack.run do |l|
      event = LogStash::Event.new(
        "@message" => l.delete("line"),
        "@source_path" => l.delete("file"),
        "@source_host" => l.delete("host"),
        "@fields" => l,
        "@type" => @type,
        "@tags" => @tags.clone
      )
      output_queue << event
    end
  end # def run
end # class LogStash::Inputs::Lumberjack
