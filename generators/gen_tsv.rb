require_relative '../rlib/arp.rb'

#Create a tab separated file from the data
#Useful as a Command Line view
module TSV
  #Output TSV file.
  # @param [Hash] switches
  # @param [String] target_file write output to this file. defaults to stdout.
  def self.gen(switches, target_file=nil)
    arp = Arp.new
    fd = target_file == nil ? $stdout : File.open(target_file, "w")
    begin
      switches.each do |n, s| #For each switch
        s.ports.each do |k,p| #For each port on the switch
          begin
            if p != nil && p.remote_switch_name != nil && switches[p.remote_switch_name] != nil && switches[p.remote_switch_name].ports[p.port_number] == nil
              #puts "#{p.remote_switch_name} #{p.port_number} #{p.remote_port_name}"
              switches[p.remote_switch_name].ports[p.port_number] = Port.new(p.port_number)
              switches[p.remote_switch_name].ports[p.port_number].port_name = "#{p.port_number}/#{p.remote_port_name}"
              switches[p.remote_switch_name].ports[p.port_number].remote_switch_name = s.name
              switches[p.remote_switch_name].ports[p.port_number].remote_port_name = p.port_name
              switches[p.remote_switch_name].ports[p.port_number].remote_port_number = p.port_number
              switches[p.remote_switch_name].ports[p.port_number].remote_mac = s.mac
            end
          rescue Exception => error
            puts "Switch #{s.name} Port #{p.port_name} : #{error}"
          end
        end
      end
      switches.each do |n, s| 
        s.ports.each do |k,p|
          if p != nil
            begin
              if p.bridge_port
                fd.puts "Switch:\t#{s.name}\tPort:\t#{p.port_number}\t#{p.port_name}\tUplink:\t#{p.remote_switch_name}\t#{p.remote_port_number}"
              else
                p.port_arp.each do |pa|
                  fd.puts "Switch:\t#{s.name}\tPort:\t#{p.port_number}\t#{p.port_name}\tHost:\t#{arp.host(pa)}\t#{pa}"
                end
              end
            rescue Exception => error
              puts "Switch #{s.name} Port #{p.port_name} : #{error}"
            end
          end
        end
      end
    ensure
      fd.close if fd != nil && fd != $stdout 
    end
  end
end
