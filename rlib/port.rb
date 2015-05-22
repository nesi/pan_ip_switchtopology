#Port class, for holding port status, and characteristics for the switches in the Switch class. 
class Port
  attr_accessor :port_number, :port_name, :remote_switch_name, :remote_mac, :remote_port_number, :remote_port_name, :bridge_port
  attr_accessor :expected_remote_switch_name, :expected_remote_mac, :expected_remote_port_number, :expected_remote_port_name
  attr_accessor :up
  attr_accessor :port_arp
  
  #Create instance of Port
  # @param port_number [String] Port number on the switch.
  # @return [Port]
  def initialize(port_number)
    @port_number = port_number
    @bridge_port = false
    @port_arp = [] #Array of MAC addresses seen on this port
  end
  
  #Return key attributes as a string (Primary use is debugging)
  # @return [String]
  def to_s
    if @bridge_port == true
      "[#{@port_name}, #{@remote_switch_name}, #{@remote_port_name}, #{@remote_port_number}]"
    else
      "[#{@port_name}, [ #{@port_arp.join(',')} ] ]"
    end
  end
end
