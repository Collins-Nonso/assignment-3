FROM alpine:3.22
RUN apk add --no-cache bash coreutils util-linux bind-tools netcat-openbsd grep
WORKDIR /app
COPY app/app.sh /app/app.sh
RUN chmod 0755 /app/app.sh
ENTRYPOINT ["/app/app.sh"]
CMD ["help"]
