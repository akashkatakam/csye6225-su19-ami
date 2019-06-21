#!/usr/bin/env bash
#installing MySQL
#sudo yum update -y
sudo yum install -y wget
sudo yum install java-1.8.0-openjdk.x86_64 -y
sudo yum localinstall https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
sudo yum install mysql-server
sudo systemctl enable mysqld
sudo systemctl start mysqld
wget -q --no-cookies -S "http://archive.apache.org/dist/tomcat/tomcat-9/v9.0.16/bin/apache-tomcat-9.0.16.tar.gz"
tar -xf apache-tomcat-9.0.16.tar.gz
sudo mv apache-tomcat-9.0.16/ /opt/tomcat/
echo "export CATALINA_HOME='/opt/tomcat/'" >> ~/.bashrc
source ~/.bashrc
sudo useradd -r tomcat --shell /bin/false
sudo chown -R tomcat:tomcat /opt/tomcat/
sudo cat > /etc/systemd/system/tomcat.service << EOF
[Unit]
Description=Apache Tomcat 9
After=syslog.target network.target
[Service]
User=tomcat
Group=tomcat
Type=forking
Environment=JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk
Environment=CATALINA_PID=/opt/tomcat/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl start tomcat

