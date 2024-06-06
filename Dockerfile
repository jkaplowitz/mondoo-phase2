FROM ubuntu:22.04
COPY --chmod=755 phase1 ./
EXPOSE 8080
ENTRYPOINT ["/phase1"]