# cunnie/fedora-golang-bosh

FROM fedora:25

MAINTAINER Brian Cunnie <brian.cunnie@gmail.com>

# need ruby to run dns-check.rb & bind-utils for dig & nslookup
RUN dnf update -y; \
  dnf groupinstall -y "Development Tools"; \
  dnf install -y golang; \
  dnf install -y ruby rubygems ruby-devel redhat-rpm-config; \
  dnf install -y mysql-devel openssl-devel zlib-devel; \
  gem install yajl-ruby

RUN curl -L https://github.com/cloudfoundry/bosh-cli/releases/download/v5.5.1/bosh-cli-5.5.1-linux-amd64 -o /usr/local/bin/bosh; \
  chmod +x /usr/local/bin/bosh
