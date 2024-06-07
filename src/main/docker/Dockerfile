# Inspired by https://github.com/jboss-dockerfiles/wildfly/blob/master/Dockerfile
FROM eclipse-temurin:11-ubi9-minimal

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

ENV EAP_VERSION=${version.eap}
ENV JBOSS_HOME /opt/jboss/eap

WORKDIR /opt/jboss

COPY maven/scripts/*.sh /tmp

RUN http_proxy=$HTTP_PROXY https_proxy=$HTTPS_PROXY no_proxy=$NO_PROXY sh /tmp/install_missing_packages.sh unzip=unzip groupadd=shadow-utils

RUN groupadd -r jboss -g 1000 && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss && chmod 755 /opt/jboss

ADD maven/dist/jboss-eap.zip /opt/jboss

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd /opt/jboss \
    && unzip jboss-eap.zip \
    && mv jboss-eap-$EAP_VERSION $JBOSS_HOME \
    && rm jboss-eap.zip \
    && chmod 755 ${JBOSS_HOME}/bin/*.sh \
    && chown -R jboss:jboss ${JBOSS_HOME} \
    && chmod -R g+rw ${JBOSS_HOME}

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

USER jboss

# Expose the ports in which we're interested
EXPOSE 8080

# Set the default command to run on boot
CMD ["/opt/jboss/eap/bin/standalone.sh", "-b", "0.0.0.0"]