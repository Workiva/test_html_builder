FROM google/dart:2.13
WORKDIR /build/
ADD pubspec.yaml /build
RUN pub get
FROM scratch
