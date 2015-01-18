#
# Copyright (C) 2014 Catalyst IT Limited.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# Author: Ricardo Rocha <ricardo@catalyst.net.nz>
#

require 'spec_helper'

describe 'ceph::rgw::keystone' do

  shared_examples_for 'ceph rgw keystone' do

    describe "create with default params" do

      let :pre_condition do
        "
          include ceph::params
          class { 'ceph': fsid => 'd5252e7d-75bc-4083-85ed-fe51fa83f62b' }
          class { 'ceph::repo': extras => true, fastcgi => true, }
          include ceph
          ceph::rgw { 'radosgw.gateway': }
          ceph::rgw::apache { 'radosgw.gateway': }
        "
      end

      let :title do
        'radosgw.gateway'
      end

      let :params do
        {
          :rgw_keystone_url         => 'http://keystone.default:5000/v2.0',
          :rgw_keystone_admin_token => 'defaulttoken',
        }
      end

      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_url').with_value('http://keystone.default:5000/v2.0') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_token').with_value('defaulttoken') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_accepted_roles').with_value('_member_, Member') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_token_cache_size').with_value(500) }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_revocation_interval').with_value(600) }
      it { should contain_ceph_config('client.radosgw.gateway/use_pki').with_value('') }
      it { should contain_ceph_config('client.radosgw.gateway/nss_db_path').with_value('/var/lib/ceph/nss') }

      it { should contain_exec('radosgw.gateway-nssdb-ca').with(
         'command' => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate http://keystone.default:5000/v2.0/certificates/ca -O /tmp/ca
openssl x509 -in /tmp/ca -pubkey | certutil -A -d /var/lib/ceph/nss -n ca -t \"TCu,Cu,Tuw\"
"
      ) }
      it { should contain_exec('radosgw.gateway-nssdb-signing').with(
         'command' => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate http://keystone.default:5000/v2.0/certificates/signing -O /tmp/signing
openssl x509 -in /tmp/signing -pubkey | certutil -A -d /var/lib/ceph/nss -n signing_cert -t \"P,P,P\"
"
      ) }

    end

    describe "create with custom params" do

      let :pre_condition do
        "
          include ceph::params
          class { 'ceph': fsid => 'd5252e7d-75bc-4083-85ed-fe51fa83f62b' }
          class { 'ceph::repo': extras => true, fastcgi => true, }
          ceph::rgw { 'radosgw.custom': }
          ceph::rgw::apache { 'radosgw.custom': }
        "
      end

      let :title do
        'radosgw.custom'
      end

      let :params do
        {
          :rgw_keystone_url                 => 'http://keystone.custom:5000/v2.0',
          :rgw_keystone_admin_token         => 'mytoken',
          :rgw_keystone_accepted_roles      => '_role1_,role2',
          :rgw_keystone_token_cache_size    => 100,
          :rgw_keystone_revocation_interval => 200,
          :use_pki                          => false,
          :nss_db_path                      => '/some/path/to/nss',
        }
      end

      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_url').with_value('http://keystone.custom:5000/v2.0') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_admin_token').with_value('mytoken') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_accepted_roles').with_value('_role1_,role2') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_token_cache_size').with_value(100) }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_revocation_interval').with_value(200) }
      it { should contain_ceph_config('client.radosgw.custom/use_pki').with_value(false) }
      it { should contain_ceph_config('client.radosgw.custom/nss_db_path').with_value('/some/path/to/nss') }

      it { should contain_exec('radosgw.custom-nssdb-ca').with(
         'command' => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate http://keystone.custom:5000/v2.0/certificates/ca -O /tmp/ca
openssl x509 -in /tmp/ca -pubkey | certutil -A -d /some/path/to/nss -n ca -t \"TCu,Cu,Tuw\"
"
      ) }
      it { should contain_exec('radosgw.custom-nssdb-signing').with(
         'command' => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate http://keystone.custom:5000/v2.0/certificates/signing -O /tmp/signing
openssl x509 -in /tmp/signing -pubkey | certutil -A -d /some/path/to/nss -n signing_cert -t \"P,P,P\"
"
      ) }

    end

  end

  describe 'Debian Family' do

    let :facts do
      {
        :concat_basedir         => '/var/lib/puppet/concat',
        :fqdn                   => 'myhost.domain',
        :hostname               => 'myhost',
        :lsbdistcodename        => 'precise',
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '12.04',
      }
    end

    it_configures 'ceph rgw keystone'
  end

  describe 'RedHat Family' do

    let :facts do
      {
        :concat_basedir         => '/var/lib/puppet/concat',
        :fqdn                   => 'myhost.domain',
        :hostname               => 'myhost',
        :lsbdistcodename        => 'Final',
        :osfamily               => 'RedHat',
        :operatingsystem        => 'RedHat',
        :operatingsystemrelease => '6',
      }
    end

    it_configures 'ceph rgw keystone'
  end
end

# Local Variables:
# compile-command: "cd ../.. ;
#    bundle install ;
#    bundle exec rake spec
# "
# End:
