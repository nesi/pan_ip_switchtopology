#!/usr/local/bin/ruby
require 'pp'
require_relative 'generators/gen_neato_topology.rb'
require_relative 'generators/gen_dot_topology.rb'
require_relative 'generators/gen_switch_graph.rb'
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
@auth = Configuration.new('conf/auth.json')
@switches_we_are_interested_in = Configuration.new(@config.switch_config)
begin
  Dir.chdir(@config.base_directory) #Where we will create temporary files.

  #Define the switches we care about (eg. The ones in PAN, not the ITS network.)
  @switches = {}
  @switches_we_are_interested_in.switches.each do |s|
    @switches[s[0]] = Switch.new(*s) #Create an instance of the Switch class for each switch.
  end

  #Finds ports that refer a switch and tags them as bridge ports.
  @switches.each { |k, s| s.set_is_our_switch(@switches )} 

  #These aren't getting picked up automatically in the switch's snmp bridge tables entries, so we have to manually configure these entries.
  @switches['bnt-a2-001-m'].ports['23'].remote_switch_name = 'ITS'; @switches['bnt-a2-001-m'].ports['23'].bridge_port = true;
  @switches['bnt-a2-001-m'].ports['24'].remote_switch_name = 'ITS'; @switches['bnt-a2-001-m'].ports['24'].bridge_port = true;
  @switches['bnt-a2-002-m'].ports['23'].remote_switch_name = 'ITS'; @switches['bnt-a2-002-m'].ports['23'].bridge_port = true;
  @switches['bnt-a2-002-m'].ports['24'].remote_switch_name = 'ITS'; @switches['bnt-a2-002-m'].ports['24'].bridge_port = true;
  @switches['bnt-a2-002-m'].ports['21'].remote_switch_name = 'ITS_TMK_BR'; @switches['bnt-a2-002-m'].ports['21'].bridge_port = true;

  self_test(@switches)
  
  #Generates a neato diagram for the switches we found.
  Neato.gen_neato(@switches, @config.html_directory, @config.html_network_directory, @config.neato_base_filename, @config.neato_keep_tmp_files) 
  #Gen_switch_graph.gen_dot(@switches, @config.dot_filename)
  
  Gen_switch_graph.gen_shtml(@switches, @config.html_directory, @config.html_network_directory) #Generate the shtml files that link the neato .png and map files together (if they don't exist).
  Gen_switch_graph.gen_html_table(@switches, @config.html_directory, @config.html_network_directory) #Generates HTML tables, with the switch ports as cells, and coloured to indicate the state.
  
rescue Exception=>error #catch every type of error.
  puts error
  exit(-1) #drop out. Something bad just happened
end
