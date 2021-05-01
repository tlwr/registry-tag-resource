# registry-tag-resource

a [concourse](https://concourse-ci.org) resource for tags in a oci registry

a
[blog post on www.toby.codes](https://www.toby.codes/posts/2021-05-Automatic-updates-of-Docker-images-with-Concourse)
describes how this resource type can be used

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

## examples

### dynamically generate docker image using build args

using a [Dockerfile](Dockerfile) with a build arg:

```Dockerfile
BUILD_ARG ruby_version
FROM ruby:$ruby_version

...
```

a pipeline that uses the
[oci-build-task](https://github.com/vito/oci-build-task) can dynamically
build docker images using `BUILD-ARG_` params:

```yaml
name: dynamically-build-image
plan:

  # source code
  - get: my-src 

  # registry-tag
  - get: ruby-img-tag
  
  # make tag file from resource available as a variable
  - load_var: ruby-version
    file: ruby-img-tag/tag

  - task: build-img
    privileged: true
    config:
      platform: linux

      image_resource:
        type: registry-image
        source:
          repository: vito/oci-build-task

      inputs:
        - name: my-src
          path: .

      outputs:
        - name: image

      params:
        # load ruby version for build task
        BUILD_ARG_ruby_version: ((.:ruby-version))

      run:
        path: build
```
