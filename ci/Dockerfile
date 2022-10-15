# cunnie/fedora-golang-bosh

# To build

# docker buildx build --platform=linux/amd64 -t cunnie/fedora-golang-bosh . # OR
# docker build -t cunnie/fedora-golang-bosh .
# docker push cunnie/fedora-golang-bosh

FROM fedora

LABEL org.opencontainers.image.authors="Brian Cunnie <brian.cunnie@gmail.com>"

# need ruby to run dns-check.rb & bind-utils for dig & nslookup
RUN dnf update -y; \
  dnf groupinstall -y "Development Tools"; \
  dnf install -y \
    bind-utils \
    binutils \
    btrfs-progs \
    direnv \
    etcd \
    fd-find \
    git \
    golang \
    htop \
    iproute \
    iputils \
    jq \
    mysql-devel \
    neovim \
    net-tools \
    nmap-ncat \
    npm \
    openssl-devel \
    python \
    redhat-rpm-config \
    ripgrep \
    ruby \
    ruby-devel \
    rubygems \
    socat \
    strace \
    tcpdump \
    tmux \
    wget \
    zlib-devel \
    zsh \
    zsh-lovers \
    zsh-syntax-highlighting \
  ; \
  /usr/bin/gem install yajl-ruby

RUN mkdir ~/workspace; \
  cd ~/workspace; \
  git clone https://github.com/clvv/fasd.git; \
  cd fasd; \
  sudo make install; \
  echo 'eval "\$(fasd --init posix-alias zsh-hook)"' >> ~/.zshrc; \
  echo 'alias z='fasd_cd -d'     # cd, same functionality as j in autojump' >> ~/.zshrc \
EOF

RUN  echo "" | SHELL=/usr/bin/zsh /usr/bin/zsh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; \
    sed -i 's/robbyrussell/agnoster/' ~/.zshrc; \
    echo 'export EDITOR=nvim' >> ~/.zshrc; \
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc

# amd64, arm64 (so I can run on AWS graviton2, natively on M1, M2 macs)
ARG TARGETARCH

RUN curl -L https://github.com/cloudfoundry/bosh-cli/releases/download/v7.0.1/bosh-cli-7.0.1-linux-${TARGETARCH} -o /usr/local/bin/bosh; \
  chmod +x /usr/local/bin/bosh

RUN dnf install -y dnf-plugins-core; \
  dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo; \
  dnf -y install vault; \
  setcap -r /usr/bin/vault

RUN curl -o /etc/yum.repos.d/cloudfoundry-cli.repo -L https://packages.cloudfoundry.org/fedora/cloudfoundry-cli.repo; \
  dnf install -y cf8-cli

RUN GOBIN=/usr/local/bin go install github.com/onsi/ginkgo/v2/ginkgo@latest

CMD [ "/usr/bin/zsh" ]
