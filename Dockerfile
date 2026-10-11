# quark (suckless static HTTP server), static musl build, scratch image.
FROM alpine:3.20 AS build
ARG UID=1000
ARG GID=1000
RUN apk add --no-cache build-base git
RUN git clone git://git.suckless.org/quark /q && git -C /q checkout 5ad0df91757fbc577ffceeca633725e962da345d
WORKDIR /q
RUN make LDFLAGS=-static && strip quark
# Internal user matching host UID/GID so restricted mode files stay readable after dropping root.
RUN echo "quark:x:${UID}:${GID}::/:/bin/false" > /passwd && echo "quark:x:${GID}:" > /group

FROM scratch
COPY --from=build /q/quark /quark
COPY --from=build /passwd /etc/passwd
COPY --from=build /group /etc/group
# quark chroots into -d, then drops to -u/-g; the container needs CHROOT, SETUID, SETGID.
ENTRYPOINT ["/quark", "-l", "-h", "0.0.0.0", "-p", "8000", "-d", "/docs", "-u", "quark", "-g", "quark"]
