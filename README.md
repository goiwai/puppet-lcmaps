# lcmaps <!-- omit in toc -->

The module is extended to the original module [cnafsd-lcmaps](https://forge.puppet.com/modules/cnafsd/lcmaps) for specifying some optional parameters like:

- `create_pool_user`: A boolean switch whether creating pool accounts. (`true` by default)
- `create_pool_group`: A boolean switch whether creating a group for pool accounts. (`true` by default)
- `number_of_digits`: A integer value to specify number of digits for the number of pool accounts, e.g. `4` for `user0123`. (`0` by default)
- `first_number`: A integer value to specify the first number of pool accounts, e.g. `4` for creating in start with `user004`. (`1` by default)
- `step_number`: A integer value to specify the step number between pool accounts, e.g. `4` for creating `user001` then `user005`. (`1` by default)

## Table of Contents <!-- omit in toc -->

- [Description](#description)
- [Setup](#setup)
- [Usage](#usage)
- [Limitations](#limitations)

## Description

Install and configure LCMAPS.

## Setup

This module is available on puppet forge:

```shell
puppet module install iwai-lcmaps
```

## Usage

Use this module as follow:

```puppet
include lcmaps
```

If you want to define your own pool accounts use:

```puppet
class { 'lcmaps':
  pools => [
    {
      'name' => 'poolname',
      'size' => 200,
      'base_uid' => 1000,
      'group' => 'poolgroup',
      'gid' => 1000,
      'vo' => 'poolVO',
    },
  ],
}
```

Pool accounts mandatory data:

- name, the name of the pool;
- size, the size of pool;
- base_uid, the first uid of the generated accounts;
- group, the name of the promary group of each account;
- gid, the group id of the primary group;
- vo, the VO name.

Optional parameters:

- groups, non primary groups for each account;
- role, the VOMS role (if not defined is NULL);
- capability, the VOMS capability (if not defined is NULL).
- `create_pool_user`: A boolean switch whether creating pool accounts. (`true` by default)
- `create_pool_group`: A boolean switch whether creating a group for pool accounts. (`true` by default)
- `number_of_digits`: A integer value to specify number of digits for the number of pool accounts, e.g. `4` for `user0123`. (`0` by default)
- `first_number`: A integer value to specify the first number of pool accounts, e.g. `4` for creating in start with `user004`. (`1` by default)
- `step_number`: A integer value to specify the step number between pool accounts, e.g. `4` for creating `user001` then `user005`. (`1` by default)

## Limitations

It works only on RedHat 9 distributions but not on 7 any longer. To install this module for working with UMD-4 on RedHat 7 series, run `puppet module install iwai/lcmaps --version '< 1'`.
