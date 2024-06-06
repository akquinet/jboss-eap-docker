# Inspired by https://github.com/jboss-dockerfiles/wildfly/blob/master/Dockerfile
FROM eclipse-temurin:11-ubi9-minimal

ENV EAP_VERSION=${version.eap}

# Starting on jdk 21 eclipse-temurin is based on ubi9-minimal version 9.3
#   that doesn't includes shadow-utils package that provides groupadd & useradd commands
# Conditional RUN: IF no groupadd AND microdnf THEN: update, install shadow-utils, clean
RUN if ! [ -x "$(command -v groupadd)" ] && [ -x "$(command -v microdnf)" ]; then microdnf update -y && microdnf install --best --nodocs -y shadow-utils unzip && microdnf clean all; fi \
  && if ! [ -x "$(command -v unzip)" ] && [ -x "$(command -v microdnf)" ]; then microdnf update -y && microdnf install --best --nodocs -y unzip && microdnf clean all; fi

WORKDIR /opt/jboss

RUN groupadd -r jboss -g 1000 && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss && \
    chmod 755 /opt/jboss

ENV JBOSS_HOME /opt/jboss/eap

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