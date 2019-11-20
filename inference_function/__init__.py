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