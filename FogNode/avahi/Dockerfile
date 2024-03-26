FROM alpine:latest

LABEL maintainer="Philipp Zagar <zagar@stanford.edu>" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.name="philippzagar/avahi" \
    org.label-schema.description="Simple Avahi docker image" \
    org.label-schema.version="0.1" \
    org.label-schema.url="https://hub.docker.com/r/philippzagar/avahi" \
    org.label-schema.vcs-url="https://github.com/StanfordSpezi/SpeziLLM"

# Install Avahi daemon without dbus dependency
RUN apk --no-cache --no-progress add avahi

# Setup services
RUN rm -rf /etc/avahi/services
COPY services/ /etc/avahi/services

# Disable D-Bus in Avahi's configuration
RUN sed -i 's/.*enable-dbus=.*/enable-dbus=no/' /etc/avahi/avahi-daemon.conf

# Run Avahi daemon with non-root user, avoid daemonizing to keep container running
CMD ["avahi-daemon", "--no-chroot"]