#Generate a Graphviz neato file, showing the switches and the interconnections between them.
#We put the core switches at the center, and arrange the other switches in a 180 degree arc
#Lastly, we run the resulting file through neato to get a png.
class Neato
  
  #Creates neato (Graphviz) diagram as a png.
  # @param switches [Hash] Hash indexed by name of the switch, pointing to Switch records for the switches we defined in conf/switches.json.
  # @param html_base_directory [String] The system web server's root directory
  # @param web_directory [String] The directory, relative to the web server dir, we will write our output to (.dot, .png, .html)
  # @param the_file [String] The basename of the files we write to (We will add a .dot, .png, .html, ...)
  # @param remove_the_dot_file [Boolean] Set to false if you are debugging, and the temporary .dot file will not be removed
  def self.gen_neato(switches, html_base_directory="/tmp/", web_directory='.', the_file='neato', remove_the_dot_file = true)
    File.open("#{html_base_directory}/#{web_directory}/#{the_file}.dot", "w") do |fd|
      #300dpi 8x10 with 0.5" margins
      x = 10 #These units seem to be arbitrary. 
      y = 10
      centre = [x/2,y/2] #Center of the arc . 

      #Switch elipse dimensions
      height = 0.5 
      width = height * 16 / 9

      #spacing 0.5
      spacing = 0.5

      #Position the Private network Core Switches
      bnt_c2_003_m = [centre[0]-spacing-width, centre[1]]
      bnt_c2_004_m = [centre[0]+spacing+width, centre[1]]

      #The external and private core switch node definitions. Set absolute position at bottom of page.
      fd.puts <<-EOF
        graph g {
          overlap=scale;
          layout=neato

          "bnt-a2-001-m"       [height=#{height},  pos="#{bnt_c2_003_m[0]},#{bnt_c2_003_m[1]-height}!",   width=#{width}, color=#{(color = switch_status('bnt-a2-001-m')) ? color  : 'black'}, URL=\"/#{web_directory}/bnt_a2_001_m_t.html\"]; 
          "bnt-a2-002-m"       [height=#{height},  pos="#{bnt_c2_004_m[0]},#{bnt_c2_004_m[1]-height}!",   width=#{width}, color=#{(color = switch_status('bnt-a2-002-m')) ? color  : 'black'}, URL=\"/#{web_directory}/bnt_a2_002_m_t.html\"];

          "bnt-c2-003-m"       [height=#{height},  pos="#{bnt_c2_003_m[0]},#{bnt_c2_003_m[1]}!",   width=#{width}, color=#{(color = switch_status('bnt-c2-003-m')) ? color  : 'black'}, URL=\"/#{web_directory}/bnt_c2_003_m_t.html\"];
          "bnt-c2-004-m"       [height=#{height},  pos="#{bnt_c2_004_m[0]},#{bnt_c2_004_m[1]}!",   width=#{width}, color=#{(color = switch_status('bnt-c2-004-m')) ? color  : 'black'}, URL=\"/#{web_directory}/bnt_c2_004_m_t.html\"];
EOF

      angle = Math::PI/(switches.length + 1 - 3) #Don't include two external and two private_core switches in this count. Bnt-a2-001-m not included, as snmp failing.
      r = 5 
      t = 1
     
      #Create a node record for each leaf switch, with an absolute position, equally spaced around a 180deg arc.
      switches.each do |k,s|
        if s.category == "private_leaf"
          point = [r * Math.cos(t*angle) + centre[0], r * Math.sin(t*angle) + centre[1]  ]
          fd.puts "          \"#{s.name}\" [height=#{height}, pos=\"#{point[0]},#{point[1]}!\", width=#{width}, color=#{(color = switch_status('#{s.name}')) ? color  : 'black'}, URL=\"/#{web_directory}/#{s.name.gsub(/[- ]/,'_')}_t.html\"]; "
          t = t + 1
        end
      end

      processed_switch = {}
     # processed_switch["bnt-a2-001-m"] = true #SNMP failing, so manually added.

      switches.each do |k1,s|
        if s.category == "external" 
          processed_switch[s.name] = true
          s.ports.each do |k2,p|
            if p.remote_switch_name != nil && #We have a remote switch 
              switches[p.remote_switch_name] != nil && #the remote switch is in our list of switches
              p.remote_port_name !~ /MGT[AB]/ && p.port_name !~ /MGT[AB]/ && #The port isn't connecting to a management port
              processed_switch[p.remote_switch_name] == nil
                fd.puts "\"#{s.name}\" -- \"#{p.remote_switch_name}\" [style=\"setlinewidth(2)\" len=1.0 color=\"green\"  headlabel=\"#{p.remote_port_name}:#{p.port_name}\" ];"
            end
          end
        end
      end
      fd.puts

      switches.each do |k1,s|
        if s.category == "private_core" 
          processed_switch[s.name] = true
          s.ports.each do |k2,p|
            if p.remote_switch_name != nil && #We have a remote switch 
              switches[p.remote_switch_name] != nil && #the remote switch is in our list of switches
              p.remote_port_name !~ /MGT[AB]/ && p.port_name !~ /MGT[AB]/ && #The port isn't connecting to a management port
              processed_switch[p.remote_switch_name] == nil
                fd.puts "\"#{s.name}\" -- \"#{p.remote_switch_name}\" [style=\"setlinewidth(2)\" len=1.0 color=\"green\"  headlabel=\"#{p.remote_port_name}:#{p.port_name}\" labeldistance=10 labelangle=0.0 ];"
            end
          end
        end
      end
      fd.puts
      
      switches.each do |k1,s|
        if s.category == "private_leaf"
          processed_switch[s.name] = true
          s.ports.each do |k2,p|
            if p.remote_switch_name != nil && #We have a remote switch 
              switches[p.remote_switch_name] != nil && #the remote switch is in our list of switches
              p.remote_port_name !~ /MGT[AB]/ && p.port_name !~ /MGT[AB]/ && #The port isn't connecting to a management port
              processed_switch[p.remote_switch_name] == nil              
                fd.puts "\"#{p.remote_switch_name}\" -- \"#{s.name}\" [style=\"setlinewidth(2)\" len=1.0 color=\"green\"  headlabel=\"#{p.remote_port_name}:#{p.port_name}\"  ];"
            end
          end
        end
      end
      
      fd.puts "  }"
    end
    
    system("/usr/bin/dot -Tpng -o #{html_base_directory}/#{web_directory}/#{the_file}.png -Tcmapx -o #{html_base_directory}/#{web_directory}/#{the_file}_map.html #{html_base_directory}/#{web_directory}/#{the_file}.dot")    
    File.unlink("#{html_base_directory}/#{web_directory}/#{the_file}.dot") if remove_the_dot_file
  end
  
  #Query the switch status, returning a status colour for the diagram. (Not completed, so always returns 'green' for Ok)
  # @param switch [Switch] An individual switch, from which we determine the status.
  # @return [String] A colour name, for use in generating the diagram.
  def self.switch_status(switch)
    'green'
  end
end
