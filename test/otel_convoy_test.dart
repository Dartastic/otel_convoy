// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_convoy/otel_convoy.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_convoy-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('events.create records project + endpoint + delivery', () async {
    await tracedConvoy<String>(
      operation: 'events.create',
      invoke: () async => const ConvoyCallResult(
        value: 'ok',
        result: ConvoyResult(
          projectId: 'proj_1',
          endpointId: 'ep_1',
          eventId: 'evt_1',
          eventType: 'user.created',
          projectType: 'outgoing',
          deliveryStatus: 'Success',
          retryCount: 0,
          responseStatusCode: 200,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('convoy events.create')!);
    expect(a['convoy.project.id'], 'proj_1');
    expect(a['convoy.endpoint.id'], 'ep_1');
    expect(a['convoy.project.type'], 'outgoing');
    expect(a['convoy.delivery.status'], 'Success');
  });

  test('Discarded delivery sets span error', () async {
    await tracedConvoy<String>(
      operation: 'events.replay',
      invoke: () async => const ConvoyCallResult(
        value: 'ok',
        result: ConvoyResult(
          deliveryStatus: 'Discarded',
          retryCount: 10,
        ),
      ),
    );
    expect(
      spans.findSpanByName('convoy events.replay')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutConvoyInstrumentationAsync(() async {
      await tracedConvoy<String>(
        operation: 'endpoints.create',
        invoke: () async => const ConvoyCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('convoy '), isEmpty);
  });
}
