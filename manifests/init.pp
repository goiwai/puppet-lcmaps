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
#   The Array of pool accounts.
#
# @param create_pool_user
#   If true (default), attempts to create pool accounts.
#   If false, skip creating pool accounts -- a special switch for KEKCC, where the necessary pool accounts have already been created.
#
# @param create_pool_group
#   If true (default), attempts to create pool accounts.
#   If false, skip creating groups for pool accounts -- a special switch for KEKCC, where the necessary pool accounts have already been created.
#
# @param generate_gridmapfile
#
# @param gridmapfile_file
#
# @param generate_groumapfile
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
# @param manage_lcas_db_file
#   If true (default) use as /etc/lcas/lcas.db the file specified with lcas_db_file.
#   If false, file is not managed by this class.
#
# @param lcas_db_file
#   The path of the lcas.db to copy into /etc/lcas/lcas.db. Default: puppet:///modules/storm/etc/lcas/lcas.db
#
# @param manage_lcas_ban_users_file
#   If true (default) use as /etc/lcas/ban_users.db the file specified with lcas_ban_users_file.
#   If false, file is not managed by this class.
#
# @param lcas_ban_users_file
#   The path of the ban_users.db to copy into /etc/lcas/ban_users.db. Default: puppet:///modules/storm/etc/lcas/ban_users.db
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
  Boolean $create_pool_user,
  Boolean $create_pool_group,

  Boolean $generate_gridmapfile,
  String $gridmapfile_file,

  Boolean $generate_groupmapfile,
  String $groupmapfile_file,

  Boolean $manage_lcmaps_db_file,
  String $lcmaps_db_file,

  Boolean $manage_lcas_db_file,
  String $lcas_db_file,

  Boolean $manage_lcas_ban_users_file,
  String $lcas_ban_users_file,

  Boolean $manage_gsi_authz_file,
  String $gsi_authz_file,

) {

  $lcamps_rpms = ['lcmaps', 'lcmaps-without-gsi', 'lcmaps-plugins-basic', 'lcmaps-plugins-voms']
  package { $lcamps_rpms:
    ensure => latest,
  }

  $lcas_rpms = ['lcas', 'lcas-lcmaps-gt4-interface', 'lcas-plugins-basic', 'lcas-plugins-voms']
  package { $lcas_rpms:
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
    if has_key($pool, 'groups') {
      $pool_groups = $pool['groups']
    } else {
      $pool_groups = [$pool_group]
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

    range('1', $pool_size).each | $id | {

      $id_str = sprintf('%03d', $id)
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
        ensure  => present,
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
      ensure  => present,
      content => template($gridmapfile_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  } else {
    file { $gridmapfile:
      ensure => present,
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
      ensure  => present,
      content => template($groupmapfile_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  } else {
    file { $groupmapfile:
      ensure => present,
      source => $groupmapfile_file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
    }
  }

  if $manage_gsi_authz_file {
    file { '/etc/grid-security/gsi-authz.conf':
      ensure => present,
      source => $gsi_authz_file,
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
    }
  }

  if $manage_lcmaps_db_file {
    file { '/etc/lcmaps/lcmaps.db':
      ensure  => present,
      source  => $lcmaps_db_file,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package[$lcamps_rpms],
    }
  }

  if $manage_lcas_db_file {
    file { '/etc/lcas/lcas.db':
      ensure  => present,
      source  => $lcas_db_file,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package[$lcas_rpms],
    }
    if $manage_lcas_ban_users_file {
      file { '/etc/lcas/ban_users.db':
        ensure  => present,
        source  => $lcas_ban_users_file,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        require => File['/etc/lcas/lcas.db'],
      }
    }
  }
}
