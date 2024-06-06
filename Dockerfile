FROM gcr.io/distroless/base-debian12
COPY phase1 ./
RUN chmod a+x ./phase1
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/phase1"]