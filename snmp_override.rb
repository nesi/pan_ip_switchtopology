#Overrides the ruby snmp modules Manager.walk, to allow non-increasing OIDs
#We see non-increasing OIDS from switches, where the tack on a MAC or IP address to the base OID.

module SNMP
  class Manager
    def walk(object_list, index_column=0)
      raise ArgumentError, "expected a block to be given" unless block_given?
      vb_list = @mib.varbind_list(object_list, :NullValue)
      raise ArgumentError, "index_column is past end of varbind list" if index_column >= vb_list.length
      is_single_vb = object_list.respond_to?(:to_str) || object_list.respond_to?(:to_varbind)
      start_list = vb_list
      start_oid = vb_list[index_column].name
      last_oid = start_oid
      loop do
        vb_list = get_next(vb_list).vb_list
        index_vb = vb_list[index_column]
        break if EndOfMibView == index_vb.value
        stop_oid = index_vb.name
        break unless stop_oid.subtree_of?(start_oid)
        last_oid = stop_oid
        if is_single_vb
          yield index_vb
        else
          vb_list = validate_row(vb_list, start_list, index_column)
          yield vb_list
        end
      end
    end
  end
end
  