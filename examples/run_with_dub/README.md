## dubtest

This is a demonstration about how one might run zug-tap tests with a library 
project.

## How to add tests

One way to do it is to create a subPackage in the project configuration file, name it "tests" and set the target as an executable:

    {
        "authors": [
            "Emil Nicolaie Perhinschi"
        ],
        "copyright": "Copyright © 2019, Emil Nicolaie Perhinschi",
        "description": "example how to run zug-tap",
        "license": "proprietary",
        "name": "dubtest",
        "targetType": "library",
        "subPackages": [
            {
                "name":"tests",
                "targetType":"executable",
                "dependencies": {
                    "zug-tap" : "*",
                    "dubtest" : { "path":"../" }
                },
                "sourcePath":"t",
                "targetName":"tests"
            }
        ]
    }

## How to run the tests 

dub -q run :tests 

