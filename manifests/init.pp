# Class: vim
# ===========================
#
# Installs vim and customizes the .vimrc
# If not run as root, we ommit the parameters and only install
# the .vim stuf for the calling user.
#
# if run as root, the vimrc files are also installed in
# the user_list home directories.
#
# Users should excist
#
# Parameters
# ----------
#
# * `user_list`
# When run as root, we install the .vim files and dirs for those users, 
# otherwise, ignored. Default = ''
#
# Examples
# --------
#
# @example
#    class { 'vim':
#      user_list  => [ 'user1', 'user2' ],
#    }
#
# Authors
# -------
#
# Johan De Wit <johan@koewacht.net>
#
# Copyright
# ---------
#
# Copyright 2015 Johan De Wit, unless otherwise noted.
#
class vim (
  Array[String] $user_list = [],
) {

  if $facts['os']['name'] != "Fedora" {

    fail('Only Fedora runs on my laptops !')

  }

  if $facts['id'] == 'root' {

    package { 'vim-enhanced':
      ensure => present,
    }

    $vim_user_list = $user_list

  } else {

    $vim_user_list = [ $facts['id'] ]

  }

  $vim_user_list.each  |String $value| {

    if $value == 'root' {

      Notify { "WARNING: Skipping vimrc for the root user": }
    
    } else {
    
      vcsrepo { "/home/${value}/.vim":
        ensure   => present,
        user     => $value,
        source   => 'https://github.com/ricciocri/vimrc',
        provider => 'git',
      }

      exec { "init dot_vim_${value}":
        command     => "/usr/bin/git pull &&  /usr/bin/git submodule init &&  /usr/bin/git submodule update && /usr/bin/git submodule status",
        cwd         => "/home/${value}/.vim",
        refreshonly => true,
        subscribe   => Vcsrepo["/home/${value}/.vim"],
        user        => $value,
      }
  
      file { "/home/${value}/.vimrc":
        ensure => file,
        owner  => $value,
        group  => $value,
        mode   => '0640',
        source => 'puppet:///modules/vim/vimrc_basic',
      }

      vcsrepo { "/home/${value}/.vim/bundle/vim-colors-solarized":
        ensure   => present,
        user     => $value,
        source   => 'https://github.com/altercation/vim-colors-solarized.git',
        provider => 'git',
        require  => Vcsrepo["/home/${value}/.vim"],
      }

      ["candy.vim", "codeschool.vim", "vividchalk.vim"].each |String $file| {
        file { "/home/${value}/.vim/colors/${file}":
          ensure => file,
          owner  => $value,
          group  => $value,
          source => "puppet:///modules/vim/${file}",
        }
      }
    }
  }
}
