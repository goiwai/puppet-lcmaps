# @summary Utility class used to install LCMAPS and LCAS and configure mapping software and files. 
#
# @param gridmapdir_owner
#   The owner of /etc/grid-security/gridmapdir
#
# @param gridmapdir_group
#   The group of /etc/grid-security/gridmapdir
#
# @param gridmapdir_mode
#   The permissions on /etc/grid-security/gridmapdir
#
# @param pools
#   The hash of pool accounts. Some optional parameters are extended to
#   the original module [cnafsd-lcmaps](https://forge.puppet.com/modules/cnafsd/lcmaps):
#   See also [`pooldata.pp`](pooldata.pp) for a declaration of the array parameters.
# 
#     `roles`:
#        Optional[Array[String]]: if `role` is not set AND roles is set, 
#        write out multiple roles for pool accounts and a single group in:
#        `/etc/grid-security/ggrid-mapfile`
#        `/etc/grid-security/groupmapfile`
#     `create_pool_user`:
#        If true (default), attempts to create pool accounts.
#        If false, skip creating pool accounts -- a special switch for KEKCC, where the necessary pool accounts have already been created.
#     `create_pool_group`:
#        If true (default), attempts to create a groupd for pool accounts.
#        If false, skip creating groups for pool accounts
#        -- a special switch for KEKCC, where the necessary pool accounts have already been created.
#     `number_of_digits`:
#        If 0 (default), attempts to define the minimum digit for pool accounts, e.g. three digits for 100 pool accounts like user012.
#        If greater than 0, attempts to define the number of digits as specified, e.g. user0123, while setting 4 of number_of_digits.
#     `first_number`:
#        Creates a pool account starting with the first_number like user001 while setting 1 of first_number.
#     `step_number`:
#        A step value of pool accounts. Creates a pool account user001, then user003 for setting 2 of step_number.
#
# @param generate_gridmapfile
#
# @param gridmapfile_file
#
# @param generate_groupmapfile
#
# @param groupmapfile_file
#
# @param manage_lcmaps_db_file
#   If true (default) use as /etc/lcmaps/lcmaps.db the file specified with lcmaps_db_file.
#   If false, file is not managed by this class.
#
# @param lcmaps_db_file
#   The path of the lcmaps.db to copy into /etc/lcmaps/lcmaps.db. Default: puppet:///modules/storm/etc/lcmaps/lcmaps.db
#
# @param manage_gsi_authz_file
#   If true (default) use as /etc/grid-security/gsi-authz.conf the file specified with gsi_authz_file.
#   If false, file is not managed by this class.
#
# @param gsi_authz_file
#   The path of the gsi-authz.conf to copy into /etc/grid-security/gsi-authz.conf. Default: puppet:///modules/storm/etc/grid-security/gsi-authz.conf
#
# @example Example of usage
#    class { 'lcmaps':
#      pools => [{
#        'name' => 'dteam',
#        'size' => 20,
#        'base_uid' => 7100,
#        'group' => 'dteam',
#        'gid' => 7100,
#        'vo' => 'dteam',
#      }],
#      manage_lcas_ban_users_file => false,
#    }
#
class lcmaps (

  String $gridmapdir_owner,
  String $gridmapdir_group,
  String $gridmapdir_mode,

  Array[Lcmaps::PoolData] $pools,

  Boolean $generate_gridmapfile,
  String $gridmapfile_file,

  Boolean $generate_groupmapfile,
  String $groupmapfile_file,

  Boolean $manage_lcmaps_db_file,
  String $lcmaps_db_file,

  Boolean $manage_gsi_authz_file,
  String $gsi_authz_file,

) {
  $lcamps_rpms = ['lcmaps', 'lcmaps-without-gsi']
  package { $lcamps_rpms:
    ensure => latest,
  }

  $gridmapdir = '/etc/grid-security/gridmapdir'

  if !defined(File[$gridmapdir]) {
    file { $gridmapdir:
      ensure  => directory,
      owner   => $gridmapdir_owner,
      group   => $gridmapdir_group,
      mode    => $gridmapdir_mode,
      recurse => true,
    }
  }

  $pools.each | $pool | {
    # mandatories
    $pool_name = $pool['name']
    $pool_group = $pool['group']
    $pool_gid = $pool['gid']
    $pool_vo = $pool['vo']
    $pool_base_uid = $pool['base_uid']
    $pool_size = $pool['size']

    # optionals
    if ('groups' in $pool) {
      $pool_groups = $pool['groups']
    } else {
      $pool_groups = [$pool_group]
    }
    if ('create_pool_user' in $pool) {
      $create_pool_user = $pool['create_pool_user']
    } else {
      $create_pool_user = true
    }
    if ('create_pool_group' in $pool) {
      $create_pool_group = $pool['create_pool_group']
    } else {
      $create_pool_group = true
    }
    if ('number_of_digits' in $pool) {
      $number_of_digits = $pool['number_of_digits']
    } else {
      $number_of_digits = 0
    }
    if ('first_number' in $pool) {
      $first_number = $pool['first_number']
    } else {
      $first_number = 1
    }
    if ('step_number' in $pool) {
      $step_number = $pool['step_number']
    } else {
      $step_number = 1
    }

    if $create_pool_group {
      group { $pool_group:
        ensure => present,
        gid    => $pool_gid,
      }
      $pool_groups.each | $g | {
        if !defined(Group[$g]) {
          group { $g:
            ensure => present,
          }
        }
      }
    }

    debug("\$number_of_digits=${number_of_digits}")
    debug("\$first_number=${first_number}")
    $n = $first_number
    $pool_numbers = range(0, $pool_size - 1).map | $i | {
      $first_number + $step_number * $i
    }
    debug("\$pool_numbers=${pool_numbers}")
    # $last_number = $pool_numbers[-1]
    if ($number_of_digits == 0) {
      $digit = String($pool_numbers[-1]).length
    } else {
      $digit = $number_of_digits
    }
    debug("\$digit=${digit}")
    $id_format = "%0${digit}d"
    debug("\$id_format=${id_format}")

    $pool_numbers.each | $id | {
      $id_str = sprintf($id_format, $id)
      $name = "${pool_name}${id_str}"

      if $create_pool_user {
        user { $name:
          ensure     => present,
          uid        => $pool_base_uid + $id,
          gid        => $pool_gid,
          groups     => $pool_groups,
          comment    => "Mapped user for ${pool_vo}",
          managehome => true,
          require    => [Group[$pool_group]],
        }
      }

      file { "${gridmapdir}/${name}":
        ensure  => file,
        require => File[$gridmapdir],
        owner   => $gridmapdir_owner,
        group   => $gridmapdir_group,
      }
    }
  }

  $gridmapfile='/etc/grid-security/grid-mapfile'
  $gridmapfile_template='lcmaps/etc/grid-security/grid-mapfile.erb'

  if $generate_gridmapfile {
    file { $gridmapfile:
      ensure  => file,
      content => template($gridmapfile_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  } else {
    file { $gridmapfile:
      ensure => file,
      source => $gridmapfile_file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
    }
  }

  $groupmapfile='/etc/grid-security/groupmapfile'
  $groupmapfile_template='lcmaps/etc/grid-security/groupmapfile.erb'

  if $generate_groupmapfile {
    file { $groupmapfile:
      ensure  => file,
      content => template($groupmapfile_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  } else {
    file { $groupmapfile:
      ensure => file,
      source => $groupmapfile_file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
    }
  }

  if $manage_gsi_authz_file {
    file { '/etc/grid-security/gsi-authz.conf':
      ensure => file,
      source => $gsi_authz_file,
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
    }
  }

  if $manage_lcmaps_db_file {
    file { '/etc/lcmaps/lcmaps.db':
      ensure  => file,
      source  => $lcmaps_db_file,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package[$lcamps_rpms],
    }
  }
}
