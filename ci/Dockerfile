# cunnie/fedora-golang-bosh

# To build

# docker build -t cunnie/fedora-golang-bosh .
# docker push cunnie/fedora-golang-bosh

FROM fedora

MAINTAINER Brian Cunnie <brian.cunnie@gmail.com>

# need ruby to run dns-check.rb & bind-utils for dig & nslookup
RUN dnf update -y; \
  dnf groupinstall -y "Development Tools"; \
  dnf install -y bind-utils iputils iproute net-tools wget; \
  dnf install -y strace btrfs-progs zsh; \
  dnf install -y neovim python python3-neovim fd-find npm ripgrep; \
  dnf install -y ruby rubygems ruby-devel redhat-rpm-config; \
  dnf install -y mysql-devel openssl-devel zlib-devel; \
  dnf install -y etcd; \
  gem install yajl-ruby

RUN mkdir ~/workspace; \
  cd ~/workspace; \
  git clone https://github.com/clvv/fasd.git; \
  cd fasd; \
  sudo make install; \
  echo 'eval "\$(fasd --init posix-alias zsh-hook)"' >> ~/.zshrc; \
  echo 'alias z='fasd_cd -d'     # cd, same functionality as j in autojump' >> ~/.zshrc \
EOF

RUN  echo "" | SHELL=/usr/bin/zsh zsh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; \
    sed -i 's/robbyrussell/agnoster/' ~/.zshrc; \
    echo 'export EDITOR=nvim' >> ~/.zshrc

RUN mkdir ~/.config; \
  git clone https://github.com/luan/nvim ~/.config/nvim

RUN curl -L https://github.com/cloudfoundry/bosh-cli/releases/download/v6.4.10/bosh-cli-6.4.10-linux-amd64 -o /usr/local/bin/bosh; \
  chmod +x /usr/local/bin/bosh

RUN curl -o /etc/yum.repos.d/cloudfoundry-cli.repo -L https://packages.cloudfoundry.org/fedora/cloudfoundry-cli.repo; \
  dnf install -y cf7-cli


RUN dnf install -y dnf-plugins-core; \
  dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo; \
  dnf -y install vault; \
  setcap -r /usr/bin/vault

# amd64, arm64 (so I can run on AWS graviton2); future-proofing that I'll never need
ARG TARGETARCH
# I need the latest go (1.17), and Fedora 35 is pinned to 1.16
# I'll need to manually update this, which is a pain
RUN curl -L https://go.dev/dl/go1.17.6.linux-$TARGETARCH.tar.gz | tar xzf - -C /usr/local

ENV PATH="$PATH:/usr/local/go/bin"

RUN GOBIN=/usr/local/go/bin /usr/local/go/bin/go install github.com/onsi/ginkgo/v2/ginkgo@latest; \
  /usr/local/go/bin/go get github.com/onsi/ginkgo/v2; \
  /usr/local/go/bin/go get github.com/onsi/gomega/...

CMD [ "/usr/bin/zsh" ]
