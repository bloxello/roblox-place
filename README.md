# Bloxello Roblox Hub

Install [Rojo](https://rojo.space/) and [Wally](https://wally.run/), then run `wally install` and `rojo serve`. Enable HTTP requests in Roblox Studio for local catalog testing.

The generated Hub contains a private per-store API key used to grant entitlements after its server handles a Developer Product receipt or verifies Game Pass ownership. **Anyone with Studio edit access can extract and abuse this key.** Only give edit access to trusted collaborators, and rotate the key from Bloxello whenever access changes. Receipt IDs remain idempotent and `ProcessReceipt` returns `NotProcessedYet` when Bloxello cannot accept the receipt.

