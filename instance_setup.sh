#!/usr/bin/env bash
#installing MySQL
sudo yum install wget firewalld -y
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo systemctl status firewalld
sudo yum install -y wget
sudo yum install java-1.8.0-openjdk.x86_64 -y
wget -q --no-cookies -S "http://archive.apache.org/dist/tomcat/tomcat-9/v9.0.16/bin/apache-tomcat-9.0.16.tar.gz"
tar -xf apache-tomcat-9.0.16.tar.gz
sudo mv apache-tomcat-9.0.16/ /opt/tomcat/
echo "export CATALINA_HOME='/opt/tomcat/'" >> ~/.bashrc
source ~/.bashrc
sudo useradd -r tomcat --shell /bin/false
cd /opt && sudo chown -R tomcat tomcat/
sudo sh -c 'chmod +x /opt/tomcat/bin/*.sh'
cat << EOF | sudo tee -a /etc/systemd/system/tomcat.service
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
sudo systemctl enable tomcat
sudo systemctl status tomcat
sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp
sudo firewall-cmd --reload

echo "Creating code deploy agent in the AMI"
sudo yum install ruby -y
cd /home/centos
wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
# If code deploy aget is not running then start the service first
# sudo service codedeploy-agent start
sudo service codedeploy-agent status
echo "Installing Unified Cloud Watch Agent"
wget https://s3.us-east-1.amazonaws.com/amazoncloudwatch-agent-us-east-1/centos/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm
sudo systemctl status amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent
sudo systemctl status amazon-cloudwatch-agent
cd /opt
sudo mkdir cloudwatch
cat << EOF | sudo tee -a /opt/cloudwatch/cloudwatch-config.json
{
  \"agent\": {
    \"metrics_collection_interval\": 10,
    \"logfile\": \"/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log\"
  },
  \"logs\": {
    \"logs_collected\": {
      \"files\": {
        \"collect_list\": [
          {
            \"file_path\": \"/opt/tomcat/logs/csye6225.log\",
            \"log_group_name\": \"csye6225_su2019\",
            \"log_stream_name\": \"webapp\"
          }
        ]
      }
    },
    \"log_stream_name\": \"cloudwatch_log_stream\"
  },
  \"metrics\":{
    \"metrics_collected\":{
      \"statsd\":{
        \"service_address\":\":8125\",
        \"metrics_collection_interval\":10,
        \"metrics_aggregation_interval\":0
      }
    }
  }
}
EOF
cd /home/centos
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent
