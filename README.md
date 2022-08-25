# deployments

BOSH Deployment Manifests, Cloud Config, -state.json files

### Cloud Foundry

To deploy cf:

```zsh
bin/cf.sh
cf api api.cf.nono.io
cf login -u admmin
cf create-space -o system system # don't worry if it's already created
cf t -o system -s system
 # CF Acceptance Tests req'ts
cf enable-feature-flag diego_docker # necessary if you're running the Docker tests (`"include_docker": true`)
cf create-security-group credhub <(echo '[{"protocol":"tcp","destination":"10.0.0.0/8","ports":"8443,8844","description":"credhub"}]')
cf bind-running-security-group credhub
cf bind-staging-security-group credhub
```

## Credentials

We publish our auto-generated keys and certificates.

This includes auto-generated keys, certificates, and passwords; however, we
have redacted the passwords from this file in order to make sure we use our
own, custom passwords, which we set via the command line, e.g.

  `bosh create-env -v admin_password=IReturnedAndSawUnderTheSun ...`

(That's not quite true -- we use an environment variable whose contents are
YAML-formatted passwords, and pass that in to bosh) (we use `-l` not `-v`):

  `bosh create-env -l <(echo "$DEPLOYMENTS_YML")`

We also override the `/director_ssl/key` and `/director_ssl/cert` to use our
CA-issued certificate, but we didn't bother redacting those fields from this
file because we weren't as worried about not getting them right (if we
interpolate our passwords incorrectly, someone can either compromise our
machine or we can be locked-out; if we use the wrong certificate & key we
merely get an SSL error).

We run a second check to make sure we interpolate the passwords correctly
and didn't miss one (we use the `--var-errs` flag):

  `bosh int --var-errs ...`

One may ask, "Is it wise to publish your CA certificates, certificates and
keys used in active and publicly-accessible BOSH directors?" The answer is,
"No." We recommend you don't do it. We publish ours primarily for instructive
purposes.

But we're not terribly worried, either. Our understanding is that the keys &
certs aren't used for authentication, merely for encryption (the passwords
are used for authentication, and we don't publish those). "Aha! But what if a
hacker were able to use they keys to unencrypt the traffic between the BOSH
director and one of its deployed VMs and reveal a password in plaintext?" To
which we answer, "If she's able to sniff (`tcpdump`) the traffic, then she's
already root on either the director or the VM, and we've already lost the
battle."
