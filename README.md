# A kubernetes playground

(forked from the [runc one](https://github.com/totherme/runc-playground))

Want to play with k8s?

```
vagrant plugin install vagrant-notify-forwarder
vagrant up
vagrant ssh
```

Then follow instructions from the [dev guide](https://github.com/kubernetes/community/blob/master/contributors/devel/development.md)


## File synchronization

Initially we had the sourcecode inside the shared mount (vboxsf) and also built
it in there. We noticed a huge performance problem with that. So we decided to
move the source code away from that share. However, we still wanted to be able
to use tools on the host (e.g. GogLand, ...) but still build inside the VM.

So we try to synchronize the changes made in the host's `vagrant/go/k8s.io/kubernetes`
to the guest's `~ubuntu/workspace/go/k8s.io/kubernetes` (one way sync).
For this to work there are two important things in place:

- `vagrant-notify-forwarder`: This vagrant plugin makes sure that we can use
  inotify to listen on changes to the filesystem of the shared mount inside the
  guest. It captures all events on the host and forwards them via network to the
  guest and replays them there.
  Note: While provisioning the plugin makes sure the guest runs and listens
  for those events forwarded via the network, you should see a process in the
  guest running something like `sudo nohup /tmp/notify-forwarder receive -p 22020`.
- `lsyncd`: Now, that we can listen on changes to the shared mount inside the
  guest, we can use [lsyncd](http://axkibe.github.io/lsyncd/) to replicate the
  changes from the shared mount to our working/build directory.
