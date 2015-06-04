#!/usr/local/bin/ruby
require 'pp'
require_relative 'generators/gen_tsv.rb'
require_relative 'rlib/switch.rb'
require_relative 'rlib/configuration.rb'

#Debugging check to see if we loaded the switches correctly
# @param switches [Switch] The switches we loaded from the conf file, and just did SNMP queries on
def self_test(switches)
  #Visual test to see if we loaded data correctly.
  switches.each do |s|
    pp s
  end
end

@config = Configuration.new
#@auth = Configuration.new((@config.auth[0] == '/') ? @config.auth : File.expand_path(File.dirname(__FILE__)) + @config.auth)
@switches_we_are_interested_in = Configuration.new((@config.switch_config[0] == '/') ? @config.switch_config : File.expand_path(File.dirname(__FILE__)) + "/" + @config.switch_config)

begin
  Dir.chdir(@config.base_directory) #Where we will create temporary files.

  #Define the switches we care about (eg. The ones in PAN, not the ITS network.)
  @switches = {}
  @switches_we_are_interested_in.switches.each do |s|
    @switches[s[0]] = Switch.new(*s) #Create an instance of the Switch class for each switch.
  end

  #Finds ports that refer a switch and tags them as bridge ports.
  @switches.each { |k, s| s.set_is_our_switch( @switches )} 

  #These aren't getting picked up automatically in the switch's snmp bridge tables entries, so we have to manually configure these entries.
  @switches['bnt-a2-001-m'].ports['23'].remote_switch_name = 'ITS'; @switches['bnt-a2-001-m'].ports['23'].bridge_port = true;
  @switches['bnt-a2-001-m'].ports['24'].remote_switch_name = 'ITS'; @switches['bnt-a2-001-m'].ports['24'].bridge_port = true;
  @switches['bnt-a2-002-m'].ports['23'].remote_switch_name = 'ITS'; @switches['bnt-a2-002-m'].ports['23'].bridge_port = true;
  @switches['bnt-a2-002-m'].ports['24'].remote_switch_name = 'ITS'; @switches['bnt-a2-002-m'].ports['24'].bridge_port = true;
  @switches['bnt-a2-002-m'].ports['21'].remote_switch_name = 'ITS_TMK_BR'; @switches['bnt-a2-002-m'].ports['21'].bridge_port = true;

  #self_test(@switches)
  TSV::gen(@switches)
  
rescue Exception=>error #catch every type of error.
  puts error
  exit(-1) #drop out. Something bad just happened
end
