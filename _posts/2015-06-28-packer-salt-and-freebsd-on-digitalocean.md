---
title: Packer, Salt, and FreeBSD on DigitalOcean
description: >
    Getting Packer and Salt to successfully provision a FreeBSD machine was
    a pain in the butt. Here's how I did it.
layout: post
---

{% raw %}

I spent a large part of my weekend setting up a FreeBSD server on
[DigitalOcean][] (referral link). I've been meaning to try their FreeBSD
offering ever since it was announced, and I finally found a good excuse to
experiment. While I was experimenting, I figured I'd try out some of the tools
I've been meaning to get some experience with. In this case, I settled on
a combination of [Packer][] and [Salt][].

[Packer][] is a tool for building machine images. It can build a bunch of
different types of machine images, including VMware boxes, AMIs, Docker images,
and - most important for this post - DigitalOcean snapshots. Packer delegates
most of the actual provisioning (installing packages, changing configuration
files, managing users, etc.) to external tools. These can be as simple as
inline shell scripts, or as complex as entire Ansible playbooks. You can see
a full list of the provisioners that Packer supports on [the documentation
site][provisioners].

I was lucky enough to attend a [SaltStack][Salt] session at the SCALE
conference in February, and I've been meaning to take a deeper look at the tool
ever since. Usually Salt is run with a `master` and a set of `minion` nodes,
but since Packer only deals with creating machine images (and not managing the
actual nodes at runtime), it only supports running Salt in a "masterless" (i.e.
single-node) state. That's perfect for our needs.

The goal of this post is to setup a FreeBSD server running Nginx. Additionally,
some extra general system configuration tasks need to be performed:

- Setup a non-root user for remote administration
- Make sure our user is in the `wheel` group
- Restrict SSH access to public key authentication (no passwords)

This is totally not a complete guide on how to setup a public-facing server.
There's a lot of things this is missing - log rotation, health monitoring,
regular security updates, tuning kernel parameters, etc. - but this is a good
start for those new to these tools. I also ran into enough problems when trying
to set this up that I thought it would be worth writing about them.

## Prerequisites

You'll need [Packer][]. You can grab it from the website, a binary release
should be fine. This was tested on `v0.8.0`.

You'll also need a DigitalOcean Personal Access Token (PAT). You can generate
one from the [applications panel in your account][pat].

Finally, you may need some patience and a willingness to debug problems as they
occur. There's a fair amount of moving parts here, and it's easy to make
mistakes or run into issues caused by hidden assumptions made by those same
parts.

## Getting started with Packer

Let's create a new directory for our work.

```bash
mkdir packed-salt && cd packed-salt
```

The first thing we need is a build file for Packer. You can read more about the
format in the [docs][packer-tutorial], but the short version is that it's
a simple JSON file. For the impatient, paste this into `build.json`:

```json
{
  "variables": {
    "digitalocean_pat": "{{env `DIGITALOCEAN_PAT`}}"
  },
  "builders": [{
    "type": "digitalocean",
    "api_token": "{{user `digitalocean_pat`}}",
    "region": "sfo1",
    "size": "1gb",
    "ssh_username": "freebsd",
    "image": "freebsd-10-1-x64",
    "droplet_name": "my_cool_droplet_name",
    "snapshot_name": "my_cool_droplet_name--{{timestamp}}"
  }]
}
```

Let's go over each of the parts.

The first section, `variables`, contains a listing of all the user-supplied
variables. In our case there's only one - `digitalocean_pat`. The `` {{env
`DIGITALOCEAN_PAT`}} `` part just pulls `DIGITALOCEAN_PAT` from the local env.
That's a nice way of keeping sensitive information out of config files (and Git
repos).

The second part, `builders`, is an array of builder configurations. In our case
we're just building a single snapshot for DigitalOcean. It's important to note
that the `size`, `region`, and `image` parameters need to match the available
options retrieved from the [DigitalOcean API][do-api]. We also need to specify
the `ssh_username` because, unlike all the rest of the base images on the
service, the FreeBSD base image requires you login as `freebsd` instead of
`root`.

To run this, make sure the `DIGITALOCEAN_PAT` variable is set appropriately in
your environment. Something like this should work:

```bash
export DIGITALOCEAN_PAT="<PUT YOUR GENERATED TOKEN HERE>"
```

Once you've got your environment setup, you can run the build using Packer:

```bash
packer build build.json
```

If everything went well, this should setup a temporary SSH key, create
a FreeBSD droplet, save it to your account under the name `my_cool_droplet--`
(+ a timestamp), and then shut the Droplet down (and remove the aforementioned
SSH key). If something failed, now would be a really good time to try and debug
it. You can increase the verbosity of what Packer prints to stdout by setting
the environment variable `PACKER_LOG` to 1, like so:

```bash
PACKER_LOG=1 packer build build.json
```

## Getting started with Salt

Assuming everything went well, we can start to add provisioning scripts. Let's
first change the `build.json` file to look like this:

```json
{
  "variables": {
    "digitalocean_pat": "{{env `DIGITALOCEAN_PAT`}}"
  },
  "builders": [{
    "type": "digitalocean",
    "api_token": "{{user `digitalocean_pat`}}",
    "region": "sfo1",
    "size": "1gb",
    "ssh_username": "freebsd",
    "image": "freebsd-10-1-x64",
    "droplet_name": "my_cool_droplet_name",
    "snapshot_name": "my_cool_droplet_name--{{timestamp}}"
  }],
  "provisioners": [{
      "type": "shell",
      "execute_command": "chmod +x {{.Path}}; env {{.Vars}} {{.Path}}",
      "inline": [
          "sudo pkg install -y py27-salt-2015.5.2",
          "sudo mkdir -p /srv /usr/local/etc/salt/states",
          "sudo ln -s /usr/local/etc/salt /etc/salt",
          "sudo ln -s /usr/local/etc/salt /srv/salt"
      ]
  }, {
      "type": "salt-masterless",
      "skip_bootstrap": true,
      "local_state_tree": "{{template_dir}}/salt"
  }]
}
```

That's a lot more information, so let's take a moment to digest what we've
added. There's a new section, `provisioners`, that's a list of 2 different
provisioning options. The first is a simple inline-shell provisioner, and the
second is a call to the `salt-masterless` provisioner.

I've opted to install Salt using FreeBSD's native `pkg` manager instead of
through Salt's bootstrap script. I like this method because it helps keep
everything roughly in the same place. Unfortunately, Salt still expects to find
files under `/srv/salt` and `/etc/salt` (which are the defaults). As a result,
we have to include the inline commands above to create some symlinks and
directory trees in order to make sure everything runs correctly.

The part that gave me the most trouble here is that `execute_command` line.
FreeBSD's default shell (`tcsh`) doesn't like the way Packer specifies
environment variables, so we have to adjust the template it uses. The [default
template is][ex default]:

```sh
chmod +x {{.Path}}; {{.Vars}} {{.Path}}
```

That ends up creating a command that looks something like:

```sh
chmod +x myshellscript; FOO=1 BAR=baz myshellscript
```

Unfortunately that particular invocation is not valid tcsh (it thinks `FOO=1`
is the command), so we have to adjust it by adding the `env` command like so:

```sh
chmod +x {{.Path}}; env {{.Vars}} {{.Path}}
```

One other note on the inline shell provisioner: `py27-salt-2015.5.2` is the
most current package available at the time of writing, but that may change in
the future. If you run into problems finding that package, spin up a Droplet
and run `pkg search salt` to figure out what name you should be using.

Next, we have the `salt-masterless` provisioner. This looks deceptively simple.
`skip_bootstrap` does just what you'd expect and prevents Salt from downloading
the bootstrap script. Since we're using the `pkg` version, that's exactly the
behavior we want. `local_state_tree` points to a local collection of Salt
"states" that we'll be using to configure our machine.

That's it for `build.json`. Now we need to create a new directory for our Salt
states:

```bash
mkdir salt
```

Inside the salt directory, paste the following into a file called `top.sls`:

```yaml
# http://docs.saltstack.com/en/latest/topics/tutorials/quickstart.html
base:
  '*':
    - webserver
```

This is a very simple file that says each of the nodes being configured should
be setup under the `webserver` role. Now we need to add that role. We can do so
by putting our configuration in another file, `webserver.sls`, inside the
`salt` directory:

```yaml
# create a new user called "msmith"
msmith:
    user.present:
        - fullname: Mary Smith
        - home: /home/msmith
        - gid_from_name: True
        - groups:
            - wheel
    ssh_auth.present:
        - user: msmith
        - source: salt://ssh_keys/id_rsa.pub

# make sure the Nginx logs exist, otherwise Nginx will cry
{% for f in ["access", "error"] %}
/var/log/nginx/{{ f }}.log:
    file.managed:
        - makedirs: True
{% endfor %}

nginx:
    # install Nginx via pkg, but first refresh the pkg database
    pkg.installed:
        - refresh: True
    # make sure the nginx service is enabled (rc.conf) and running
    service.running:
        - enable: True
        # reload the service whenever the pkg or config file changes
        - reload: True
        - watch:
            - pkg: nginx
            - file: /usr/local/etc/nginx/nginx.conf

# copy the Nginx config file up
/usr/local/etc/nginx/nginx.conf:
    file.managed:
        - source: salt://nginx/nginx.conf
        - user: root
        - group: wheel
        - mode: 644

# copy our site up
/usr/local/www/nginx:
    file.recurse:
        - source: salt://site
        - include_empty: True

# copy our new sshd_config file up
sshd:
    file.managed:
        - name: /etc/ssh/sshd_config
        - source: salt://ssh/sshd_config
        - user: root
        - group: wheel
        - mode: 644
    service.running:
        - reload: True
        - watch:
            - file: /etc/ssh/sshd_config
```

Let's examine this piece by piece:

```yaml
# create a new user called "msmith"
msmith:
    user.present:
        - fullname: Mary Smith
        - home: /home/msmith
        - gid_from_name: True
        - groups:
            - wheel
    ssh_auth.present:
        - user: msmith
        - source: salt://ssh_keys/id_rsa.pub
```

This section uses Salt's [user state][salt.states.user] to configure a new
user. Specifically, it uses the `user.present` API. The `salt://` prefix on the
filename is a convention that Salt uses to indicate the file is local. We'll
add the file in the next section.

This brings us to the next section, which illustrates a powerful component of
Salt's default configuration language. Each YAML file will be run through
[Jinja2][] first, which means you can use all the same looping constructs you
may already be familiar with.

```yaml
# make sure the Nginx logs exist, otherwise Nginx will cry
{% for f in ["access", "error"] %}
/var/log/nginx/{{ f }}.log:
    file.managed:
        - makedirs: True
{% endfor %}
```

All this section does is make sure that the log files we reference in our
configuration later on (`/var/log/nginx/access.log` and
`/var/log/nginx/error.log`) exist, otherwise Nginx will refuse to start.

```yaml
nginx:
    # install Nginx via pkg, but first refresh the pkg database
    pkg.installed:
        - refresh: True
    # make sure the Nginx service is enabled (rc.conf) and running
    service.running:
        - enable: True
        # reload the service whenever the pkg or config file changes
        - reload: True
        - watch:
            - pkg: nginx
            - file: /usr/local/etc/nginx/nginx.conf
```

This is where a lot of the meat happens. The first step, `pkg.installed`, uses
Salt's [pkg state][salt.states.pkg] to make sure Nginx is installed. The
`refresh: True` line just makes sure that the `pkg` cache is refreshed prior to
the install.

The next step, `service.running`, makes sure that the Nginx service is running.
It's using Salt's [service state][salt.states.service] to do that. The `enable:
True` line makes sure that the Nginx service is enabled in the `/etc/rc.conf`
file (`nginx_enable="YES"`). Finally, the `reload` and `watch` sections are
telling Salt to reload the Nginx service whenever the pkg changes (via an
upgrade, for example) or the configuration file changes.

Speaking of the configuration file, we need to copy that up to our server.

```yaml
# copy the Nginx config file up
/usr/local/etc/nginx/nginx.conf:
    file.managed:
        - source: salt://nginx/nginx.conf
        - user: root
        - group: wheel
        - mode: 644
```

This uses Salt's [file state][salt.states.file] to copy the file up with the
correct permissions. The most interesting part about this section is the
`source` line. The `salt://nginx/nginx.conf` value is a local-file reference to
`nginx/nginx.conf` within the `salt` directory (i.e.
`packed-salt/salt/nginx/nginx.conf`). Everything else should look pretty basic.
We'll add that file in a moment, as soon as we're done going over the rest of
the provisioning script.

```yaml
# copy our site up
/usr/local/www/nginx:
    file.recurse:
        - source: salt://site
        - include_empty: True
```

This part should look pretty familiar. It's copying the `salt/site` directory
(i.e. `packed-salt/salt/site`) to `/usr/local/www/nginx` on the remote server.
This is where our public web files (i.e. HTML, JS, etc.) will live.


```yaml
sshd:
    file.managed:
        - name: /etc/ssh/sshd_config
        - source: salt://ssh/sshd_config
        - user: root
        - group: wheel
        - mode: 644
    service.running:
        - reload: True
        - watch:
            - file: /etc/ssh/sshd_config
```

Almost done. This moves a new `sshd_config` file into place and makes sure that
`sshd` is reloaded whenever that file changes. You can read more about the
`watch` option in the [requisites documentation][reqs].

### Configuring Nginx

Now is a good time to add that `nginx.conf` file we talked about earlier.
First, create the directory structure:

```bash
# assuming you're in the root of the project (i.e. packed-salt)
mkdir -p salt/nginx
```

Now create a `salt/nginx/nginx.conf` file with the following contents:

```
user  www;
worker_processes  1;
error_log /var/log/nginx/error.log info;

events {
    worker_connections  512;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    access_log /var/log/nginx/access.log;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80 default_server;
        server_name  _;
        root /usr/local/www/nginx;
        index index.html;

        location / {
            try_files $uri $uri/ =404;
        }

        error_page      500 502 503 504  /50x.html;
        location = /50x.html {
            root /usr/local/www/nginx-dist;
        }
    }
}
```

This isn't an Nginx configuration tutorial, so I'm going to skip over most of
this. Important things to note are the locations of the `error` and `access`
logs, as well as the `server_name` (set to the `_` wildcard for now).

### Adding a site

If you've already got a static HTML site, now would be a great time to grab it.
I used a built version of my [Jekyll site][]. Just place it in `salt/site` and
you're good to go.

### Adding your public SSH key

We also need to make sure your public SSH key is on the server. Create
a `salt/ssh_keys` directory and place your public key (usually `id_rsa.pub`)
inside.

### Setting up a new `sshd_config` file

This is where you get to customize the `sshd_config` file. You'll want to save
it to `salt/ssh/sshd_config` in your local project directory. Here's the one
I was using:

```
Port 22
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

Protocol 2

SyslogFacility AUTH
LogLevel INFO

# Authentication:
StrictModes yes
MaxAuthTries 3

RSAAuthentication yes
PubkeyAuthentication yes

# The default is to check both .ssh/authorized_keys and
# .ssh/authorized_keys2
AuthorizedKeysFile .ssh/authorized_keys

# stop passwords
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
# pam is ok without passwords
UsePAM yes

# override default of no subsystems
Subsystem       sftp    /usr/libexec/sftp-server

# turn off root login
PermitRootLogin no
```

## All together now

Let's try running it. From the root directory (i.e. `packed-salt`):

```bash
packer build build.json
```

If this didn't work, it's time to get your hands dirty. Try running
`PACKER_LOG=1 packer build build.json` and reading through the errors as they
happen. I found searching for `Result: False` in the output stream usually
pinpointed the errors pretty quickly.

If it worked, congratulations! You've successfully created a DigitalOcean
snapshot of a FreeBSD machine, complete with a minimal Nginx configuration and
password-less SSH authentication. The next step is to create a Droplet from
that base image. You can go to your [DigitalOcean control panel][do-cp] and
create a new droplet using the `my_cool_droplet_name--TIMESTAMP` image as
a base.

It's also important to note that this server probably still isn't production
ready. That being said, hopefully I've sparked your interest in these tools and
given you enough of a platform to begin learning and using them.

Was this tutorial helpful to you? Did you run into unexpected problems? Let me
know on Twitter ([@ciarandowney][]) or App.net ([@ciarand][])!

{% endraw %}

[@ciarand]: https://app.net/ciarand
[@ciarandowney]: https://twitter.com/ciarandowney
[DigitalOcean]: https://www.digitalocean.com/?refcode=4e262cd0afdb
[Jekyll site]: https://github.com/ciarand/ciarand.github.io
[Jinja2]: http://jinja.pocoo.org/
[Packer]: https://packer.io
[Salt]: https://saltstack.com/
[do-api]: https://developers.digitalocean.com/documentation/v2/
[do-cp]: https://cloud.digitalocean.com/droplets
[ex default]: https://github.com/mitchellh/packer/blob/v0.8.0/provisioner/shell/provisioner.go#L88-L90
[packer-tutorial]: https://packer.io/intro/getting-started/build-image.html
[pat]: https://cloud.digitalocean.com/settings/applications
[provisioners]: https://packer.io/docs/templates/provisioners.html
[reqs]: https://docs.saltstack.com/en/latest/ref/states/requisites.html
[salt.states.file]: https://docs.saltstack.com/en/latest/ref/states/all/salt.states.file.html
[salt.states.pkg]: https://docs.saltstack.com/en/latest/ref/states/all/salt.states.pkg.html
[salt.states.service]: https://docs.saltstack.com/en/latest/ref/states/all/salt.states.service.html
[salt.states.user]: https://docs.saltstack.com/en/latest/ref/states/all/salt.states.user.html
