require_relative '../lib/docker_hub_client'

RSpec.describe DockerHubClient do
  let(:docker_hub_ruby_uri) {
    'https://hub.docker.com/v2/repositories/library/ruby'
  }

  it 'returns a digest for a tag' do
    client = DockerHubClient.new(docker_hub_ruby_uri)

    digest = client.get_digest('latest')

    expect(digest).not_to be_nil
    expect(digest).to match(/^sha256:[A-Za-z0-9]{64}$/)
  end

  it 'raises an exception when the tag does not exist' do
    client = DockerHubClient.new(docker_hub_ruby_uri)

    expect { client.get_digest('unknown') }.to raise_error(
      match('expected 200 but received 404')
    )
  end
end
