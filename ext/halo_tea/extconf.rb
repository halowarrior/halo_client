require 'mkmf'

RbConfig::CONFIG['DLEXT'] = 'so'
create_makefile 'halo_tea/halo_tea'