require 'open3'
require 'json'
require 'tmpdir'

RSpec.describe 'in' do
  let(:fs) { Hash.new }

  before do
    fs['chdir'] = Dir.mktmpdir
  end

  after do
    FileUtils.remove_entry fs['chdir']
  end

  def raw_run_in(in_stream, env={})
    executable = File.join(__dir__, '..', 'bin', 'in')
    cmd = "#{executable} #{fs['chdir']}"

    out, err, process = Open3.capture3(env, cmd, stdin_data: in_stream)

    { out: out, err: err, status: process.exitstatus }
  end

  def run_in(in_config, env={})
    raw_run_in(in_config.to_json, env)
  end

  context 'when given invalid input json' do
    let(:invalid_json) { ';' }
    let(:run) { raw_run_in(invalid_json) }
    let(:err) { run[:err] }
    let(:status) { run[:status] }

    it 'prints a helpful error message' do
      expect(err).to match('JSON::ParserError')
      expect(status).not_to be(0)
    end
  end

  describe 'source validation' do
    context 'when uri is missing' do
      let(:input) do
        {
          'source' => {},
        }
      end

      let(:run) { run_in(input) }
      let(:err) { run[:err] }
      let(:status) { run[:status] }

      it 'prints a helpful error message' do
        expect(err).to match('mandatory source.uri not found')
        expect(status).not_to be(0)
      end
    end
  end

  context 'when running in' do
    let(:run) { run_in(input) }
    let(:err) { run[:err] }
    let(:status) { run[:status] }
    let(:output) { JSON.parse(run[:out]) }

    let(:tag_contents) { File.read(File.join(fs['chdir'], 'tag')) }
    let(:digest_contents) { File.read(File.join(fs['chdir'], 'digest')) }

    context 'when using docker hub' do
      let(:input) do
        {
          'source' => {
            'uri' => 'https://hub.docker.com/v2/repositories/library/ruby'
          },
          'version' => {
            'tag' => 'latest'
          },
        }
      end

      context 'when getting ruby latest' do
        it 'generates a resource' do
          expect(err).to eq('')
          expect(status).to be(0)

          expect(output.dig('version', 'tag')).to eq('latest')

          expect(output['metadata'].length).to eq(2)

          expect(output['metadata']).to include({
            'name' => 'tag',
            'value' => 'latest',
          })

          expect(output['metadata']).to include({
            'name' => 'digest',
            'value' => be_a(String),
          })

          expect(tag_contents).to eq('latest')
          expect(digest_contents).to match(/^sha256:[A-Za-z0-9]{64}$/)
        end
      end
    end

    context 'when using quay.io' do
      let(:input) do
        {
          'source' => {
            'uri' => 'https://quay.io/v2/coreos/etcd'
          },
          'version' => {
            'tag' => 'latest'
          },
        }
      end

      context 'when getting ruby latest' do
        it 'generates a resource' do
          expect(err).to eq('')
          expect(status).to be(0)

          expect(output.dig('version', 'tag')).to eq('latest')

          expect(output['metadata'].length).to eq(2)

          expect(output['metadata']).to include({
            'name' => 'tag',
            'value' => 'latest',
          })

          expect(output['metadata']).to include({
            'name' => 'digest',
            'value' => be_a(String),
          })

          expect(tag_contents).to eq('latest')
          expect(digest_contents).to match(/^sha256:[A-Za-z0-9]{64}$/)
        end
      end
    end
  end
end
