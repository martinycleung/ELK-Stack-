#!/bin/bash
#Script made for ELK Stack installtion
#Author: Vinod.N K
#Usage: Nginx, Java, Elasticsearch, Logstash, Kibana, Redis
#Distro : Linux -Centos, Rhel, and any fedora
#Check whether root user is running the script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# INTRODUCTION

: '
Install and configure R (Redis) + ELK server from scratch on CentOS 6.5.
* Logstash version 1.4.2
* Elasticsearch version 1.3.2
- You have to change the IP-address to the IP of the central server in configuration marked with [ip-for-central-server].
- You may have to change the Elasticsearch network.host parameter to the internal IP of your server to use eg. GET on the URL from Kibana.
- You may have to change the Kibana elasticsearch parameter to the actual URL with your internal IP to connect probably to the interface.
'
# MAIN

main() {
  dependencies
  elasticsearch
  logstash
  kibana
  redis
  start_and_chkconfig
}


### DEPENDENCIES

dependencies() {
  echo ""
  echo "Dependencies"

  sleep 2

  yum -y install java-1.7.0-openjdk nginx redis
}

# ELASTICSEARCH Installtion
echo Installing Elasticsearch ...

elasticsearch() {
  echo ""
  echo "Elasticsearch"

cat <<EOF >> /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-1.3]
name=Elasticsearch repository for 1.3.x packages
baseurl=http://packages.elasticsearch.org/elasticsearch/1.3/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1
EOF

  yum -y install elasticsearch

  sed -i '/network.host/c\network.host: localhost' /etc/elasticsearch/elasticsearch.yml
  sed -i '/discovery.zen.ping.multicast.enabled/c\discovery.zen.ping.multicast.enabled: false' /etc/elasticsearch/elasticsearch.yml
  sed -i '/cluster.name/c\cluster.name: elasticsearch' /etc/elasticsearch/elasticsearch.yml

  chown -R elasticsearch:elasticsearch /var/lib/elasticsearch/ /var/log/elasticsearch/
}

# LOGSTASH Installtion
echo Installing Logstash ....

logstash() {
  echo ""
  echo "Logstash"

  sleep 2

cat <<EOF >> /etc/yum.repos.d/logstash.repo
[logstash-1.4]
name=logstash repository for 1.4.x packages
baseurl=http://packages.elasticsearch.org/logstash/1.4/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1
EOF

  yum -y install logstash-1.4.2

cat <<EOF >> /etc/logstash/conf.d/default.conf
input {
  redis {
          host => "localhost"
          type => "redis"
          data_type => "list"
          key => "logstash"
  }
}
filter {
}
output {
  elasticsearch {
    host => "[ip-for-central-server]"
    cluster => "elasticsearch"
  }
  stdout { codec => rubydebug }
}
EOF

  chown -R logstash:logstash /var/lib/logstash/ /var/log/logstash/
}

# KIBANA Installtion...
echo Installing Kibana 
kibana() {
  echo ""
  echo "Kibana"

  sleep 2

  cd /usr/share/nginx/html

  curl -O https://download.elasticsearch.org/kibana/kibana/kibana-3.0.1.tar.gz
  tar -xzvf kibana-3.0.1.tar.gz
  cd kibana-3.0.1
  mv * ..; cd ..; ls
}


# REDIS Installtion
echo  Installtion Redis
redis() {
  echo ""
  echo "Redis"

  sleep 2

  sed -i '/bind 127.0.0.1/c\bind 0.0.0.0' /etc/redis.conf

  mkdir -p /var/log/redis
  touch /var/log/redis/redis.log
  chown -R redis:redis /var/log/redis/
}

#Starting  on boot Config

start_and_chkconfig() {
  echo ""
  echo "Starting services + chkconfig"

  sleep 2

  chkconfig elasticsearch on
  chkconfig logstash on
  chkconfig redis on
  chkconfig nginx on

  /etc/init.d/elasticsearch restart
  /etc/init.d/logstash restart
  /etc/init.d/redis restart
  /etc/init.d/nginx restart
}

# Logstash In Client 

main

# Install logstash agents on your agent servers:
: '
Redhat-based:
yum -y install java-1.7.0-openjdk
cat <<EOF >> /etc/yum.repos.d/logstash.repo
[logstash-1.4]
name=logstash repository for 1.4.x packages
baseurl=http://packages.elasticsearch.org/logstash/1.4/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1
EOF

yum -y install logstash-1.4.2
Debian-based:
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
sudo apt-get -y install oracle-java7-installer
echo "deb http://packages.elasticsearch.org/logstash/1.4/debian stable main" | sudo tee /etc/apt/sources.list.d/logstash.list
sudo apt-get update
sudo apt-get install logstash=1.4.2-1-2c0f5a1

##Bug: In Ubuntu you may have to edit the LS_GROUP=logstash to LS_GROUP=adm in the logstash Init script - known bug

# Redirect output to Redis at this server:
input {
        file {
                type => "secure-log"
                path => ["/var/log/secure"]
        }
}
output {
        redis {
                host => "[ip-for-central-server]"
                data_type => "list"
                key => "logstash"
        }
}
'
