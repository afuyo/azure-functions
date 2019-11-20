# Microsoft Azure Functions Deployment 
This is a quick guide to deploy your trained models using [Microsoft Azure Functions](https://bit.ly/2MA6ozf)

This guide will upload a trained LSTM model to Azure Functions. The inference will be triggered by a HTTP POST request. The result of the prediction will be returned in the HTTP Response.

## Microsoft Azure Functions
Microsoft Azure Functions is the serverless architecture offfered by Microsoft. You don't need to provision serverers or manage resources. It should also be able to handle sudden spikes of workloads. 

If new to azure functions this tutorial, [Create an HTTP triggered function in Azure](https://bit.ly/2Zs7AKs) should get you started.

For more detailed description please refer to Azure docs [Create a function on Linux using cutom image](https://bit.ly/2KRsH0T)

## Requirements
### Software
1. Linux(this guide has been tested on Ubuntu 16.04)
2. [Python 3.6](https://www.python.org/downloads/) (only Python runtime currently supported by Azure Functions)
3. [Azure Functions Core Tools version 2.x](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local#v2)
4. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
5. Docker
6. [Anaconda](https://www.anaconda.com/distribution/)

### Accounts
1. [Docker Hub Account](https://hub.docker.com/)

## Create The Local Function App Project
### Configure and Activate Anaconda Python Environment
```
conda config --set ssl_verify /usr/local/share/ca-certificates/zscaler.crt
source ~/.bashrc
conda create -n py36Env python=3.6
conda activate py36Env

```
### Setup Project Directory
```
func init <PROJECT_DIR> --docker
cd <PROJECT_DIR>
```
When prompted:
`Select a worker runtime:` python


### Create Function
Create a function with name using the template "Http Trigger". 

```
func new --name <FUNCTION_NAME> --template "HttpTrigger"
```

### Update Function
Modify the following file in the directory: 

#### <FUNCTION_NAME>/init.py 

```
import logging

import azure.functions as func
from keras.models import Model
from keras.layers import Input
from keras.layers import LSTM
from numpy import array
import pickle


def lstm():
    '''
    inputs1 = Input(shape=(3, 1))
    lstm1 = LSTM(1, return_sequences=True)(inputs1)
    model = Model(inputs=inputs1, outputs=lstm1)
    # define input data
    data = array([0.1, 0.2, 0.3]).reshape((1,3,1))
    # make and show prediction
    print(model.predict(data))
    '''
    data = array([0.1, 0.2, 0.3]).reshape((1,3,1))
    model = pickle.load(open("model.pkl","rb"))
    preds=model.predict(data)
    return preds

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    name = req.params.get('name')
    preds=lstm()
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get('name')

  
    if name:
        return func.HttpResponse(f"Hello {preds}!")
    else:
        return func.HttpResponse(
             "Please pass a name on the query string or in the request body",
             status_code=400
        )
```

This is where you place your inference function. In this case a simple, pretraind LSTM model. 

##### <FUNCTION_NAME>/function.json 

Update the function authorization. Replace the corresponding line in the file with the following:

```
"authLevel": "anonymous",
```

#### model.pkl 
Copy your trained model file, 'model.pkl' to .

### Test Function
Run the following command to test the function locally

```
func host start
```

This will return an output with the URL. 

```
Http Functions:

        inference_funciton: [GET,POST] http://localhost:7071/api/<FUNCTION_NAME>
```
Example: 
```
http://localhost:7071/api/inference_function?name=Alan
```
## Docker Setup

### Edit Docker image 
Before we can do anything with the docker image we need to add Zscaler SSL certifiates. 
Edit ***Dockerfile*** like this:

```
FROM mcr.microsoft.com/azure-functions/python:2.0

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true
RUN apt-get update \
&& apt-get install -y \
    build-essential \
    checkinstall \
    libreadline-gplv2-dev \
    libncursesw5-dev \
    libssl-dev \
    libsqlite3-dev \
    tk-dev \
    libgdbm-dev \
    libc6-dev \
    libbz2-dev \
    libffi-dev \
    openssl \
    curl \
    xml-twig-tools \
    git-all

COPY pip.conf /etc/pip.conf
RUN curl --fail -sk https://bootstrap.pypa.io/get-pip.py | python

RUN mkdir -p /usr/share/ca-certificates/extra /usr/lib/ssl/certs
COPY zscaler.crt /usr/share/ca-certificates/extra/zscaler.crt
COPY zscaler.crt /usr/lib/ssl/certs/zscaler.crt
COPY zscaler.crt /usr/lib/ssl/certs/zscaler.pem
RUN update-ca-certificates

COPY . /home/site/wwwroot

RUN cd /home/site/wwwroot && \
    pip install -r requirements.txt

```

### Build Docker image

The following command will run the Docker image locally on your machine:

```
docker build --tag <DOCKER_HUB_ID>/<DOCKER_IMAGE_NAME>:<TAG> .
```

### Test Docker image

The following will run the Docker image on your local machine for testing:

```
docker run -p 8080:80 -it <DOCKER_HUB_ID>/<DOCKER_IMAGE_NAME>:<TAG>
```

Your function in the Docker image is now running at the URL 'localhost:8080/api/<FUNCTION_NAME>'. You can now run tests with the new URL.  

### Push Docker Image to Docker Hub
Use the following commant to log in to Docker from command prompt.

```
docker login --username <DOCKER_HUB_ID>
```

You can now push the Docker image to Docker Hub:

```
docker push <DOCKER_HUB_ID>/<DOCKER_IMAGE_NAME>:<TAG>
```

## Azure Setup 

### Setup Azure Resources
You will need Resource Group, Storage Account adn Linux App Service Plan. Assuming thesea are in place you can go on and publish your app to Azure.

#### Login to Azure 

Login to Microsoft Azure with Azure CLI:

```
az login
```
#### Create the App & Deploy the Docker image from Docker Hub 

You can run the following command to deploy your Azure Function:
```
az functionapp create -g <RESOURCE_GROUP> \ 
 -p <APP_PLAN_NAME> \
 -n <FUNCTION_APP> \
 -s <STORAGE_ACCOUNT> \
 -i <DOCKER_HUB_ID>/<DOCKER_IMAGE_NAME>:<TAG> \
 --subscription "4639bceb-3ade-4111-880d-59690ee204d1"
```

The subscription is for Tryg Foundation. 

### Run your Azure Function

After a few minutes you should be able to see your app in the [Microsoft Azure Portal](https://bit.ly/2zoOLJz)

The URL of your app will be: 
```
https://<FUNCTION_APP>.azurewebsites.net/api/<FUNCTION_NAME>
```
Example:
```
https://statarm26.azurewebsites.net/api/inference_function?name==Glenn
```


## References:

[Create your first Python fucntion in Azure](https://bit.ly/2Zs7AKs)

[Create a function on Linux using a custom image](https://bit.ly/2KRsH0T)

[Azure Functions Python developer guide](https://bit.ly/342KlX5)