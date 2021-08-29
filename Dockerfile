ARG IMAGE=store/intersystems/iris-community:2020.1.0.204.0
ARG IMAGE=intersystemsdc/iris-community:2020.1.0.209.0-zpm
ARG IMAGE=intersystemsdc/iris-community:2020.2.0.204.0-zpm
ARG IMAGE=intersystemsdc/irishealth-community:2020.2.0.204.0-zpm
ARG IMAGE=intersystemsdc/irishealth-community:2020.3.0.200.0-zpm
ARG IMAGE=intersystemsdc/irishealth-ml-community:2021.1.0.215.0-zpm
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
