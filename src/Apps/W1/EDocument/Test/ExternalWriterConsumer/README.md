# E-Document external purchase-draft writer consumer

This is an **independent app fixture**, not part of the `E-Document Core Tests` app. Its ID is intentionally absent from E-Document Core's `internalsVisibleTo` list.

Build it against the freshly compiled E-Document Core app symbols (and the standard Business Central dependencies) to verify that an ordinary third-party app can implement `IStructuredFormatReader`, register an `E-Doc. Read into Draft` enum value, instantiate the public `E-Doc. Purchase Draft Writer`, populate the published staging tables, and compile its `PersistDraft` invocation.

This is a **compile-time contract fixture only**: the sample does not parse its input, and must not be installed as a production format reader. The regular E-Document Core tests exercise runtime persistence, replacement and cleanup.

Do not add this app to E-Document Core's `internalsVisibleTo` list: doing so would defeat the purpose of the fixture.
