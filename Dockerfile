FROM alpine:3.20 AS build
RUN apk add --no-cache build-base linux-headers
COPY externals/ZeroTierOne /src
COPY xnet-speed.c /src/xnet-speed.c
WORKDIR /src
RUN make clean && \
    sed -i 's/CXXFLAGS=-Wall -O2/CXXFLAGS=-Wall -O3 -march=native/' make-linux.mk && \
    sed -i 's/LDFLAGS=-pie/LDFLAGS=-pie -Wl,--allow-multiple-definition/' make-linux.mk && \
    make -j$(nproc) ZT_SSO_SUPPORTED=0 ZT_USE_MINIUPNPC=0 one && \
    strip xnet-one && \
    gcc -O2 -o xnet-speed xnet-speed.c -lpthread && strip xnet-speed

FROM alpine:3.20
RUN apk add --no-cache openjdk17-jre-headless libstdc++ libgcc tini iptables
COPY --from=build /src/xnet-one /usr/local/bin/xnet-one
COPY --from=build /src/xnet-speed /usr/local/bin/xnet-speed
RUN ln -s xnet-one /usr/local/bin/xnet-cli && \
    ln -s xnet-one /usr/local/bin/xnet-idtool
COPY portal.jar /opt/portal.jar
COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9993/tcp 9993/udp 3001/tcp
VOLUME /data
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]
