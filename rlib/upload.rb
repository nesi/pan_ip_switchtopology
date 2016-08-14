require 'rubygems'
require 'net/ssh'
require 'net/scp'

#SCP helper
module Upload
  #Do an scp source_file dest_host:dest_file using the keyfile for authentication.
  # @param source_file [String] The file to copy
  # @param dest_file [String] The remote file name we are copying to
  # @param dest_host [String] The host name we are copying to
  # @param keyfile [String] The filename of the id_rsa file we are using to authenticate with.
  def self.upload_file(source_file, dest_file, dest_host, keyfile)
  	begin
  		Net::SCP.start(dest_host, 'root', :keys => [ keyfile ]) do |scp|
  	    scp.upload!( source_file, dest_file )
  		end
    rescue Exception => error
      $stderr.puts "upload_file('#{source_file}', '#{dest_file}', '#{dest_host}', '#{keyfile}') Scp failed with error: #{error}"
    end
  end
end
