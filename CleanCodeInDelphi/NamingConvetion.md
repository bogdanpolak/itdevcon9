# Naming convention for the BSC Academy.

## Information box

| Data | Value |
| - | - |
| version | 1.0 |
| state | **approved** |
| published | **2018-10-11** |
| authors | Bogdan Polak |
| developed since | 2018-09-01 |

## Convention

| Element | Sample | Rules |
| - | - | - |
| units with code only | Model.Customer.pas | Multi-segment name: [mode info](#naming-units)  |
| units with components | Form.Customer.pas | Multi-segment name: [mode info](#naming-units)  | 
| class | TPizza | [CamelCase](#camel-case), capital ```T``` at the beginning  |
| components | lbxBooks | [CamelCase](#camel-case), capital ```T``` at the beginning  |
| method | changeState() | [CamelCase](#camel-case) starting with small letter |
| class attribute | FAppVersion | [CamelCase](#camel-case), capital ```F``` at the beginning |
| global variables | Form1 | **Warning!** Global variables should be avoided. ([Avoid global variables](#reference))  |
| local variables | FirstName | [CamelCase](#camel-case) with capital letter |
| parameters | FirstName | [CamelCase](#camel-case) with capital letter |

## Naming Units

Units should be named according to the following rules. A multi-segment name with segments separated by dots. Name should explain a role of the containing code. This segments are mimics the namespaces. The name of each segment starts with a capital letter. If segment contains more than one word use [CamelCase](#camel-case). 

Segments in the name can be more than two. Recommendation to map the project folders structure into the the structure of the namespaces.

In the future, the structure of the namespaces should be more precisely defined, but currently we are not able to define it.

Proposals of base segments for the project:

* Units with components (forms, frames, data modules, ...):
    * Module.
    * Frame.
    * Dialog.
    * Form.
* Units with code only:
    * Database.
    * Utils.
    * Data.
    * Logic.
    * Unit. (better not to use this)
* Try too use MVC pattern to separate the controller units form the model units:
    * Model.
    * Controller.

## Camel Case

* The names should to inform about the purpose of the containing / defining objects.
* The number of words and the length of the name should be as small as possible, but it should explain the purpose and use of the object precisely.
* The name should be in accordance with the *CleanCode* rules, that is, it should substitute the comments.
* **Names must be written in English**. Please use the dictionary if in doubt.
* Badly chosen names can be rejected during the code review.

* **Exceptions**
    * Unit names - they may have the form of a shortcut

## Reference

* **Avoid global variables**
    * In some forms and some data modules, global variables must appear for all auto-created forms / data modules.
    * In the logic layer, the addition of a global variable is treated as a violation of this convention.
    * Recommended solution: **Singleton** (replacing global variables with Singleton).    

## Bibliography

* Clean Code
* MVC Architecture
* Hungarian notation
* Camel Case
* Internal Code Reviews rules
* Singleton
* GoF patters

## TODO

[ ] Bibliography links with sources

[ ] Build namespace structure