FROM golang:1.8-alpine
ADD . /go/src/rest-api
ADD test.pem /go/src/test.pem
RUN apk add --update git
RUN apk --no-cache add curl
RUN go get -d github.com/gorilla/mux
RUN go install rest-api 

FROM alpine:latest
RUN apk --no-cache add curl
COPY --from=0 /go/bin/rest-api .
COPY --from=0 /go/src/test.pem . 
ENV PORT 8000
CMD ["./rest-api"]
