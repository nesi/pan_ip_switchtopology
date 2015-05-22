require 'json'
require 'pp'

#Reads json configuration and provides access to the configuration data
#as method calls.
class Configuration
  
  #Creates an instance of Configuration from a json file
  # @param [String] filename The Json file
  # @return [Configuration]
  def initialize(filename="#{File.dirname(__FILE__)}/../conf/config.json") 
    json = File.read(filename)
    @pjson = JSON.parse(json)
  end
  
  #Provides a test for a method named after a json configuration item exists
  # @note We need to define respond_to? as well as method_missing to satisfy tests in some libraries.
  # @param symbol [Symbol,String]  The method name we need to test exists
  # @param include_private [Boolean]  Extend the test to private methods
  # @return [Boolean] true if the method exists
  def respond_to?(symbol, include_private = false)
    (@pjson[symbol.to_s] != nil) || super(symbol, include_private)
  end

  #Default handler to map json configuration names to method names
  # @note Be aware of the possibility of name conflicts between built in class methods an configuration items defined in the json file)
  # @param symbol [symbol,String] The method name that maps to a json configuration item
  # @param args [Array] Not used, but would hold arguments to the method call. Should be zero length for our methods.
  # @param block [Block] Not used, but would be a code block supplied to the method. 
  # @return [Object] the data associated with the json name, (hence method name) in the configuration file.
  def method_missing(symbol , *args, &block)
    s = symbol.to_s
    if @pjson[s] != nil
      return @pjson[s]
    else
      super
    end     
  end
  
  # @return [String] the configuration
  def to_s
    @pjson.to_s
  end
  
  #Provides a self test of this class, by reading the test configuration file.
  #  and attempting to access configuration items as methods. 
  def self.test
    config = Configuration.new('../conf/config_test.json')
    puts "base_directories is defined? #{config.respond_to?(:base_directory)}"
    puts "not_there is defined? #{config.respond_to?(:not_there)}"
    puts "base_directories is: '#{config.base_directory}'"
    puts "hello is of class: #{config.hello.class}"
    puts "config.hello[0] => #{config.hello[0]}"
    puts "world is of class: #{config.world.class}"
    puts "config.world['1'] => #{config.world['1']}"
    puts "boolean is of class: #{config.boolean.class}"
    puts "config.boolean => #{config.boolean}"
    puts "Dump the config file using to_s"
    puts config
  end
end

#Self test
#Configuration.test
