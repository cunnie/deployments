# cunnie/fedora-golang-bosh

FROM fedora:34

MAINTAINER Brian Cunnie <brian.cunnie@gmail.com>

# need ruby to run dns-check.rb & bind-utils for dig & nslookup
RUN dnf update -y; \
  dnf groupinstall -y "Development Tools"; \
  dnf install -y bind-utils iputils iproute net-tools ; \
  dnf install -y golang; \
  dnf install -y strace btrfs-progs zsh; \
  dnf install -y neovim python python3-neovim fd-find npm ripgrep; \
  dnf install -y ruby rubygems ruby-devel redhat-rpm-config; \
  dnf install -y mysql-devel openssl-devel zlib-devel; \
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

RUN curl -L https://github.com/cloudfoundry/bosh-cli/releases/download/v6.4.4/bosh-cli-6.4.4-linux-amd64 -o /usr/local/bin/bosh; \
  chmod +x /usr/local/bin/bosh

RUN curl -o /etc/yum.repos.d/cloudfoundry-cli.repo -L https://packages.cloudfoundry.org/fedora/cloudfoundry-cli.repo; \
  dnf install -y cf7-cli

RUN GOBIN=/usr/local/bin go get github.com/onsi/ginkgo/ginkgo; \
  go get github.com/onsi/gomega/...

CMD [ "/usr/bin/zsh" ]
