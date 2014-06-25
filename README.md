# Agile Test Management

Tarantula is modern tool for managing software testing in agile
software projects. It's free, licensed as open source software under
GNU GPLv3.

[www.testiatarantula.com](http://www.testiatarantula.com)

# Install

## Requirements

* Recommended platform is
  [CentOS-6.X for i386 Architecture](http://isoredirect.centos.org/centos/6/isos/i386/). Tarantula
  has installation script which automates most of the installation
  steps. CentOs 6.x for x86_64 Architecture is not recommended, as it
  seems to have problems with memcached/passenger subsystems, at least
  with low memory systems.
* Root Access to Linux
* Access to SMTP Server which doesn’t require authentication. Used for
  sending new user passwords. If not available, you can install
  e.g. PostFix on same server and set authenticated mail relay via
  another server.

## Installation

### Install RVM

Latest Tarantula uses Rails 3.2.* and Ruby 1.9.3. Easiest way to use
those in CentOS is using [Ruby Version Manager](http://rvm.io). If you
don't already have RVM installed, use following instructions,
otherwise skip to [Install Tarantula](#install-tarantula)

Install RVM dependencies:

```
yum install make gcc readline-devel zlib-devel openssl-devel libyaml redhat-lsb
```

Install RVM system wide:

```
curl -L https://get.rvm.io | sudo bash -s stable --rails
source /usr/local/rvm/scripts/rvm
```

<a name="install-tarantula"></a>
### Install Tarantula

Login as root.

Activate required extra repositories:

```shell
yum install http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
```

SELinux has to be in permissive mode to allow Apache web server to run
Ruby-on-Rails applications on Passenger module. Edit config file with
e.g. nano text editor:

```shell
nano /etc/selinux/config
```

Change SELINUX setting in file to permissive:

```shell
SELINUX=permissive
```

Set default Ruby with RVM:

```shell
rvm use 1.9.3
```

Download and execute installation script:

```shell
yum -y install wget
wget https://raw.github.com/prove/tarantula/master/vendor/installer/install.sh
bash install.sh
```

Some installation tasks (bundler, rubygems may take long
time. Please be patient.)

Press **Enter** to accept default value for user account to be used to run
processes:

```
Which user will be running Tarantula processes? [apache]
```

After a while, installation is complete:


    Done installing packages and Tarantula files

    Verify/edit database settings in file:  /opt/tarantula/rails/config/database.yml
    If db settings are OK run
    RAILS_ENV=production rake tarantula:install in Rails root (/opt/tarantula/rails) to initialize DB.

    Usable passenger configuration generated to /etc/httpd/conf.d/tarantula.conf

    Compile Apache native mod_passenger as root by running:
    passenger-install-apache2-module and restart Apache: service httpd restart

You can ignore instructions above. All necessary steps are listed
below.

Go to rails directory and run application install script to create databases etc.:

```shell
cd /opt/tarantula/rails
RAILS_ENV=production rake tarantula:install
```

You are prompted for some settings (host running tarantula, email
settings etc):

**Protocol, host, and port**: This is the web address of installed
  Tarantula. Used in email notifications, e.g. this address is
  included as link to emails sent to new
  users. E.g. tarantula.yourdomain.com

**Admin Email**: System will sent emails using this address as email’s
  “FROM” field.

**SMTP Address**: SMTP server address. E.g smtp.yourdomain.com or
  localhost (if you opt to run local mail service, e.g. postfix).

**SMTP Port**: Usually 25.

**SMTP Domain**: E.g. yourdomain.com.

After tarantula:install task is completed, allow access to http port by modifying firewall settings:

```shell
system-config-firewall-tui
```

Cursor keys can be used to move between choices.  Select with
space-bar.  Press **Customize** and make sure that WWW (HTTP) is
enabled.  Press **Close**, **OK** and **Yes** to save new settings.

Set web and sql servers to start on boot:

```shell
chkconfig httpd --add
chkconfig --level 35 httpd on
chkconfig mysqld --add
chkconfig --level 35 mysqld on
chkconfig memcached --add
chkconfig --level 35 memcached on
chkconfig delayed_job --add
chkconfig --level 35 delayed_job on
```

Install passenger module (runs Tarantula Ruby-on-Rails application on
top of Apache). You don’t need to do anything after this command, as
all apache configuration has been taken care already by previous rake
task.

```shell
passenger-install-apache2-module
```

Setup cron for scheduled tasks.

```shell
cp /opt/tarantula/rails/config/crontab /etc/cron.d/tarantula
chown root:root /etc/cron.d/tarantula
chmod 0644 /etc/cron.d/tarantula
```

Everything should be now set. Reboot system to make sure that all
services run correctly after it.

```shell
reboot
```

After reboot open web browser to tarantula hostname or ip to start
using Tarantula. Login with name: admin, password: admin. Please
change password on first login.
