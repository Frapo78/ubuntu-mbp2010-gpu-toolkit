# Chromium / Nouveau notes

On the reference system Chromium running on the NVIDIA render node can trigger Nouveau `INVALID_VALUE` errors.

The important distinction is:

- Intel host Mesa acceleration is healthy.
- The problematic path is specific to Chromium/ANGLE/Nouveau combinations.
- Missing Nouveau NVA5 video firmware also disables hardware video decode.

Until Intel is the permanent desktop GPU, Chromium should be treated as a workload capable of exposing the Nouveau weakness.

The project will eventually provide a browser-safe policy rather than hiding errors with GPU clock changes or unsupported proprietary drivers.
