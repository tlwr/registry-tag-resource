require 'open3'
require 'json'

CURRENT_GO_VERSION = '1.21.3'
PREVIOUS_GO_VERSION = '1.21.2'

RSpec.describe 'check' do
  def raw_run_check(in_stream, env={})
    executable = File.join(__dir__, '..', 'bin', 'check')
    out, err, process = Open3.capture3(env, executable, stdin_data: in_stream)

    { out: out, err: err, status: process.exitstatus }
  end

  def run_check(in_config, env={})
    raw_run_check(in_config.to_json, env)
  end

  context 'when given invalid input json' do
    let(:invalid_json) { ';' }
    let(:run) { raw_run_check(invalid_json) }
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
          'source' => {}
        }
      end

      let(:run) { run_check(input) }
      let(:err) { run[:err] }
      let(:status) { run[:status] }

      it 'prints a helpful error message' do
        expect(err).to match('mandatory source.uri not found')
        expect(status).not_to be(0)
      end
    end
  end

  describe 'happy path' do
    let(:input) do
      {
        'source' => {
          'uri' => 'https://hub.docker.com/v2/repositories/library/ruby'
        }
      }
    end

    let(:run) { run_check(input) }
    let(:err) { run[:err] }
    let(:status) { run[:status] }
    let(:versions) { JSON.parse(run[:out]) }

    context 'when using default source params' do
      it 'generates 25 versions' do
        expect(err).to eq('')
        expect(status).to be(0)

        expect(versions.length).to eq(25)
        expect(versions).to all(satisfy { |v| v['tag'].is_a? String })
      end
    end

    context 'when getting multiple pages' do
      before do
        input['source']['pages'] = 3
        input['source']['tags_per_page'] = 10
      end

      it 'generates 30 versions' do
        expect(err).to eq('')
        expect(status).to be(0)

        expect(versions.length).to eq(30)
        expect(versions).to all(satisfy { |v| v['tag'].is_a? String })
      end
    end

    context 'when filtering by semantic versions' do
      before do
        input['source']['uri'] = 'https://hub.docker.com/v2/repositories/library/golang'
        input['source']['semver'] = {
          'matcher': '>= 1.19.1'
        }
        input['source']['regexp'] = '^[0-9]+[.][0-9]+[.][0-9]+$'
        input['source']['pages'] = 2
        input['source']['tags_per_page'] = 50
      end


      it 'generates at least one version' do
        expect(err).to eq('')
        expect(status).to be(0)

        expect(versions.length).to be >= 1
        expect(versions).to all(satisfy { |v| v['tag'].is_a? String })

        ordered = versions.sort_by { |v| Gem::Version.new(v['tag']) }
        expect(versions).to eq(ordered)
      end

      context 'when a current version exists' do
        before do
          input['version'] = { "tag": CURRENT_GO_VERSION }
        end

        it 'generates only versions equal or after the current version' do
          expect(err).to eq('')
          expect(status).to be(0)

          expect(versions.length).to be >= 1
          expect(versions).to all(satisfy { |v| v['tag'].is_a? String })

          ordered = versions.sort_by { |v| Gem::Version.new(v['tag']) }
          expect(versions).to eq(ordered)
        end
      end
    end

    context 'when filtering by regexp' do
      before do
        input['source']['uri'] = 'https://hub.docker.com/v2/repositories/library/golang'
        input['source']['regexp'] = '^1[.][0-9]+[.][0-9]+$'
        input['source']['pages'] = 2
        input['source']['tags_per_page'] = 50
      end

      it 'generates at least one version' do
        expect(err).to eq('')
        expect(status).to be(0)

        expect(versions.length).to be >= 1
        expect(versions).to all(satisfy { |v| v['tag'].is_a? String })
      end

      context 'when a current version exists' do
        before do
          input['version'] = { "tag": CURRENT_GO_VERSION }
        end

        it 'generates only versions equal or after the current version' do
          expect(err).to eq('')
          expect(status).to be(0)

          expect(versions.length).to be >= 1
          expect(versions).to all(satisfy { |v| v['tag'].is_a? String })

          expect(versions).to include({ 'tag' => CURRENT_GO_VERSION })
          expect(versions).not_to include({ 'tag' => PREVIOUS_GO_VERSION })

          ordered = versions.sort_by { |v| Gem::Version.new(v['tag']) }
          expect(versions).to eq(ordered)
        end
      end
    end

    context 'when using quay.io' do
      before do
        input['source']['uri'] = 'https://quay.io/v2/coreos/etcd'
        input['source']['tags_per_page'] = 10
        input['source']['pages'] = 3
      end

      it 'generates 30 versions' do
        expect(err).to eq('')
        expect(status).to be(0)

        expect(versions.length).to eq(30)
        expect(versions).to all(satisfy { |v| v['tag'].is_a? String })
      end
    end

    context 'when using regexp and semver with prefices and pre-releases' do
      before do
        input['source']['uri'] = 'https://hub.docker.com/v2/repositories/minio/console'
        input['source']['regexp'] = '^v\d+\.\d+\.\d+$'
        input['source']['tags_per_page'] = 25
        input['source']['pages'] = 1
        input['source']['semver'] = {}
        input['source']['semver']['prefix'] = 'v'
        input['source']['semver']['matcher'] = '>= 0.8.0'
      end

      it 'generates a version' do
        expect(err).to eq('')
        expect(status).to be(0)

        expect(versions.length).to be >= 1
        expect(versions).to all(satisfy { |v| v['tag'].is_a? String })
      end
    end
  end
end
