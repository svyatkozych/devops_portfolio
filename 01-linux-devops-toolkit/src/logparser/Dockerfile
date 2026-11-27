FROM ubuntu:24.04 AS build
RUN apt-get update \
    && apt-get install -y --no-install-recommends g++ cmake make \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY CMakeLists.txt .
COPY src ./src
RUN cmake -S . -B build -DSTATIC_BUILD=ON -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build

FROM scratch
COPY --from=build /src/build/logparser /logparser
USER 65534:65534
ENTRYPOINT ["/logparser"]
