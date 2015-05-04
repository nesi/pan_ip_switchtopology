#!/usr/local/bin/ruby
require 'pp'
require_relative 'gen_neato_topology.rb'
require_relative 'gen_dot_topology.rb'
require_relative 'gen_switch_graph.rb'
require_relative 'switch.rb'
require_relative 'configuration.rb'

@config = Configuration.new
@auth = Configuration.new('conf/auth.json')

#Pairs [Switch_name in the Database, Switch_DNS name]
SNMPWALK = true #Set to false during testing, and snmp queries don't happen

begin
  Dir.chdir(@config.base_directory)

  #Define the switches we care about (eg. The ones in PAN, not the ITS network.)
  @switches = {}
  [ 
      #hostname     ,  #IP Address  , #MAC Address       , #Make, #Model,  #Position, #Use SNMP
    [ 'bnt-a2-001-m', '10.0.116.229', '08:17:F4:5E:62:00', :bnt, 'G8124', :external, @auth.snmp_community, SNMPWALK ], #External
    [ 'bnt-a2-002-m', '10.0.116.230', '08:17:F4:5E:50:00', :bnt, 'G8124', :external, @auth.snmp_community, SNMPWALK ], #External
  
    [ 'bnt-c2-004-m', '10.0.116.247', '6C:AE:8B:E4:C5:00', :bnt, 'G8124', :private_core, @auth.snmp_community, SNMPWALK ], #C2-U41 Core
    [ 'bnt-c2-003-m', '10.0.116.246', ['6C:AE:8B:E4:CB:00','6C:AE:8B:E4:CB:FE'], :bnt, 'G8124', @auth.snmp_community, :private_core, SNMPWALK ], #C2-U42 Core
  
    [ 'Pica8 Switch', '10.0.116.147', ['E8:9A:8F:FB:C4:73','E8:9A:8F:FB:C4:74'], :pica8, 'Pronto 3290', :private_leaf, SNMPWALK  ], #'tdc-o18-u48-m' in the hosts file and actually in o15 rack

    [ 'exmgmt-a1-b4-m', '10.0.116.225', '08:17:F4:C3:65:00', :bnt, 'G8000', :private_leaf, @auth.snmp_community, SNMPWALK ],
    [ 'exmgmt-a1-b6-m', '10.0.116.226', '08:17:F4:C3:5F:00', :bnt, 'G8000', :private_leaf, @auth.snmp_community, SNMPWALK ],
    [ 'exmgmt-a1-d4-m', '10.0.116.227', '08:17:F4:C3:6A:00', :bnt, 'G8000', :private_leaf, @auth.snmp_community, SNMPWALK  ],
    [ 'exmgmt-a1-d6-m', '10.0.116.228', '08:17:F4:C3:AC:00', :bnt, 'G8000', :private_leaf, @auth.snmp_community, SNMPWALK  ],
    [ 'exmgmt-b1-b6-m', '10.0.116.237', '6C:AE:8B:E0:20:00', :bnt, 'G8000', :private_leaf, @auth.snmp_community, SNMPWALK  ],
    [ 'exmgmt-b1-d6-m', '10.0.116.238', '6C:AE:8B:E0:3F:00', :bnt, 'G8000', :private_leaf, @auth.snmp_community, SNMPWALK  ],
    [ 'exmgmt-c3-b2-m', '10.0.116.242', '74:99:75:49:65:00', :bnt, 'G8052', :private_leaf, @auth.snmp_community, SNMPWALK ],
    [ 'exmgmt-c3-d2-m', '10.0.116.243', '74:99:75:49:63:00', :bnt, 'G8052', :private_leaf, @auth.snmp_community, SNMPWALK ],
    [ 'exmgmt-a4-b6-m', '10.0.116.244', '6C:AE:8B:E3:34:00', :bnt, 'G8000', :private_leaf, @auth.snmp_community, SNMPWALK  ],
    [ 'exmgmt-a4-d6-m', '10.0.116.245', '6C:AE:8B:E3:27:00', :bnt, 'G8000', :private_leaf, @auth.snmp_community, SNMPWALK  ],
    [ 'exmgmt-a5-b4-m', '10.0.116.148', '74:99:75:3f:7a:00', :bnt, 'G8052', :private_leaf, @auth.snmp_community, SNMPWALK ],
    [ 'exmgmt-a5-d4-m', '10.0.116.149', '74:99:75:3f:8d:00', :bnt, 'G8052', :private_leaf, @auth.snmp_community, SNMPWALK  ],
    [ 'exmgt-c2-u40-m', '10.0.116.146', ['78:FE:3D:E9:52:80','78:FE:3D:E9:52:81'], :juniper, 'ex3300-24t', :private_leaf, @auth.snmp_community, SNMPWALK  ],
    [ 'exmgt-o18-u42-m', '10.0.116.144', '50:C5:8D:A9:D9:40', :juniper, 'ex3300-24t', :private_leaf, @auth.snmp_community, SNMPWALK  ], #Department nodes in test rack.
    #These are on dev network, but are visible via private vlans on above switches.
    #[ 'exmgt-o15-u41', '192.168.116.144', '78:FE:3D:E9:5E:00', :juniper, 'ex4300-24t', :private_leaf, @auth.snmp_community, false ], #connected to port 43 of exmgmt-a5-b4-m
    #[ 'tdc-o18-u46-m_dev_switch', '192.168.116.145', '78:FE:3D:E9:73:40', :juniper, 'ex4300-24t', :private_leaf, @auth.snmp_community, false  ], #Connected to port 47 of the Pica8 
  
  ].each do |s|
    @switches[s[0]] = Switch.new(*s) #Create an instance of the Switch class for each switch.
  end

  @switches.each { |k, s| s.set_is_our_switch(@switches )} #Finds ports that refer a switch and tags them as bridge ports.

  #These aren't getting picked up automatically in the switch's snmp bridge tables entries, so we have to manually configure these entries.
  @switches['bnt-a2-001-m'].ports['23'].remote_switch_name = 'ITS'; @switches['bnt-a2-001-m'].ports['23'].bridge_port = true;
  @switches['bnt-a2-001-m'].ports['24'].remote_switch_name = 'ITS'; @switches['bnt-a2-001-m'].ports['24'].bridge_port = true;
  @switches['bnt-a2-002-m'].ports['23'].remote_switch_name = 'ITS'; @switches['bnt-a2-002-m'].ports['23'].bridge_port = true;
  @switches['bnt-a2-002-m'].ports['24'].remote_switch_name = 'ITS'; @switches['bnt-a2-002-m'].ports['24'].bridge_port = true;
  @switches['bnt-a2-002-m'].ports['21'].remote_switch_name = 'ITS_TMK_BR'; @switches['bnt-a2-002-m'].ports['21'].bridge_port = true;

=begin
  #Visual test to see if we loaded data correctly.
  @switches.each do |s|
    pp s
  end
=end

  #Dot.new("/tmp/x.dot", @switches)
  Neato.gen_neato(@switches, 'pan_private_net') #Generates a neato diagram for the switches we found.

  Gen_switch_graph.gen_shtml(@switches)
  #Gen_switch_graph.gen_dot(@switches)
  Gen_switch_graph.gen_html_table(@switches) #Generates HTML tables, with the switch ports as cells, and coloured to indicate the state.
rescue Exception=>error
  puts error
end
