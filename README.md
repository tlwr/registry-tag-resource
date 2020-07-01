# registry-tag-resource

a [concourse](https://concourse-ci.org) resource for tags in a oci registry

## operations

* `check` - looks for tags
* `in` - downloads metadata about the tag (todo)

## configuration

```yaml
source:
  # where the image lives
  #
  # for docker hub https://hub.docker.com/v2/user_or_org/image_name
  #
  # mandatory
  uri: https://hub.docker.com/v2/repositories/governmentpaas/cf-cli

  # architecture
  #
  # optional ; default amd64 ; eg amd arm arm64 386
  arch: amd64

  # how many pages to check in the registry
  #
  # for hub.docker.com 1 page corresponds to the 10 most recent tags
  #
  # optional ; default 1
  pages: 1

  # if the digest should be included in the version
  # this is useful for generating new versions if the digest changes
  #
  # optional ; default true
  version_includes_digest: true

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
