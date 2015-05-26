#Switch Topology

`switchtopology/run.rb`

Using the switches defined in *conf/switches.json*, snmp queries are run:
* snmp bridge mib queries determine switches links verses host links.
* Port status is queried
* Manual links are added for the links to ITS, which we can't query the status of.

A png, with HTML map file, is produced using neato, in the *html_directory/html_network_directory* directory
shtml files are then added to combine the references to the png and map files

`switchtopology/gen_arp_out.sh`

This must be run when the host file changes, or a host's MAC address changes (eg after a HW fault).
It creates *conf/arp.out* , which holds a map of MAC address to host details.

##Class Documentation

http://nesi.github.io/pan_ip_switchtopology/

##Work to do

Need to record the expected state, and compare against it, so I can highlight changes and faults.

##Example *conf/config.json*, 
```
{
"switch_config": "conf/switches.json",    //Definition of switches of interest.
"base_directory": "/var/pan/iblinkinfo",  //Directory we put temporary files
"html_directory": "/var/www/html",        //Base directory of the web server
"html_network_directory": "pan/network",  //Directory in web directory, that we want to store html & pics
"neato_base_filename": "pan_private_net", //Base name for files created by neato (they will have .html .dot etc added)
"neato_remove_tmp_files": false             //Do we clean up after ourselves (Set to false for debugging)
}
```

##Example *conf/switches.json*
```
{
//Define the local switches we are interesed in.
"switches": [ 
	  //hostname     ,  IP Address  , MAC Address       , Make, Model,  Position, Snmp-community, Use-SNMP

	  //Two 10G switches connecting to ITS network (and to REANNZ)
	  [ "bnt-a2-001-m", "10.0.1.229", "08:17:F4:5E:62:00", "bnt", "G8124", "external", "secret", true ], 
	  [ "bnt-a2-002-m", "10.0.1.230", "08:17:F4:5E:50:00", "bnt", "G8124", "external", "secret", true ], 

	  //Two private network"s core 10G switches
	  [ "bnt-c2-004-m", "10.0.1.247", "6C:AE:8B:E4:C5:00", "bnt", "G8124", "private_core", "secret", true ], //C2-U41 Core
	  [ "bnt-c2-003-m", "10.0.1.246", ["6C:AE:8B:E4:CB:00","6C:AE:8B:E4:CB:FE"], "bnt", "G8124", "private_core", "secret", true ], //C2-U42 Core

	  //In O15 test rack
	  [ "Pica8 Switch", "10.0.1.147", ["E8:9A:8F:FB:C4:73","E8:9A:8F:FB:C4:74"], "pica8", "Pronto 3290", "private_leaf", true  ],
	  //"tdc-o18-u48-m" in the hosts file and actually in o15 rack

	  //In idataplex rack switches
	  [ "exmgmt-a1-b4-m", "10.0.1.225", "08:17:F4:C3:65:00", "bnt", "G8000", "private_leaf", "secret", true ],
	  [ "exmgmt-a1-b6-m", "10.0.1.226", "08:17:F4:C3:5F:00", "bnt", "G8000", "private_leaf", "secret", true ],
	  [ "exmgmt-a1-d4-m", "10.0.1.227", "08:17:F4:C3:6A:00", "bnt", "G8000", "private_leaf", "secret", true  ],
	  [ "exmgmt-a1-d6-m", "10.0.1.228", "08:17:F4:C3:AC:00", "bnt", "G8000", "private_leaf", "secret", true  ],
	  [ "exmgmt-b1-b6-m", "10.0.1.237", "6C:AE:8B:E0:20:00", "bnt", "G8000", "private_leaf", "secret", true  ],
	  [ "exmgmt-b1-d6-m", "10.0.1.238", "6C:AE:8B:E0:3F:00", "bnt", "G8000", "private_leaf", "secret", true  ],
	  [ "exmgmt-c3-b2-m", "10.0.1.242", "74:99:75:49:65:00", "bnt", "G8052", "private_leaf", "secret", true ],
	  [ "exmgmt-c3-d2-m", "10.0.1.243", "74:99:75:49:63:00", "bnt", "G8052", "private_leaf", "secret", true ],
	  [ "exmgmt-a4-b6-m", "10.0.1.244", "6C:AE:8B:E3:34:00", "bnt", "G8000", "private_leaf", "secret", true  ],
	  [ "exmgmt-a4-d6-m", "10.0.1.245", "6C:AE:8B:E3:27:00", "bnt", "G8000", "private_leaf", "secret", true  ],
	  [ "exmgmt-a5-b4-m", "10.0.1.148", "74:99:75:3f:7a:00", "bnt", "G8052", "private_leaf", "secret", true ],
	  [ "exmgmt-a5-d4-m", "10.0.1.149", "74:99:75:3f:8d:00", "bnt", "G8052", "private_leaf", "secret", true  ],
	  [ "exmgt-c2-u40-m", "10.0.1.146", ["78:FE:3D:E9:52:80","78:FE:3D:E9:52:81"], "juniper", "ex3300-24t", "private_leaf", "secret", true  ],
  
	  //Department nodes in test rack.
	  //These are on dev network, but are visible via private vlans on above switches.
	  [ "exmgt-o18-u42-m", "10.0.1.144", "50:C5:8D:A9:D9:40", "juniper", "ex3300-24t", "private_leaf", "secret", true  ]
	  //[ "exmgt-o15-u41", "192.168.1.144", "78:FE:3D:E9:5E:00", "juniper", "ex4300-24t", "private_leaf", "secret", false ], //connected to port 43 of exmgmt-a5-b4-m
	  //[ "tdc-o18-u46-m_dev_switch", "192.168.1.145", "78:FE:3D:E9:73:40", "juniper", "ex4300-24t", "private_leaf", "secret", false  ] //Connected to port 47 of the Pica8 
  ]
}
```

##External Requirements

Runs under Ruby (at least 1.9)
Needs gem snmp to run
  `gem install snmp`

Need gem yard to generate class documentation from the source comments.
  `gem install yard`

