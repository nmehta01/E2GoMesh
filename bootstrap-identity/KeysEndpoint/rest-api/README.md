#Build and deploy rest-api docker container 

#Build container image

sudo docker build -t gcr.io/${PROJECT_ID}/rest-app:v83 .
Sending build context to Docker daemon  7.233MB
Step 1/11 : FROM golang:1.8-alpine
 ---> 4cb86d3661bf
Step 2/11 : ADD . /go/src/rest-api
 ---> ef73ce61a59b
Step 3/11 : ADD test.pem /go/src/test.pem
 ---> ca7c7ef6bc00
Step 4/11 : RUN apk add --update git
 ---> Running in 8be9c5f51ab4
fetch http://dl-cdn.alpinelinux.org/alpine/v3.5/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.5/community/x86_64/APKINDEX.tar.gz
(1/5) Installing libssh2 (1.7.0-r2)
(2/5) Installing libcurl (7.61.1-r1)
(3/5) Installing expat (2.2.0-r1)
(4/5) Installing pcre (8.39-r0)
(5/5) Installing git (2.11.3-r2)
Executing busybox-1.25.1-r1.trigger
OK: 24 MiB in 17 packages
Removing intermediate container 8be9c5f51ab4
 ---> e64624474364
Step 5/11 : RUN go get -d github.com/gorilla/mux
 ---> Running in cc7d35c711af
Removing intermediate container cc7d35c711af
 ---> 512c45cf6380
Step 6/11 : RUN go install rest-api
 ---> Running in 6f22c7be0945
Removing intermediate container 6f22c7be0945
 ---> 7bab6dbdc088
Step 7/11 : FROM alpine:latest
 ---> caf27325b298
Step 8/11 : COPY --from=0 /go/bin/rest-api .
 ---> Using cache
 ---> f7e74a5c64b5
Step 9/11 : COPY --from=0 /go/src/test.pem /etc/config/public/Key-rsa
 ---> c35bff9b9c5a
Step 10/11 : ENV PORT 8000
 ---> Running in 9232cdd16f80
Removing intermediate container 9232cdd16f80
 ---> c06cbfd9746c
Step 11/11 : CMD ["./rest-api"]
 ---> Running in 0016dd1fd6c3
Removing intermediate container 0016dd1fd6c3
 ---> dafa139ca8c6
Successfully built dafa139ca8c6
Successfully tagged gcr.io/e2-chase/rest-app:v83


## Push it to GCR

#sudo docker push gcr.io/${PROJECT_ID}/rest-app:v83

OUTPUT

The push refers to repository [gcr.io/e2-chase/rest-app]
e2f752abb896: Pushed 
b8c33459ac87: Layer already exists 
503e53e365f3: Layer already exists 
v83: digest: sha256:8a10f7f4a3831550e98122e1e8a6017b78093e6285741a27839da89402ab8879 size: 947


## Run the container locally

sudo docker run --rm -p 8000:8000 gcr.io/${PROJECT_ID}/rest-app:v83
