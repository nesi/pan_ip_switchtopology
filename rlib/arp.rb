#!/usr/local/bin/ruby
require 'pp' #For debugging

#Bit of a hack :)
#We need to be able to translate for MAC addresses to IP addresses,
#The quick and dirty way to do this is to first ping every host, to ensure the OS arp table is full,
#Then we run /sbin/arp to read the system table,
#And translate this into a file we can use later.
# @see gen_arp_out.sh
#
# @note the system arp table was a bit small for our cluster, so I increased the table size.
#* In /etc/sysctl.conf
#  * net.ipv4.neigh.default.gc_thresh3 = 4096
#  * net.ipv4.neigh.default.gc_thresh2 = 2048
#  * net.ipv4.neigh.default.gc_thresh1 = 1024
#
class Arp

  attr_accessor :hosts     #Array of the hosts loaded from the arp.out file.
  
  #Create an instance of Arp
  # @return [Arp]
  # @param filename [String] Override the default arp.out file ('../conf/arp.out')
  def initialize(filename = nil)
    @hosts = []
    #Default ARP table filename is in the conf directory, relative to this script
    default_directory = File.expand_path(File.dirname(__FILE__)) + '/../conf/'
    default_filename = 'arp.out'
    #ARP table file can be overridden if filename is specified.
    filename = File.join(default_directory, 'arp.out') if filename == nil
    load_arp(filename)
    @mac_index = {}
    @hosts.each do |h| 
       @mac_index[expand(h[1])] = h
    end
  end
  
  #was generating arp.out file with arp > arp.out, but IB interfaces cause fields to overrun each other
  #Switched to arp -a > arp.out
  # @see gen_arp_out.sh
  def load_arp(filename)
    line = 0
    File.open(filename,'r') do |fd|
      fd.each_line do |l|
        #Firstline of /sbin/arp -a output is a header.
        if line != 0 
          # @example lines in arp -a output 
          #    pdu-a2-c-u1 (10.0.116.180) at <incomplete> on eth2
          #    ? (10.0.111.183) at 6C:AE:8B:E4:CB:00 [ether] on eth2
          #    compute-a1-030-ib (10.0.133.30) at A0:00:01:00:FE:80:00:00:00 [infiniband] on ib0
          #    compute-a1-045-p (10.0.102.45) at 5C:F3:FC:A8:3E:76 [ether] on eth2
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
  
  #Find the hostname from the MAC address.
  # @param mac_address [String]  MAC address of the target.
  # @return [String,nil] Hostname associated with the MAC address, or nil if it isn't known. 
  def hostname(mac_address)
    if(host = mac_index(mac_address)) != nil
      return host[0]
    else
      return nil
    end
  end
  
  #Test to see if MAC address exists in our DB
  # @param mac_address [String]  MAC address of the target.
  # @return [Boolean] True if MAC address is known to us. 
  def mac_address?(mac_address) 
    if(host = mac_index(mac_address)) != nil
      return true
    else
      return false
    end
  end
  
  #Find the ip address from the MAC address.
  # @param mac_address [String]  MAC address of the target.
  # @return [String,nil] IP address associated with the MAC address, or nil if it isn't known. 
  def ip_address(mac_address)
    if(host = mac_index(mac_address)) != nil
      return host[2]
    else
      return nil
    end
  end
  
  #Find the DB entry from the MAC address.
  # @param mac_address [String]  MAC address of the target.
  # @return [String,nil] DB entry associated with the MAC address, or nil if it isn't known. 
  def mac_index(mac_address)
    @mac_index[expand(mac_address)]  
  end  

  #Class Level. Find the hostname from the MAC address.
  # @param mac_address [String]  MAC address of the target.
  # @return [String,nil] Hostname associated with the MAC address, or nil if it isn't known. 
  def self.host(mac_address)
     a = Arp.new
     a.host(mac_address)
  end
  
  #Find the hostname from the MAC address.
  # @param mac_address [String]  MAC address of the target.
  # @return [String] Hostname associated with the MAC address, or the MAC address if it isn't known. 
  def host(mac_address)
     if mac_address != nil && (n = hostname(mac_address)) != nil && n != ''
       n
     else
       expand(mac_address)
     end
  end

  #Standardise the MAC address string format.
  # @param mac_address [String]  MAC address of the target.
  # @return  [String]  MAC address of the target with Uppercase, two digit Hexadecimal numbers, separated with ':'s.
  def expand(mac_address) #want leading 0's, which sometimes we don't always get. Want uppercase, some compare is simpler.
    return nil if s == nil
    as = mac_address.split(':')
    as.collect! { |x| "%02X" % (x.to_i(16)) }
    as.join(':')
  end

  #Return the ARP DB as a string.
  # @return [String] Arp DB.
  def to_s
    @hosts.to_s
  end
  
  #Class method to run self test, by reading the arp.out file and dumping the Arp DB.
  def self.test
    arp = Arp.new
    #Test for a know host, indexed by the MAC address.
    puts "arp.mac_index('34:40:B5:B9:D4:3F') => #{arp.mac_index("34:40:B5:B9:D4:3F")}"
    puts
    #Dump the whole ARP @hosts array.
    puts "Dump of entire Arp hosts Array, as loaded from conf/arp.out"
    pp arp.hosts
  end

end

#Self Test
#Arp.test


