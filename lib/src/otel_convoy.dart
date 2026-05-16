// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_convoy_suppression.dart';

const _tracerName = 'dartastic_otel_libs_convoy';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class ConvoyResult {
  const ConvoyResult({
    this.projectId,
    this.endpointId,
    this.eventId,
    this.deliveryAttemptId,
    this.subscriptionId,
    this.sourceId,
    this.eventType,
    this.projectType,
    this.deliveryStatus,
    this.retryCount,
    this.responseStatusCode,
    this.responseLatencyMs,
    this.endpointDisabled,
    this.statusCode,
  });

  final String? projectId;
  final String? endpointId;
  final String? eventId;
  final String? deliveryAttemptId;
  final String? subscriptionId;
  final String? sourceId;
  final String? eventType;

  /// `outgoing` (Convoy sends to your customers) vs `incoming` (Convoy
  /// ingests webhooks for you).
  final String? projectType;

  /// `Success` / `Failure` / `Retry` / `Scheduled` / `Discarded` /
  /// `Processing`.
  final String? deliveryStatus;

  final int? retryCount;
  final int? responseStatusCode;
  final int? responseLatencyMs;
  final bool? endpointDisabled;
  final int? statusCode;
}

class ConvoyCallResult<T> {
  const ConvoyCallResult({required this.value, this.result});
  final T value;
  final ConvoyResult? result;
}

/// Wraps a Convoy API call in a CLIENT span. [operation] is one of
/// `events.create`, `events.replay`, `events.batchreplay`,
/// `deliveryattempts.list`, `endpoints.create`, `endpoints.pause`,
/// `subscriptions.create`, `sources.create`, `projects.create`.
Future<T> tracedConvoy<T>({
  required String operation,
  required Future<ConvoyCallResult<T>> Function() invoke,
}) async {
  if (convoyInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'convoy',
    'rpc.method': operation,
    'convoy.operation': operation,
  };

  final span = _tracer().startSpan(
    'convoy $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.projectId != null) {
        extras.add(OTel.attributeString(
          'convoy.project.id',
          r.result!.projectId!,
        ));
      }
      if (r.result!.endpointId != null) {
        extras.add(OTel.attributeString(
          'convoy.endpoint.id',
          r.result!.endpointId!,
        ));
      }
      if (r.result!.eventId != null) {
        extras.add(OTel.attributeString(
          'convoy.event.id',
          r.result!.eventId!,
        ));
      }
      if (r.result!.deliveryAttemptId != null) {
        extras.add(OTel.attributeString(
          'convoy.delivery_attempt.id',
          r.result!.deliveryAttemptId!,
        ));
      }
      if (r.result!.subscriptionId != null) {
        extras.add(OTel.attributeString(
          'convoy.subscription.id',
          r.result!.subscriptionId!,
        ));
      }
      if (r.result!.sourceId != null) {
        extras.add(OTel.attributeString(
          'convoy.source.id',
          r.result!.sourceId!,
        ));
      }
      if (r.result!.eventType != null) {
        extras.add(OTel.attributeString(
          'convoy.event.type',
          r.result!.eventType!,
        ));
      }
      if (r.result!.projectType != null) {
        extras.add(OTel.attributeString(
          'convoy.project.type',
          r.result!.projectType!,
        ));
      }
      if (r.result!.deliveryStatus != null) {
        extras.add(OTel.attributeString(
          'convoy.delivery.status',
          r.result!.deliveryStatus!,
        ));
        if (r.result!.deliveryStatus == 'Failure' ||
            r.result!.deliveryStatus == 'Discarded') {
          span.setStatus(
            SpanStatusCode.Error,
            'Convoy delivery ${r.result!.deliveryStatus}',
          );
        }
      }
      if (r.result!.retryCount != null) {
        extras.add(OTel.attributeInt(
          'convoy.retry.count',
          r.result!.retryCount!,
        ));
      }
      if (r.result!.responseStatusCode != null) {
        extras.add(OTel.attributeInt(
          'convoy.response.status_code',
          r.result!.responseStatusCode!,
        ));
      }
      if (r.result!.responseLatencyMs != null) {
        extras.add(OTel.attributeInt(
          'convoy.response.latency_ms',
          r.result!.responseLatencyMs!,
        ));
      }
      if (r.result!.endpointDisabled != null) {
        extras.add(OTel.attributeBool(
          'convoy.endpoint.disabled',
          r.result!.endpointDisabled!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Convoy HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
