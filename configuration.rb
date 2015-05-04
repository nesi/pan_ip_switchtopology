require 'json'

class Configuration
  def initialize(filename="#{File.dirname(__FILE__)}/conf/config.json") 
    json = File.read(filename)
    @pjson = JSON.parse(json)
  end
  
  #Need to define respond_to? and method_missing.
  def respond_to?(symbol, include_private = false)
    (@pjson[symbol.to_s] != nil) || super(symbol, include_private)
  end

  def method_missing(symbol , *args, &block)
    s = symbol.to_s
    if @pjson[s] != nil
      return @pjson[s]
    else
      super
    end     
  end
  
  def to_s
    @pjson.to_s
  end
  
  def self.test
    $config = Configuration.new
    puts $config.base_directory
    puts $config.respond_to?(:base_directory)
    puts $config.respond_to?(:not_there)
  end
end

#Self test
#s = Configuration.new('conf/auth.json')
#puts s.snmp_community
#Configuration.test
