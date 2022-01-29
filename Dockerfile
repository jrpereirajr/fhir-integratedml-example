ARG IMAGE=intersystemsdc/irishealth-ml-community
FROM $IMAGE

USER root

WORKDIR /opt/irisapp
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/irisapp
USER ${ISC_PACKAGE_MGRUSER}

COPY src src
COPY data/fhir fhirdata
COPY data/train traindata
# install swagger-ui manually to avoid zpm errors
# todo: remove after fixing zpm unavailability
RUN mkdir /tmp/swagger-ui
COPY misc/swagger-ui /tmp/swagger-ui
COPY iris.script /tmp/iris.script

# run iris and initial 
RUN iris start IRIS \
	&& iris session IRIS < /tmp/iris.script
