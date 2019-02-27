FROM golang:1.8-alpine
ADD . /go/src/github.com/ishmee1/rest-api
RUN go install rest-api 

FROM alpine:latest
COPY --from=0 /go/bin/rest-api .
ENV PORT 8080
CMD ["./rest-api"]
