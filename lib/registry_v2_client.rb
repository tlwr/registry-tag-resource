require 'json'

require 'http'

class RegistryV2Client
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def list_tags(pages, tags_per_page)
    tags_url = "#{url}/tags/list?n=#{tags_per_page}"

    tags = []

    pages.times do
      break if tags_url.nil?

      resp = HTTP.get(tags_url)
      unless resp.code == 200
        abort "expected 200 but received #{resp.code} from #{tags_url}"
      end

      tags_resp = JSON.parse(resp.body)

      tags += tags_resp.fetch('tags', [])

      link = resp['link']
      if link.nil?
        tags_url = nil
      else
        next_href = LinkHeader.parse(link)&.find_link(['rel', 'next'])&.href
        if next_href.nil?
          tags_url = nil
        else
          tags_url = tags_url.sub(%r{/v2/.*$}, next_href) unless next_href.nil?
        end
      end
    end

    tags
  end
end