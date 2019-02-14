from flask import Flask
from flask_restful import Resource, Api

app = Flask(__name__)
api = Api(app)

class FetchKCC(Resource):
    def get(self):
        with open("/kerberos-server/cache.txt", "rb") as image_file:
            encoded_string = image_file.read()
            return encoded_string.encode("base64")

api.add_resource(FetchKCC, '/api/kerberos/fetch')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8080)
