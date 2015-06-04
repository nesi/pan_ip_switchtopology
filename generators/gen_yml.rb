#Encapsulates methods to generate YML from the Switch records.
module YML
  #Output Yaml file recording port status for a switch
  # @param [Hash] switches
  # @param [String] target_file write output to this file.
  def self.gen(switches, target_file='iblinkinfo.yml')
    File.open(target_file, "w") do |fd|
      port_status = {}
      switches.switch_location.each do |k,loc|
        switch_ports = []
        v = ib.switches[k]
        if v != nil 
          (1..loc[4]).each do |i|
            row = []
            l = ib.location[v[i][9]] #Connected host / switch
            row[0] = v[i][9] #Remote host attached to port
            row[1] = v[i][7] #Remote Port Number
            if(l != nil && ib.switches[v[i][9]] != nil)
              row[2] = "" #Alternate name
              #fd.print "\t-"
            else
              row[2] = "#{l == nil ? v[i][9] : "#{l[2]}/P#{"%02d"%v[i][7]}"}" #Alternate name
            end
            switch_ports[i] = row
          end
          port_status[k] = switch_ports
        end
      end
      fd.write(port_status.to_yaml)
    end
  end
end

