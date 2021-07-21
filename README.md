# fhir-intergratedml-example
An example on how to use InterSystems IRIS for Health FHIR database to perform ML models througth InterSystems IRIS IntegratedML

## Description
IntegratedML is a great feature for train/test and deploy ML models. FHIR is a powerful standard for health information interoperability. This project aims to show how to use IRIS/IRIS for Health tools, like DTL transformations to prepare FHIR data for applying ML models in IntegratedML.
Some potential applications for ideas presented in this project:
 - Reuse/extend DTL transformations in other FHIR databases for custom ML models
 - Use DTL transformations for normalize FHIR messages and publish ML models as services
 - Create a kind of models + transformations rules repository for use within any FHIR dataset
 
![Idea diagram](https://raw.githubusercontent.com/jrpereirajr/fhir-integratedml-example/main/img/diagram1.png)

## Demonstration
In order to demonstrate the project concept, a appointment no-show prediction model was set up.

First, a training dataset was used to generate synthetic FHIR resources. This dataset has information about patients, conditions, appointments and reminders sent to patients - represented by different FHIR resources. This step emulates a true FHIR database, in which no-show prediction could be applied. This is done by this command (which is already executed in installation script, so you don't need to run it again):

```objectscript
Write "Generating FHIR data based on training dataset...",!
ZWrite ##class(PackageSample.PopulateNoShow).%New().Populate(2000)
```

With the FHIR database ready to use, data needs to be transformed by combining the FHIR resources which are relevant to the problem, into a single table. Such FHIR combination is done by using this [DTL transformations](https://github.com/jrpereirajr/fhir-integratedml-example/blob/main/src/PackageSample/NoShowDTL.cls):

![DTL sample](https://raw.githubusercontent.com/jrpereirajr/fhir-integratedml-example/main/img/7mAtWpsjz5.png)

As DTL could be exported/imported, it's possible to share ML models applied on FHIR data. These transformations also could be extended by another team if necessary.

Such DTL could be invoked by this command (which is also executed by installation script):

```objectscript
Set source = ##class(HSFHIR.X0001.S.Patient).%OpenId(patientId)
$$$TOE(sc, ##class(PackageSample.NoShowDTL).Transform(source, .target))
```

After applying the DTL transformation, FHIR resources are mapped to a single row, creating a table which could be used to train a ML model for no-show prediction. Run this command to train the no-show model:

```objectscript
Do ##class(PackageSample.Utils).TrainNoShowModel()
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
