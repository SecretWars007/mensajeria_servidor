FROM dart:stable

WORKDIR /app
COPY . .

RUN dart pub get
RUN dart compile exe bin/server.dart -o bin/server

EXPOSE 1982
CMD ["./bin/server"]
