require_relative '../lib/registry_v2_client'

RSpec.describe RegistryV2Client do
  let(:quay_io_etcd_uri) { 'https://quay.io/v2/coreos/etcd' }

  it 'returns a digest for a tag' do
    client = RegistryV2Client.new(quay_io_etcd_uri)

    digest = client.get_digest('latest')

    expect(digest).not_to be_nil
    expect(digest).to match(/^sha256:[A-Za-z0-9]{64}$/)
  end

  it 'raises an exception when the tag does not exist' do
    client = RegistryV2Client.new(quay_io_etcd_uri)

    expect { client.get_digest('unknown') }.to raise_error(
      match('expected 200 but received 404')
    )
  end

  describe 'basic auth' do
    context 'when there is no username or password' do
      let(:client) { RegistryV2Client.new(quay_io_etcd_uri) }

      it 'does not apply basic auth' do
        expect(client.http.default_options.headers.get('Authorization')).to be_empty
      end
    end

    context 'when there is a username and password' do
      let(:client) { RegistryV2Client.new(quay_io_etcd_uri, username='un', password='pw') }

      it 'applies' do
        expect(client.http.default_options.headers.get('Authorization')).to eq(['Basic dW46cHc='])
      end
    end
  end
end
