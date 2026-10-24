// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_convoy/otel_convoy.dart';

/// Traces Convoy calls with OpenTelemetry.
///
/// `otel_convoy` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Convoy call in
/// [tracedConvoy]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'convoy-example');

  // Wraps a Convoy API call in a CLIENT span.
  final convoyId = await tracedConvoy<String>(
    operation: 'events.create',
    invoke: () async {
      // Make the Convoy call here, then report what it returned.
      const id = 'convoy_8f3a2c';
      return const ConvoyCallResult(
          value: id,
          result: ConvoyResult(
              projectId: 'project_8f3a2c',
              endpointId: 'endpoint_8f3a2c',
              eventId: 'event_8f3a2c',
              deliveryAttemptId: 'deliveryattempt_8f3a2c',
              subscriptionId: 'subscription_8f3a2c',
              sourceId: 'source_8f3a2c',
              eventType: 'order.created',
              projectType: 'outgoing',
              deliveryStatus: 'Success',
              retryCount: 3,
              responseStatusCode: 201,
              responseLatencyMs: 120,
              endpointDisabled: true,
              statusCode: 201));
    },
  );
  OTelLog.info('tracedConvoy events.create returned $convoyId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutConvoyInstrumentationAsync.
  await runWithoutConvoyInstrumentationAsync(
    () => tracedConvoy<String>(
      operation: 'events.create',
      invoke: () async {
        const id = 'convoy_8f3a2c';
        return const ConvoyCallResult(
            value: id,
            result: ConvoyResult(
                projectId: 'project_8f3a2c',
                endpointId: 'endpoint_8f3a2c',
                eventId: 'event_8f3a2c',
                deliveryAttemptId: 'deliveryattempt_8f3a2c',
                subscriptionId: 'subscription_8f3a2c',
                sourceId: 'source_8f3a2c',
                eventType: 'order.created',
                projectType: 'outgoing',
                deliveryStatus: 'Success',
                retryCount: 3,
                responseStatusCode: 201,
                responseLatencyMs: 120,
                endpointDisabled: true,
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
