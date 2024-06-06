# Observability Thoughts

The work accomplished in this challenge is just a beginning. Ensuring that any production service is truly operating in a robust manner needs a lot of observability infrastructure.

Here are initial thoughts on how to accomplish many such aspects, keeping in mind that the details of the right solution would depend heavily on the surrounding infrastructure and the real use case. Since this is isolated from any real application, the types of logs and traces I'm discussing are hypothetical based on typical web service and API endpoint needs.

## Logging

First, the application and its environment would need to be thoroughly instrumented with informative logs, as feasible for each technology, ideally with as much structure as possible. This could be done in Go via the standard `log` and/or `log/slog` packages

Logs transmitted to standard output in a container or to a filesystem log file, from the Kubernetes cluster itself,  from the cloud platform provider, or from any other source need to be collected. In Kubernetes this is commonly handled via a sidecar log collector agent, running on each node and collecting logs written to persistent disks or to container standard output. For logs from the platform provider, either the logs will be natively available (as for Google Cloud Platform logs in Google Cloud Logging) or an exporter / importer needs to be deployed (such as if one wants Google Cloud Platform logs in Amazon CloudWatch).

It's important to collect the GitHub Actions logs, both successful and failed, into the same system for holistic analysis.

## Tracing

Thorough tracing libraries such as OpenTelemetry should be woven throughout the application. It's important to know which requests in the stack are taking how much time, where errors are occurring, and which types of data are triggering errors for which users. The data should be sent to a vendor such as Honeycomb for flexibility in analysis.

Where possible, most routine request-specific event metadata should be collected in this structured event tracing and reflected in metrics, rather than logged, for easier aggregation and filtering. This could for example include user ID, billing plan type, latencies, timeouts, error codes, and to the extent the privacy policy permits, also a portion of the substantive request and response content which does not overwhelm the reasonable maximum size of each event transmitted. If there is a large volume of events, sampling may be required instead of 100% collection.

Similarly, it would be ideal if the tracing vendor supports integrating with GitHub deeply enough to send events based on, for example, the start and end of each GitHub Actions job and workflow.

## Metrics Collection

In a Kubernetes infrastructure, technologies like Prometheus or Thanos are commonly used to collect metrics, including a node-exporter for low-level metrics and libraries integrated with the application to serve up application-level metrics inside the container for Prometheus to scrape. Long-term storage for this data is expensive, as is too much cardinality with too many labels in the time series. But at the very least, it should count the requests served, labeled by type of request, error code, container, region, server version number, authentication status, billing plan, and so on. The details vary by exact application. To avoid high cardinality when labeling request latency through Prometheus, one can group latencies into buckets instead of having a separate label value for every possible latency. This would enable alerts based on increasing or excessive latencies.

Again, collecting metrics from GitHub about build times, usage of available quota, etc is important to enable proper dashboarding and alerting.

## Notifications and Alerting

There are several solutions here: PagerDuty, LinkedIn OnCall, Zalando's ZMON, and many others. Alerts can originate from whatever system is able to provide the necessary data - for example, Honeycomb can notify the alerting system based on triggers when configured thresholds are exceeded in the events they collect, and Prometheus has its own query language with AlertManager able to notify the alerting systems based on alert rules.

In general, alerts should recognize that data is noisy and human attention spans are scarce and limited. This means that it's better to look at sustained changes in the error rate over a rolling time window than a single brief burst of errors. The single brief burst can nevertheless show up in dashboards for human analysis during business hours, but it's not usefully actionable with the same level of urgency that warrants paging someone and waking them up.

Besides request error rates, it's worth tracking failures in builds and deploys, latencies, and similar matters as already discussed above.

Ideally, notifications should be sent to on-call engineers in a time zone where they are unlikely to be asleep, but this is only possible if the on-call engineers are geographically distributed in a follow-the-sun manner.