FROM centos:7
RUN yum install -y wget
RUN wget https://github.com/exoscale/cli/releases/download/v1.20.2/exoscale-cli_1.20.2_linux_amd64.rpm -O /exo.rpm
RUN rpm -i /exo.rpm
COPY sda.sh /sda.sh
RUN chmod +x /sda.sh
RUN mkdir /srv/service-discovery/
RUN touch /srv/service-discovery/config.json
RUN chmod 777 /srv/service-discovery/config.json
CMD ["/sda.sh"]