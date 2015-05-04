require_relative 'rlib/arp.rb'

module Gen_switch_graph
  
  def self.gen_html_table(switches)
    arp = Arp.new
    switches.each do |n,s| #for each switch
      safe_name = s.name.gsub(/[- ]/,'_')
      filename = "/var/www/html/pan_network/#{safe_name}"
      File.open("#{filename}_t.html", "w") do |fd|
        fd.puts <<-EOF
        <html>
        <head>
        <title>Switch #{s.name}</title>
        <META HTTP-EQUIV="Refresh" CONTENT="30;URL=/pan_network/#{safe_name}_t.html">
        </head>
        <body>
        <h2><a href="/pan_network/#{safe_name}.dot">#{s.name}</a></h2>
        <table border="1">
        EOF

        ports = s.ports.to_a #Change from a hash to an array, so we can use numeric indexes.
        (0...((ports.length+23)/24)).each do |l24| #lots of 24. (1..11) then (2..12), then (13..23) and (14..24)
          (0..1).each do |r| #two rows 
            fd.puts "<tr>"
            (0..1).each do |l12| #left lot of 12 , then right lot of 12
              base = l24*24 + l12*12 + r  #Groups of 24, in pairs of 12 
              (base...(base+12)).step(2) do |i| 
                if(ports[i] != nil)
                  fd.puts "<th width=\"4%\" #{ ports[i][1].up == true ? 'bgcolor="#00FF00"' : '' }>#{ports[i][1].port_name}</th>"
                else #Blank cell requires &nbsp; to render correctly
                  fd.puts "<th>&nbsp;</th>"
                end
              end
              fd.puts "<th width=\"1%\">&nbsp;</th>" if l12 == 0
            end
            fd.puts "</tr>\n<tr>"
            
            (0..1).each do |l12| #left lot of 12 , then right lot of 12
              base = l24*24 + l12*12 + r  #Groups of 24, in pairs of 12 
              (base...(base+12)).step(2) do |i|
                if ports[i] != nil
                  if ports[i][1].bridge_port
                    fd.puts "<td>Switch<br><a href=\"#{ports[i][1].remote_switch_name.gsub(/[- ]/,'_')}_t.html\">#{ports[i][1].remote_switch_name}/#{ports[i][1].remote_port_name}</a></td>"
                  elsif ports[i][1].port_arp.length > 0
                    fd.puts "<td>"
                    ports[i][1].port_arp.each do |mac|
                      fd.puts "#{arp.host(mac)}<br>"
                    end
                    fd.puts "</td>"
                  else #Blank cell requires &nbsp; to render correctly
                    fd.puts "<td>&nbsp;</td>"
                  end
                else #Blank cell requires &nbsp; to render correctly
                  fd.puts "<td>&nbsp;</td>"
                end
              end
              fd.puts "<td>&nbsp;</td>" if l12 == 0
            end
            fd.puts "</tr>"
          end
          fd.puts "<tr><td colspan=\"25\">&nbsp;</td></tr>"
        end
        
        fd.puts "</table>\n</body>\n</html>"
      end
    end
  end
  
  def self.gen_dot(switches)
    arp = Arp.new
    switches.each do |n,s| #for each switch
      safe_name = s.name.gsub(/[- ]/,'_')
      filename = "/var/www/html/pan_network/#{safe_name}"
      File.open("#{filename}.dot", "w") do |fd|
        fd.print <<-EOF2
graph #{safe_name} {
  graph [ fontname = "Times", fontsize=12, dpi=72  ];
  overlap=scale;
  layout=neato
  node [shape=ellipse, fontname = "Lucida", fontsize=12]; 
    "#{safe_name}" [color="green", URL=\"/pan_network/#{safe_name}_t.html\" ];
  node [shape=ellipse, color=black, fontname = "Lucida", fontsize=12];    
EOF2
        
        s.ports.each do |k,p| #for each port on the switch
          if p.bridge_port == false
            # create node entries 
            p.port_arp.each { |a|  fd.puts("  \"#{arp.host(a)}\" [ color=\"green\" ];" ) } 
          end
        end
        fd.print "\n"
        
        s.ports.each do |k,p| #for each port on the switch
          if p.bridge_port == false
            # create edge entries
            p.port_arp.each { |a|  fd.puts("\"#{safe_name}\" -- \"#{arp.host(a)}\" [headlabel=\"#{p.port_number}\", color=\"green\" , len=1.50 ];" ) } 
          end
        end
        fd.print "}\n"
      end
      system("/usr/bin/dot -Tpng -o #{filename}.png -Tcmapx -o #{filename}_map.html #{filename}.dot")
    end
  end
      
  def self.gen_shtml(switches)
    switches.each do |k,s|
      safe_name = s.name.gsub(/[- ]/,'_')
      filename = "/var/www/html/pan_network/#{safe_name}.html"
      if File.exists?(filename) == false
        File.open(filename, "w", 0755) do |fd|
          fd.puts <<-EOF
<html><head>
<title>#{safe_name} Switch</title>
<META HTTP-EQUIV="Refresh" CONTENT="30;URL=/pan_network/#{safe_name}.html">
</head>
<body>
<!--#include virtual="/pan_network/#{safe_name}_map.html" -->
<img src="/pan_network/#{safe_name}.png" BORDER=0 usemap="#{safe_name}" >
</body>
</html>
EOF
        end
      end
    end
  end
  
end