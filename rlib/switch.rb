require 'rubygems'
require 'snmp'
require_relative 'snmp_override.rb' #Override the oids not increasing warning, which also aborts the snmp walk
require_relative 'port.rb' 
require 'pp' #for diagnostic messages

#Holds a record for a Switch. 
class Switch
  attr_accessor :name, :ports, :ip, :mac, :category, :switch_make, :switch_model

  #Create an instance of Switch
  # @return [Switch]
  # @param name [String] Switch name
  # @param ip [String, Array<String>] IP address of the switch itself. If more than on IP address, then this is an Array.
  # @param mac [String, Array<String>] MAC address of the switch itself. If more than one, then this is an Array.
  # @param switch_make [String] Manufacturers make
  # @param switch_model [String] Manufacturers model
  # @param category [String] Designates position in the network, which helps in making pretty pictures ["external" | "private_core", | "private_leaf" | ...]
  # @param community [String] This switches SNMP read community string
  # @param do_snmpwalk [Boolean] True, if we want to query the switch. False, if we want to skip this switch.
  def initialize(name, ip, mac, switch_make, switch_model, category, community, do_snmpwalk=false)
    @name, @ip, @switch_make, @switch_model, @category = name, ip,  switch_make, switch_model, category
    @community = community
    if mac.class == Array
      @mac = mac.collect {|x| x.upcase }
    else
      @mac = mac.upcase
    end
    @ports = {}
    @physical_port_map = {} #Port numbers in some parts of the MIB don't match the physical port numbers. Map from virtual -> physical.
    @trunk_port_map = {}
    snmpwalk if do_snmpwalk
  end  
  
  #Is  a remote switch on this port, or just a host or hosts.
  #Check is made using the results of querying the bridge MIB.
  # @return [Boolean]
  # @param pport [Port] Port record we want to test.
  # @param switches [Hash] Hash by switch name, of all Switch records.
  def remote_switch?(pport, switches)
    switches.each do |sk,sv| #Look on all the switches we have to see if the switch Mac and port Mac match
      if sv.mac.class == Array
        sv.mac.each do |mac|
          if mac == pport.remote_mac #We found a match
             return true #Mark it as a bridge port.
          end
        end
      else
        if sv.mac == pport.remote_mac #We found a match
          return true #Mark it as a bridge port.
        end
      end
    end
    return false
  end
  
  #Process all switches, and tag switch ports, that are connected to another of our switches.
  # @param switches [Hash] Hash by switch name, of all Switch records.
  def set_is_our_switch(switches)
    @ports.each do |pkey, pport|#for each port on this switch
      if(pport.remote_mac != nil && pport.remote_mac != '') #if we have a remote port recorded.
        #puts "#{@name} #{pport.port_number} #{pport.remote_mac} #{pport.remote_switch_name} #{pport.remote_port_number}"
        pport.bridge_port = remote_switch?(pport, switches)
        #puts "  Bridge" if pport.bridge_port
      end
    end
  end
  
  #To_s for this class for diagnositic purposes.
  def to_s
    "name=>#{@name}, ip=>#{@ip} mac=>#{@mac} ports=>#{@ports}"
  end

  #Snmpwalk is run to retrieve multiple OIDs from ths switch, and set switch and port attributes.
  def snmpwalk
    process_switch(["1.0.8802.1.1.2.1.3.7.1.3"]) do |k,v| #Port numbers
      v = k[-1] if v == "" #Pronto8 switch sets v to ''
      @ports[k[-1]] = Port.new(v)
      @trunk_port_map[k[-1]] = k[-1] #Prime the trunk to port mapping to be 1:1
      @physical_port_map[k[-1]] = k[-1]
    end
    process_switch(["1.0.8802.1.1.2.1.3.7.1.4"]) do |k,v| #Port names
      v = k[-1] if v == "" #Pronto8 switch sets v to ''
      @ports[k[-1]].port_name = v
    end
=begin
 #BAD TEST for switch: remote nodes type (7 seems to be a switch. 5 is used by the pronto switch. 3 seems to be a host. Except fmhs-003 uses 5 :( ))
    process_switch(["1.0.8802.1.1.2.1.4.1.1.6"]) do |k,v| 
      if v != "3" && v != "0"
        @ports[k[-2]].bridge_port = true
      end
    end
=end
    process_switch(["1.0.8802.1.1.2.1.4.1.1.5"]) do |k,v| #remote switch Mac address. Might also be a host running LLDP.
      #Pronto8 switch sets v to '' if there is no remote switch. Other switches leave the OID out completely.
      @ports[k[-2]].remote_switch_name = v # Fill this in now, in case the switch name is blank in the next step.
      @ports[k[-2]].remote_mac = v.upcase
    end
    process_switch(["1.0.8802.1.1.2.1.4.1.1.9"]) do |k,v| #Names of connected switches
      @ports[k[-2]].remote_switch_name = v #Might actually be a node name.
    end
    process_switch(["1.0.8802.1.1.2.1.4.1.1.8"]) do |k,v|  #Names of remote port name
      @ports[k[-2]].remote_port_name = v
    end
    process_switch(["1.0.8802.1.1.2.1.4.1.1.7"]) do |k,v|  #Names of remote port number
      @ports[k[-2]].remote_port_number = v
    end
    
    #See if any of the LLDP entries we found are switches we know of. 
    #If they are, mark entry as a switch
    #If not, they may be hosts running LLDP, or switches we don't know about.
    #In either case, treat them as a host for display purposes (will just get lots of ARP entries for switches and virtual switches)
    
    #SNMPv2-SMI::mib-2.17.1.4.1.2.port => interface number
    process_switch(["SNMPv2-SMI::mib-2.17.1.4.1.2"]) do |k,v| 
      if @switch_make != "juniper"
        @physical_port_map[v] = k[-1] #Physical port number is derived from using virtual port number as a hash index
      end
    end
    
    #SNMPv2-SMI::enterprises.26543.2.7.4.2.3.9.2.1.1.<trunk>.<port> => <trunk>
    process_switch(["SNMPv2-SMI::enterprises.26543.2.7.4.2.3.9.2.1.1"]) do |k,v| 
      #Most switches, this will be a null mapping, but for BNT wit LACP links, the trunk numbers are returned where we would expect port numbers on other switches.
      @trunk_port_map[v] = k[-1] #Physical port number is derived from using trunk number as a hash index
    end
   
    process_switch(["IF-MIB::ifOperStatus"]) do |k,v| 
      port_index = @physical_port_map[k[-1]]
      if port_index != nil && @ports[port_index] != nil
        @ports[port_index].up = (v == "1") 
      end
    end
    
    process_switch(["SNMPv2-SMI::mib-2.17.4.3.1.2"]) do |k,v| #switch port mac address
    #process_switch(["SNMPv2-SMI::mib-2.17.7.1.2.2.1.2.1"]) do |k,v| #switch port mac address
      port_index = @trunk_port_map[v]
      if port_index != nil && @ports[port_index] != nil # && @ports[port_index].bridge_port == false
        s = ""
        k[-6,6].each { |x| s << sprintf("%02X:", x.to_i) }
        s[-1] = ""
        @ports[port_index].port_arp << s
      end
    end
  end
  
  #Process switch is called by snmpwalk to run a single SNMP query to retrieve the OID or OIDS passed in.
  # @param ifTable_columns [String, Array<String>] The OIDS we want to retrieve from this switch.
  def process_switch(ifTable_columns)
    begin
      SNMP::Manager.open(:Host => @ip, :Community => "#{@community}", :Version => :SNMPv2c) do |manager|
        manager.walk(ifTable_columns) do |row|
          row.each do |vb| 
              oid = vb.name.to_s.split('.')
              yield [oid, vb.value.to_s]
          end
        end
      end
    rescue Exception => message
      print "#{@name}: #{message}\n"
    end
  end
  
end

