---
name: Analytics service testing patterns
description: How AnalyticsEventService tests work — uses TestableAnalyticsEventService actor wrapping real components with mock network client
type: feedback
---

AnalyticsEventService is an actor, not directly testable with protocol-based mocking of its dependencies. The existing test file uses a `TestableAnalyticsEventService` actor that mirrors the real service logic but accepts a `MockAnalyticsNetworkClient` actor instead of the real `AnalyticsNetworkClient`. Real `AnalyticsPayloadBuilder`, `AnalyticsEventBuffer`, and `AnalyticsEnvironmentProvider` are used as-is.

**Why:** The real `AnalyticsNetworkClient` hits URLSession, so the network client is the only component mocked. Buffer/builder/environment are lightweight value types or actors safe to use directly.

**How to apply:** When adding new analytics tests, continue using `TestableAnalyticsEventService` + `MockAnalyticsNetworkClient`. For environment testing, use `MockAnalyticsEnvironmentProvider` with `shouldReturnNil` flag. Both mocks and the testable service live at the bottom of `AnalyticsEventServiceTests.swift`, not in shared mock files.
