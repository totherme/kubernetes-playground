# A kubernetes playground

(forked from the [runc one](https://github.com/totherme/runc-playground))

## Want to play with k8s?

### Initial setup:

```sh
brew install rsync lsyncd vagrant
vagrant plugin install vagrant-disksize
```

### Daily forkflow

```sh
vagrant up
./watch.sh start
vagrant ssh
# do your work
./watch.sh stop
vagrant halt
```

This setup makes sure that changes done on the host will be synced into the
linux guest. So you could have your IDE set up on your mac and still be able to
compile inside your linux guest with your newest changes -- without the need to
manually copying / syncing.

Then follow instructions from the [dev guide](https://github.com/kubernetes/community/blob/master/contributors/devel/development.md)


## File synchronization

Initially we had the sourcecode inside the shared mount (vboxsf) and also built
it in there. We noticed a huge performance problem with that. So we decided to
move the source code away from that share. However, we still wanted to be able
to use tools on the host (e.g. GogLand, ...) but still build inside the VM.

So we use [lsyncd](https://axkibe.github.io/lsyncd/) to synchronize the host's
directory `./vagrant/go` to the guest's directory `~ubuntu:workspace/go`. Keep
in mind that this is a one-way sync, only from the host to the guest.

To ease the usage, there is a script `./watch.sh` which you can use to
configure `lsyncd`, start and stop it.

## `vagrant-disksize` vagrant plugin

As some of the tools in [`k/k`](k8s.io/kubernetes/kubernetes) require a lot of
temporary disk space we need this plugin to resize the root disk and therefore
add more space in `/tmp`.
