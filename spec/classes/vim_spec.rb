require 'spec_helper'
require 'shared_contexts'

describe 'vim' do
  context 'unsupported platform' do
    let(:facts) do 
      { :os => { :family => 'Debian' } } 
    end
    it do
      is_expected.to compile.and_raise_error(/Only RedHat family/)
    end
  end

  context 'supported platform' do
    let(:facts) do
      { :os => { :family => 'RedHat' } } 
    end
    context 'running as root' do
      let(:facts) do
        { :os => { :family => 'RedHat' },
          :id => 'root',
        } 
      end
      context 'with default params' do
        it do
          is_expected.to contain_package('vim-enhanced').with(
            'ensure' => 'present',
          )
        end
      end
      context 'with custom parameters' do
        let(:params) do
          { :user_list => ['user1', 'user2'] } 
        end
        ['user1', 'user2'].each do |user|
          it do
            is_expected.to contain_vcsrepo("/home/#{user}/.vim").with(
              'ensure'   => 'present',
              'user'     => "#{user}",
              'source'   => 'https://github.com/ricciocri/vimrc',
              'provider' => 'git',
            )
            is_expected.to contain_exec("init dot_vim_#{user}").with(
              'command'     => '/usr/bin/git pull &&  /usr/bin/git submodule init &&  /usr/bin/git submodule update && /usr/bin/git submodule status',
              'cwd'         => "/home/#{user}/.vim",
              'refreshonly' => 'true',
              'subscribe'   => "Vcsrepo[/home/#{user}/.vim]",
              'user'        => "#{user}",
            )
            is_expected.to contain_file("/home/#{user}/.vimrc").with(
              'ensure' => 'file',
              'owner'  => "#{user}",
              'group'  => "#{user}",
              'mode'   => '0640',
              'source' => 'puppet:///modules/vim/vimrc_basic',
            )
            is_expected.to contain_vcsrepo("/home/#{user}/.vim/bundle/vim-colors-solarized").with(
              'ensure'   => 'present',
              'user'     => "#{user}",
              'source'   => 'https://github.com/altercation/vim-colors-solarized.git',
              'provider' => 'git',
              'require'  => "Vcsrepo[/home/#{user}/.vim]",
            )
            ['candy.vim', 'codeschool.vim', 'vividchalk.vim', 'antares.vim', 'gryffin.vim',
             'ingruti.vim', 'molokai_dark.vim', 'radicalgoodspeed.vim',].each do |file|
              is_expected.to contain_file("/home/#{user}/.vim/colors/#{file}").with(
                'ensure' => 'file',
                'owner'  => "#{user}",
                'group'  => "#{user}",
                'source' => "puppet:///modules/vim/#{file}",
              )
            end
          end
        end
        context 'containing user root' do
          let(:params) do 
            { :user_list => ['root'] } 
          end
          it do
            is_expected.to contain_notify('WARNING: Skipping vimrc for the root user')
          end
        end
      end
    end
    context 'running as non-root' do
      let(:facts) do
        { :os => { :family => 'RedHat' } ,
          :id => 'user' }
      end
      it do
        is_expected.not_to contain_package('vim-enhanced')
      end
      context 'with default parameters' do
      end
      context 'with custom parameters' do
        let(:params) do 
          { :user_list => ['user1', 'user2'] } 
        end
      end
    end
  end
end
