# fhir-intergratedml-example
An example on how to use InterSystems IRIS for Health FHIR database to perform ML models througth InterSystems IRIS IntegratedML

  * [Description](#description)
  * [Demonstration](#demonstration)
  * [Installation](#installation)
  * [Team](#team)

## Description
IntegratedML is a great feature for train/test and deploy ML models. FHIR is a powerful standard for health information interoperability. This project aims to show how to use IRIS/IRIS for Health tools, like DTL transformations to prepare FHIR data for applying ML models in IntegratedML.
Some potential applications for ideas presented in this project:
 - Reuse/extend DTL transformations in other FHIR databases for custom ML models
 - Use DTL transformations for normalize FHIR messages and publish ML models as services
 - Create a kind of models + transformations rules repository for use within any FHIR dataset
 
![Idea diagram](https://raw.githubusercontent.com/jrpereirajr/fhir-integratedml-example/main/img/diagram1.1.png)

![Idea implemented](https://raw.githubusercontent.com/jrpereirajr/fhir-integratedml-example/main/img/ybb74rqcoy.gif)

## Demonstration
In order to demonstrate the project concept, two models were setup:
* An appointment no-show prediction model
* A heart failure prediction model

First, training datasets were used to generate synthetic FHIR resources. These datasets had information about patients, conditions, observations, encounters, appointments and reminders sent to patients - represented by different FHIR resources. This step emulates a true FHIR database, in which no-show and heart failure predictions could be applied. 

This is done by these commands (which are already executed in installation script, so you don't need to run them again):

```objectscript
Write "Generating FHIR data based on training datasets...",!
ZWrite ##class(PackageSample.PopulateNoShow).%New().Populate(2000)
ZWrite ##class(PackageSample.PopulateHeartFailure).%New().Populate(299)
```

With the FHIR database ready to use, data needs to be transformed by combining the FHIR resources which are relevant to the problem, into single tables. Such FHIR combination is done by DTL transformations [NoShowDTL](https://github.com/jrpereirajr/fhir-integratedml-example/blob/main/src/PackageSample/NoShowDTL.cls) and [HeartFailureDTL](https://github.com/jrpereirajr/fhir-integratedml-example/blob/main/src/PackageSample/HeartFailureDTL.cls):

![DTL sample](https://raw.githubusercontent.com/jrpereirajr/fhir-integratedml-example/main/img/7mAtWpsjz5.png)

As DTL transformations could be exported/imported, it's possible to share ML models applied on FHIR data. These transformations also could be extended by another team if necessary.

Such DTL transformations could be invoked by this command (which is also executed by installation script):

```objectscript
Set source = ##class(HSFHIR.X0001.S.Patient).%OpenId(patientId)
$$$TOE(sc, ##class(PackageSample.NoShowDTL).Transform(source, .target))
$$$TOE(sc, ##class(PackageSample.HeartFailureDTL).Transform(source, .target))
```

After applying the DTL transformations, FHIR resources are mapped to single rows, creating tables which could be used to train ML models for no-show and heart failure predictions. These commands train the models (they are executed by instalation):

```objectscript
Write "Training models..."
Do ##class(PackageSample.Utils).TrainNoShowModel()
Do ##class(PackageSample.Utils).TrainHeartFailureModel()
```

Or, you also can follow these steps to try each sql statement by yourself:

```sql
-- create the training dataset
CREATE OR REPLACE VIEW PackageSample.NoShowMLRowTraining AS SELECT * FROM PackageSample.NoShowMLRow WHERE ID < 1800
-- create the testing dataset
CREATE OR REPLACE VIEW PackageSample.NoShowMLRowTest AS SELECT * FROM PackageSample.NoShowMLRow WHERE ID >= 1800

-- avoid errors in CREATE MODEL command; ignore any error here
DROP MODEL NoShowModel
-- creates an IntegratedML model for predinction Noshow column based on other ones, using the PackageSample.NoShowMLRowTraining dataset for tranning step; seed parameter here is to ensure results reproducibility
CREATE MODEL NoShowModel PREDICTING (Noshow) FROM PackageSample.NoShowMLRowTraining USING {"seed": 6}
-- trains the model, as set up in CREATE MODEL command
TRAIN MODEL NoShowModel
-- display information about the trainned model, like which ML model was selected by IntegratedML
SELECT * FROM INFORMATION_SCHEMA.ML_TRAINED_MODELS
-- use the PREDICT function to see how to use the model in SQL statements
SELECT top 10 PREDICT(NoShowModel) AS PredictedNoshow, Noshow AS ActualNoshow FROM PackageSample.NoShowMLRowTest
-- run a validation on testing dataset and calculate the model performance metrics
VALIDATE MODEL NoShowModel FROM PackageSample.NoShowMLRowTest
-- display performance metrics
SELECT * FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS
```

```sql
-- create the training dataset
CREATE OR REPLACE VIEW PackageSample.HeartFailureMLRowTraining AS SELECT DEATHEVENT,age,anaemia,creatininephosphokinase,diabetes,ejectionfraction,highbloodpressure,platelets,serumcreatinine,serumsodium,sex,smoking,followuptime FROM PackageSample.HeartFailureMLRow WHERE ID < 200
-- create the testing dataset
CREATE OR REPLACE VIEW PackageSample.HeartFailureMLRowTest AS SELECT DEATHEVENT,age,anaemia,creatininephosphokinase,diabetes,ejectionfraction,highbloodpressure,platelets,serumcreatinine,serumsodium,sex,smoking,followuptime FROM PackageSample.HeartFailureMLRow WHERE ID >= 200

-- avoid errors in CREATE MODEL command; ignore any error here
DROP MODEL HeartFailureModel
-- display information about the trainned model, like which ML model was selected by IntegratedML
CREATE MODEL HeartFailureModel PREDICTING (DEATHEVENT) FROM PackageSample.HeartFailureMLRowTraining USING {"seed": 6}
-- trains the model, as set up in CREATE MODEL command
TRAIN MODEL HeartFailureModel
-- display information about the trainned model, like which ML model was selected by IntegratedML
SELECT * FROM INFORMATION_SCHEMA.ML_TRAINED_MODELS
-- use the PREDICT function to see how to use the model in SQL statements
SELECT top 10 PREDICT(HeartFailureModel) AS PredictedHeartFailure, DEATHEVENT AS ActualHeartFailure FROM PackageSample.HeartFailureMLRowTest
-- run a validation on testing dataset and calculate the model performance metrics
VALIDATE MODEL HeartFailureModel FROM PackageSample.HeartFailureMLRowTest
-- display performance metrics
SELECT * FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS
```

The last SQL statement may show you the classification performance parameters:

![Model performance parameters - no show model](https://raw.githubusercontent.com/jrpereirajr/fhir-integratedml-example/main/img/G6786RVu7j.png)

![Model performance parameters - heart failure model](https://raw.githubusercontent.com/jrpereirajr/fhir-integratedml-example/main/img/hk7KEBxPyT.png)

The same transformation could be applied to transform FHIR resources came from external systems, through a REST API for instance (checkout the [code](https://github.com/jrpereirajr/fhir-integratedml-example/blob/main/src/PackageSample/Dispatch.cls)):

![API video sample](https://raw.githubusercontent.com/jrpereirajr/fhir-integratedml-example/main/img/rUdnZR3LMp.gif)

![API sample](https://raw.githubusercontent.com/jrpereirajr/fhir-integratedml-example/main/img/8b9aPxKQHB1.png)

## Installation 

Clone/git pull the repo into any local directory

```
$ git clone https://github.com/jrpereirajr/fhir-integratedml-example.git
```

Open the terminal in this directory and run:

```
$ cd fhir-integratedml-example
$ docker-compose up -d
```

## Team
- [José Roberto Pereira Junior](https://github.com/jrpereirajr)
- [Henrique Gonçalves Dias](https://github.com/diashenrique/)
