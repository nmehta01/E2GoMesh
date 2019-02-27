from flask import Flask
from flask_restful import Resource, Api
app = Flask(__name__)
api = Api(app)
import base64

class FetchKRB5(Resource):
    def get(self):
        with open("/kerberos-server/krb5.conf", "rb") as image_file:
              encoded_string = image_file.read()
              result =  {
                  "Krb5Conf": base64.encodestring(encoded_string).replace("\n", "")
              
              }
              return result

class FetchKCC(Resource):
    def get(self):
        with open("/kerberos-server/cache.txt", "r") as image_file:
            encoded_string = image_file.read()
            result =  {
                "KerberosCredentialCache": encoded_string.replace("\n", "")

            }
            return result
    def post(self):
        with open("/kerberos-server/cache.txt", "r") as image_file:
            encoded_string = image_file.read()
            result =  {
                "KerberosCredentialCache": encoded_string.replace("\n", "") 

            }   
            return result 
api.add_resource(FetchKCC, '/api/kerberos/fetch', methods = ['GET', 'POST', 'DELETE'])
api.add_resource(FetchKRB5, '/api/kerberos/config/fetch', methods = ['GET'])

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8080)
