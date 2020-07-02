require 'json'

require 'http'

class DockerHubClient
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def list_tags(pages, tags_per_page)
    tags_url = "#{url}/tags?page_size=#{tags_per_page}"

    tags = []

    pages.times do
      break if tags_url.nil?

      resp = HTTP.get(tags_url)
      unless resp.code == 200
        raise "expected 200 but received #{resp.code} from #{tags_url}"
      end

      tags_resp = JSON.parse(resp.body)

      tags += tags_resp.fetch('results', []).map { |ft| ft['name'] }

      tags_url = tags_resp['next']
    end

    tags
  end

  def get_digest(tag)
    tag_url = "#{url}/tags/#{tag}"

    resp = HTTP.get(tag_url)
    unless resp.code == 200
      raise "expected 200 but received #{resp.code} from #{tag_url}"
    end

    tag_resp = JSON.parse(resp.body)

    image = tag_resp['images'].find do |i|
      i['os'] == 'linux' && i['architecture'] == 'amd64'
    end

    image&.fetch('digest')
  end
end
