FROM google/dart:2.5
WORKDIR /build/
ADD pubspec.yaml /build
RUN pub get

#TODO move these to Travis CI
ADD . /build
RUN dartanalyzer .
RUN dartfmt -n --set-exit-if-changed .
RUN pub run test
#/TODO

FROM scratch
