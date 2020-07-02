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
end
