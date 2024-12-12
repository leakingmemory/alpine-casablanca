FROM alpine:3.21 AS rundeps
RUN apk update
RUN apk add ca-certificates openssl zlib libstdc++
FROM rundeps AS builddeps
RUN apk add boost-dev websocket++ g++ cmake ninja openssl-dev zlib-dev patch
FROM builddeps AS cpprestsdk-build
WORKDIR /
ENV CASABLANCA_VERSION=2.10.19
RUN wget "https://github.com/microsoft/cpprestsdk/archive/v${CASABLANCA_VERSION}.tar.gz"
RUN tar xzvf v${CASABLANCA_VERSION}.tar.gz
ADD cpprestsdk-2.10.19-warnings.patch /cpprestsdk-2.10.19-warnings.patch
WORKDIR /cpprestsdk-${CASABLANCA_VERSION}
RUN patch -p1 < /cpprestsdk-2.10.19-warnings.patch
RUN mkdir build.release
WORKDIR /cpprestsdk-${CASABLANCA_VERSION}/build.release
RUN cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_LIBDIR=/usr/local/lib
RUN ninja
WORKDIR /cpprestsdk-${CASABLANCA_VERSION}/build.release/Release/Binaries
RUN rm -f libwebsocketsclient_test.so
RUN ./test_runner *_test.so
WORKDIR /cpprestsdk-${CASABLANCA_VERSION}/build.release
RUN ninja install

FROM rundeps AS casablanca-runtime
COPY --from=cpprestsdk-build /usr/local/lib/libcpprest*.so* /usr/local/lib/

FROM casablanca-runtime AS casablanca-dev
RUN apk add zlib-dev openssl-dev boost-dev
COPY --from=cpprestsdk-build /usr/local/include/pplx /usr/local/include/pplx
COPY --from=cpprestsdk-build /usr/local/include/cpprest /usr/local/include/cpprest
COPY --from=cpprestsdk-build /usr/local/lib/cmake/cpprestsdk /usr/local/lib/cmake/cpprestsdk


