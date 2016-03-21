# node_package 3.0.0
## Security Improvements
### Introduction
### Security Advisory dated March 1, 2016
It was [recently reported](http://docs.basho.com/riak/latest/community/product-advisories/codeinjectioninitfiles/)
that, if a user could gain access to the `riak` user (or, in node_package
parlance, the `package_install_user`), that user would then
have write access to init scripts that are generally run as `root`, exposing an
escalation of privileges attack where said user could then get the `root` user
to execute a script that could allow the original user to become `root` on the
system.

### Additional Security Review

After the security advisory was initially released, a more thorough review of
all of the `node_package`-generated packages was conducted. This review found
some additional cases of files or directories owned by the
`package_install_user` or `package_install_group` that could also potentially
allow a someone with access to run in the context of that user account to
overwrite files that may later be executed by `root`. This release of
`node_package` has significantly tightened the ownership and permissions of
files installed, in most cases following the target systems' conventions
(`root:root`, `root:bin`, `root:wheel`) for all files that are executable or
could be executed, including library files that the packaged application may
read.

The [node_package](https://github.com/basho/node_package) library is used to
build deployable packages for Erlang applications that target many operating
systems. Node_package supports building installation packages for:

- Redhat / Fedora and variants
- Debian / Ubuntu and variants
- FreeBSD
- OSX
- SmartOS
- Solaris

### TL;DR - What should I do?

#### You're a user updating a system (like Riak) installed by node_package:

When upgrading from an older version of a system like Riak that uses
node_package for installation, you may need to verify the following (note, the
examples will be for a Centos 7-based Linux installation of Riak, but should
illustrate the required checks for most OSes and similar packages):

- Validate permissions on existing directories and make them owned by root:root
  (or the appropriate user/group for your operating system) and not writable by
  the package_install_user/group. For this example, we will list the specific
  directories for the Centos 7 install, and then their `node_package` template
  names in parenthesis afterward. Directories and files include:
	- /usr/lib64/riak (`platform_lib_dir`)
	- /etc/riak (`platform_etc_dir`)
	- /usr/bin (`platform_bin_dir`), specifically
		- riak
		- riak-admin
		- riak-debug
		- riak-repl
		- search-cmd
	- /etc/init.d/riak (`platform_etc_dir`/init.d/`package_install_name`)

- Validate the home directory of the `platform_install_user` user is set to the
  `platform_data_dir`, in the case of Riak on Centos 7 this should be the `riak`
  user and the `/var/lib/riak` directory, and not `/usr/lib64/riak`. If
  necessary, change the home directory of the `riak` (`package_install_user`)
  user to point to `/var/lib/riak` (`platform_data_dir`).

#### You're an application maintainer that uses node_package to produce packages for your application:

Please upgrade to version 3.0.0 of node_package and test your packaging/install
process carefully. If you were depending on the writability of directories
outside of the `platform_data_dir` you may need to adjust your application to
store writable files in `platform_data_dir` rather than some other directory,
like `package_root_dir`. 

Additionally, the home directory of the `package_install_user` has been
normalized across platforms to be the `platform_data_dir`. If you depended on
the home directory to be set to `platform_base_dir` make appropriate changes to
ensure your application can handle the change in home directory.

### Changes in version 3.0.0
#### File Ownership/Permissions
In all cases, the only files installed as owned by
`package_install_user:package_install_group` are now files to which the
packaged application needs to write. These files/directories include data
directories and log directories. All other files/directories installed by
`node_package`-packaged systems should now be owned by the appropriate `root`
account and group for the target operating system.

#### Home directory of `package_install_user`
In some cases, the home directory of the created `package_install_user` was set
to a directory that is now not writable by that user (often the
`package_base_dir`). In all cases, we have standardized on using the
`platform_data_dir` for the home directory of the `package_install_user`. This
may cause issues on upgrades, as the user in that case won't be updated (since
it already exists) but post-install scripts may now ensure that the directory
set as the `package_install_user`'s home directory is owned by the appropriate
root user/group. This will manifest itself as start/stop scripts, ping, etc.
failing to be able to write to a file called `.erlang.cookie` in that
directory. In order to resolve this issue, please use your operating system's
`usermod` or similar utility to change the home directory of the user to match
the `platform_data_dir` of the installed application.

### Details of the changes:
To view the individual changes to install package instructions, please see
[this PR](https://github.com/basho/node_package/pull/196). As always, if you
have seen or find any additional issues that may raise security concerns,
please email [security@basho.com](mailto:security@basho.com).
