require 'open3'
require 'json'

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
      it 'generates 10 versions' do
        expect(err).to eq('')
        expect(status).to be(0)

        expect(versions.length).to be(10)
        expect(versions).to all(satisfy { |v| v['tag'].is_a? String })
        expect(versions).to all(satisfy { |v| v['digest'].is_a? String })
      end
    end

    context 'when ignoring digests' do
      before do
        input['source']['version_includes_digest'] = false
      end

      it 'generates 10 versions without digests' do
        expect(err).to eq('')
        expect(status).to be(0)

        expect(versions.length).to be(10)
        expect(versions).to all(satisfy { |v| v['tag'].is_a? String })
        expect(versions).to all(satisfy { |v| v['digest'].nil? })

        ordered = versions.sort_by { |v| v['last_updated'] }
        expect(versions).to eq(ordered)
      end
    end

    context 'when getting multiple pages' do
      before do
        input['source']['pages'] = 2
      end

      it 'generates 20 versions' do
        expect(err).to eq('')
        expect(status).to be(0)

        expect(versions.length).to be(20)
        expect(versions).to all(satisfy { |v| v['tag'].is_a? String })
        expect(versions).to all(satisfy { |v| v['digest'].is_a? String })

        ordered = versions.sort_by { |v| v['last_updated'] }
        expect(versions).to eq(ordered)
      end
    end

    context 'when filtering by semantic versions' do
      before do
        input['source']['semver'] = {
          'matcher': '>= 2.6.0'
        }
        input['source']['regexp'] = '^[0-9]+[.][0-9]+[.][0-9]+$'
        input['source']['pages'] = 10
      end


      it 'generates at least one version' do
        expect(err).to eq('')
        expect(status).to be(0)

        expect(versions.length).to be >= 1
        expect(versions).to all(satisfy { |v| v['tag'].is_a? String })
        expect(versions).to all(satisfy { |v| v['digest'].is_a? String })

        ordered = versions.sort_by { |v| Gem::Version.new(v['tag']) }
        expect(versions).to eq(ordered)
      end

      context 'when a current version exists' do
        before do
          # ignore digests to simplify test
          input['source']['version_includes_digest'] = false
          input['version'] = { "tag": "2.6.6" }
        end

        it 'generates only versions equal or after the current version' do
          expect(err).to eq('')
          expect(status).to be(0)

          expect(versions.length).to be >= 1
          expect(versions).to all(satisfy { |v| v['tag'].is_a? String })
          expect(versions).to all(satisfy { |v| v['digest'].nil? })

          ordered = versions.sort_by { |v| Gem::Version.new(v['tag']) }
          expect(versions).to eq(ordered)
        end
      end
    end
  end
end
