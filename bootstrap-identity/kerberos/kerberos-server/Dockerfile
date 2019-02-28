FROM alpine
RUN apk add --no-cache krb5-server krb5
ADD docker-entrypoint.sh /
ADD generate-kcc.sh /
ADD run_stuff.sh /
VOLUME /var/lib/krb5kdc
EXPOSE 749 464 88
CMD ["/run_stuff.sh"]
