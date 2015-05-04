#!/usr/local/bin/ruby

#Bit of a hack :)
#We need to be able to translate for MAC addresses to IP addresses,
#The quick and dirty way to do this is to first ping every host, to ensure the OS arp table is full,
#Then we run /sbin/arp to read the system table,
#And translate this into a file we can use later.

#Note, the system arp table was a bit small for our cluster, so I increased the table size.
#In /etc/sysctl.conf
#net.ipv4.neigh.default.gc_thresh3 = 4096
#net.ipv4.neigh.default.gc_thresh2 = 2048
#net.ipv4.neigh.default.gc_thresh1 = 1024

class Arp

  def initialize(filename = nil)
    @hosts = []
    arp_file = File.join(File.expand_path(File.dirname(__FILE__)), 'arp.out')
    filename = arp_file if filename == nil
    load_arp(filename)
    @mac_index = {}
    @hosts.each do |h| 
       @mac_index[expand(h[1])] = h
    end
  end
  
  #was generating arp.out file with arp > arp.out, but IB interfaces cause fields to overrun each other
  #Switched to arp -a > arp.out
  def load_arp(filename)
    line = 0
    File.open(filename,'r') do |fd|
      fd.each_line do |l|
        if line != 0 #Firstline of /sbin/arp output is a header.
          #pdu-a2-c-u1 (10.0.116.180) at <incomplete> on eth2
          #? (10.0.111.183) at 6C:AE:8B:E4:CB:00 [ether] on eth2
          #compute-a1-030-ib (10.0.133.30) at A0:00:01:00:FE:80:00:00:00 [infiniband] on ib0
          #compute-a1-045-p (10.0.102.45) at 5C:F3:FC:A8:3E:76 [ether] on eth2
          tokens = l.chomp.strip.split(/\s\s*/)
          if tokens != nil && tokens.length == 7 && tokens[3] != "<incomplete>"
            if tokens[0] == '?'
              @hosts << [tokens[1], tokens[3], tokens[1]] #by IP address
            else
              @hosts << [tokens[0], tokens[3], tokens[1]] #by hostname
            end
          end
        else
          line = 1
        end
      end
    end
  end
  
  def hostname(s)
    if(host = mac_index(s)) != nil
      return host[0]
    else
      return nil
    end
  end
  
  def mac_address?(s) #Mac address in Arp table 
    if(host = mac_index(s)) != nil
      return true
    else
      return false
    end
  end
  
  def ip_address(s)
    if(host = mac_index(s)) != nil
      return host[2]
    else
      return nil
    end
  end
  
  def mac_index(s)
    @mac_index[expand(s)]  
  end  

  def self.host(s)
     a = Arp.new
     a.host(s)
  end
  
  def host(s)
     if s != nil && (n = hostname(s)) != nil && n != ''
       n
     else
       expand(s)
     end
  end

  def expand(s) #want leading 0's, which sometimes we don't always get. Want uppercase, some compare is simpler.
    return nil if s == nil
    as = s.split(':')
    as.collect! { |x| "%02X" % (x.to_i(16)) }
    as.join(':')
  end

  def to_s
    @hosts.to_s
  end

end

#arp = Arp.new
#puts arp.mac_index("34:40:B5:B9:D4:3F")
#puts arp


