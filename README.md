# registry-tag-resource

a [concourse](https://concourse-ci.org) resource for tags in a oci registry

## operations

* `check` - looks for tags
* `in` - downloads metadata about the tag

## configuration

```yaml
source:
  # where the image lives
  #
  # for docker hub https://hub.docker.com/v2/user_or_org/image_name
  #
  # for example https://hub.docker.com/v2/library/ruby for _/ruby
  # for example https://quay.io/v2/coreos/etcd'
  #
  # mandatory
  uri: https://hub.docker.com/v2/repositories/governmentpaas/cf-cli

  # how many pages to check in the registry
  #
  # optional ; default 1
  pages: 1

  # how many tags to fetch per page
  #
  # optional ; default 25
  tags_per_page: 50

  # ruby regular expression for filtering tags
  #
  # optional
  regexp: 'v[0-9]+'

  # to specify semantic versions
  # see github.com/jlindsey/semantic
  #
  # optional
  semver:
    # mandatory
    matcher: '~1.5'

    # optional
    prefix: 'v'
    
```

## `check` - check for new tags

the `check` step looks at the configured registry for new tags for the image

an example version:

```json
{
  "tag": "2.7.1"
}
```

## `in` - fetch registry image metadata

produces the following files:

* `tag`
* `digest`
