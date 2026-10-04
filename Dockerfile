# quark (suckless static HTTP server), static musl build, scratch image.
FROM alpine:3.20 AS build
RUN apk add --no-cache build-base git
RUN git clone git://git.suckless.org/quark /q && git -C /q checkout 5ad0df91757fbc577ffceeca633725e962da345d
WORKDIR /q
RUN make LDFLAGS=-static && strip quark
# uid 30011 = jose, so files with mode 600 stay readable after quark drops root.
RUN echo "jose:x:30011:30011::/:/bin/false" > /passwd && echo "jose:x:30011:" > /group

FROM scratch
COPY --from=build /q/quark /quark
COPY --from=build /passwd /etc/passwd
COPY --from=build /group /etc/group
# quark chroots into -d, then drops to -u/-g; the container needs CHROOT, SETUID, SETGID.
ENTRYPOINT ["/quark", "-l", "-h", "0.0.0.0", "-p", "8000", "-d", "/docs", "-u", "jose", "-g", "jose"]
