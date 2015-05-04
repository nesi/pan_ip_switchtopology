#Generate a Graphviz dot file, showing the switches and the interconnections between them.
class Dot
  def initialize(target_file, switches)
    @switches = switches
    @links = {}
    File.open(target_file, "w") do |fd|
      put_header(fd) #dot file lead in.
      put_switches(fd) #The switch definitions
      put_rank(fd) #Group the core switches
      put_links(fd) #Output the interswitch link definitions
      fd.puts "}" #Closing } for the dot file.
    end
  end
  
  #Dot file header 
  def put_header(fd)
    fd.puts <<-EOF
digraph g {
ranksep = 2.0; splines=false;
graph [
];
node [
fontsize = "16"
shape = "ellipse"
];
edge [
];
EOF
  end
  
  #Dot file body, for each switch
  def put_switches(fd)
    @switches.each do |n, s|
      s.ports.each do |k,p|
        if p.remote_switch_name != nil && @switches[p.remote_switch_name] != nil  && @switches[p.remote_switch_name].ports[p.port_number] == nil
          #puts "#{p.remote_switch_name} #{p.port_number} #{p.remote_port_name}"
          @switches[p.remote_switch_name].ports[p.port_number] = Port.new(p.port_number)
          @switches[p.remote_switch_name].ports[p.port_number].port_name = "#{p.port_number}/#{p.remote_port_name}"
          @switches[p.remote_switch_name].ports[p.port_number].remote_switch_name = s.name
          @switches[p.remote_switch_name].ports[p.port_number].remote_port_name = p.port_name
          @switches[p.remote_switch_name].ports[p.port_number].remote_port_number = p.port_number
          @switches[p.remote_switch_name].ports[p.port_number].remote_mac = s.mac
        end
      end
    end
    @switches.each do |n, s|
      fd.puts "\"#{s.name}\" ["
      fd.print "label = \""
      out = []
      out << "<h0> #{s.name}"
      s.ports.each do |k,p|
        if p.remote_switch_name != nil && @switches[p.remote_switch_name] != nil && p.remote_port_name !~ /MGT[AB]/ && p.port_name !~ /MGT[AB]/
          out << "<p#{p.port_number}> #{p.port_name}"
          @links["#{s.name}:p#{p.port_number}"] = "\"#{s.name}\":p#{p.port_number} -> \"#{p.remote_switch_name}\":p#{p.remote_port_number}"   #if @links["#{p.remote_switch_name}:p#{p.remote_port_number}"] == nil
        end
      end
      fd.puts "#{out.join(' | ')}\""
      fd.puts "shape = \"record\"\n];"
    end
  end
  
  #Ensure the core switches are grouped together
  def put_rank(fd)
    fd.puts '{ rank=same; "bnt-a2-001-m" ; "bnt-a2-002-m"; }' #External BNTs
    fd.puts '{ rank=same; "bnt-c2-003-m" ; "bnt-c2-004-m"; }' #Private Core
  end

  #
  def put_links(fd)
    i = 0
    @links.each { |k,v| fd.puts "#{v} [ id = #{i} ];"; i = i + 1}
  end
  
end


