FROM gcr.io/distroless/base-debian12
COPY --chown=nonroot:nonroot --chmod=755 phase1 ./
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/phase1"]