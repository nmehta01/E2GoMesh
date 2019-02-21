FROM golang:latest 
WORKDIR /app 
COPY main.go .
RUN go build -o main . 
CMD ["/app/main"]