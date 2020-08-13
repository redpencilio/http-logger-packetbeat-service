FROM docker.elastic.co/beats/packetbeat-oss:7.8.1
USER root
COPY packetbeat.yml /usr/share/packetbeat/packetbeat.yml
RUN chown root:root /usr/share/packetbeat/packetbeat.yml
