# Phase 3 - Observability thoughts

## Core simplifying assumption

The right tools to use are context-dependent. For example, if many programming languages are in use at the company, care should be taken that the different software stacks log in a compatible manner for ease of analysis, to the extent possible.

Therefore, for the purpose of giving concrete recommendations for this challenge, I'm making the simplifying assumption that we only have to deploy and monitor the app within the scope of the challenge, and not a larger infrastructure.

## Logging
This analysis recommends the use of cloud provider-level logging solutions like Google Cloud Logging, since for a simple app like this one, there is no benefit to paying for or setting up a separate log management pipeline.

Phrased differently, most of the value of sending logs to a service like Honeycomb in this case will already be covered by the event traces and metrics that are being sent there, enough to outweigh the cost and complexity of sending logs to Honeycomb. The full logs can be consulted separately when needed, as long as the traces and metrics are instrumented sufficiently thoroughly (see below) to easily link to those logs.

For a more complicated app, it's likely one will outgrow the cloud provider solution, and logs may need to be sent to Honeycomb or to a custom log aggregation system. Unfortunately, there is no "one-size-fits-all" solution suitable for describing here.

### App logs
<ins>Tool of choice:</ins> Go's standard `log` library, coupled with log collection from the container on down to the physical hardware (e.g. Google Cloud Logging's native support for Google Kubernetes Engine) 

<ins>Rationale:</ins> The standard `log` library is familiar to Go developers. Not only does it support free-text logging, it also supports the kind of structured logging that will enable better filtering and searching at the log platform level. It logs to standard error, which is easily supported by every common Kubernetes log collection solution.

This simple app already logs the two things that are likeliest to fail: parsing the `PORT` environment variable if one is specified and running the `net/http` web server itself. Therefore, no additional logging makes sense within the current trivial `main.go`, but that would certainly change as the codebase expands.

### GitHub logs
<ins>Tool of choice</ins>: I know of nothing pre-made to handle this, but I'd explore a solution like using [timorthi/export-workflow-logs](https://github.com/timorthi/export-workflow-logs) to get the workflow logs from GitHub Actions into Google Cloud Storage, a version of [this reference architecture](https://cloud.google.com/architecture/import-logs-from-storage-to-logging) to import those logs into Google Cloud Logging, and Google Cloud Scheduler to run this import job periodically.

## Tracing
### App events
<ins>Tool of choice</ins>: OpenTelemetry, as integrated with a chosen events collection data like Honeycomb or Datadog. For Go apps with Honeycomb, instrumenting the app via [their standard SDK for sending from Go](https://docs.honeycomb.io/send-data/go/honeycomb-distribution/) would be my starting point.

<ins>Rationale</ins>: OpenTelemetry is supported by most components one might want to use in a typical application stack, and makes it almost automatic to include common metadata like latency when emitting request handling events. For a trivial standalone app like this one, most of what one needs to do is simply to wrap the handler in the automatic instrumentation as described in Honeycomb's doc, but OpenTelemetry supports adding attributes to spans and customizing the tracers in all the ways one would want as the app and the surrounding system get more complicated.

<ins>Supply chain traceability:</ins> There are at least some tracing additions we can make, even with this small app. We should make sure the event traces reflect which Git commit or tag produced the particular app binary in question, and also the sha256 hash of that binary. This information could be made available to the app through environment variables and then [added as attributes to the spans](https://docs.honeycomb.io/send-data/go/honeycomb-distribution/#add-attributes-to-spans).

<ins>Easy log access:</ins> Another span attribute should be added to reflect the direct link to the relevant Google Cloud Logging logs for the particular container invocation, to make it easy to analyze any problems may that occur where viewing the full logs is essential.

### GitHub events
I don't know of a great standard solution for receiving workflow run events into open source (non-Honeycomb) OpenTelemetry, but I'm intrigued by this [Github Actions Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/27460) which seems to be at a preliminary stage for broad usage, but which is [apparently already in production for the user who announced it](https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/27460#issuecomment-1974759598).

In a Honeycomb-specific context, Honeycomb already maintains [a specific integration with GitHub Actions](https://www.honeycomb.io/integration/github-actions-buildevents).

## Metrics collection

Here the answer for the app and platform levels is basically analogous to the logging and tracing sections: [instrument the app using an OpenTelemetry SDK to send application metrics](https://docs.honeycomb.io/send-data/metrics/application/) to somewhere like Honeycomb, and then [deploy OpenTelemetry collector agents](https://docs.honeycomb.io/send-data/metrics/infrastructure/#installing-and-running-opentelemetry-collector-agents) to send corresponding platform-level metrics, in a separate dataset from the tracing data.

I'm honestly not sure how to collect metrics from GitHub Actions, but input would be welcome.

## Dashboarding

For the dashboarding section, the particular technology used for the dashboards is less interesting than what dashboards to display. Some possibilities, in each case with a separate line on the graph for each GitHub commit or tag (except as noted):

- Healthy pod count, and unhealthy pod count
- Crashed pods
- Successful runs of each GitHub workflow or workflow job, and unsuccessful runs of these
- Basic resource usage per pod (CPU, RAM, disk)
- Error rate (4xx and 5xx separately)
- Latency (p50, p90, p95, p99)

This would naturally evolve based on real operational experience with the app and as real complexity is added to the app.

## Notifications and alerting

As with dashboarding, the choices of what to notify and alert about and how is more interesting than the particular technology used. All of the major data analysis platforms have integrations with most of the major notification and alerting solutions. Some examples of likely relevant circumstances to alert on:

- The number of healthy pods decreases too low. (e.g. below 2 in a simple toy setup with 3 pods in a single deployment)
- The number of unhealthy pods remains nonzero for more than 95% of the last N minutes. (Suggests that either an unhealthy pod is not being replaced or that the replacements are also unhealthy)
- Error rate is increasing or above a certain minimum threshhold over the last N minutes.
- Latency is increasing or above a certain minimum threshold over the last N minutes.
- The GitHub phase1 repository cannot dispatch to the phase2 repository, or the phase2 repository cannot publish the image to GHCR.

Most of these alerts should page since they are production-impacting, but the GitHub alerts do not impact production, so they should alert via some less disruptive method like Slack or JIRA.