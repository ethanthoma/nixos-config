# Shared Google Cloud ADC

Desktop, Surface, and Atlas import `nixosModules.google-cloud`. It sets these
Home Manager session variables for `ethanthoma`:

- `GOOGLE_CLOUD_PROJECT=pi-vertex-515304`
- `GOOGLE_CLOUD_LOCATION=global`
- `GOOGLE_APPLICATION_CREDENTIALS=/run/secrets/google-adc`

`secrets/google-adc.json` contains the SOPS-encrypted ADC document. The user age
key and all three host keys can decrypt it. At system activation, sops-nix
installs the plaintext under `/run/secrets`, owned by `ethanthoma`, mode `0400`.
Only ciphertext enters Git and the Nix store. Start a new login session after
switching so applications inherit the variables. System services do not inherit
Home Manager session variables; configure their environment explicitly if needed.

## Renew the shared credential

If Google revokes the refresh token, authenticate again on one trusted device:

```console
gcloud auth application-default login
```

From the nixos-config repository root, encrypt the resulting file directly:

```console
sops --encrypt --input-type json --output-type json \
  --filename-override secrets/google-adc.json \
  "$HOME/.config/gcloud/application_default_credentials.json" \
  > secrets/google-adc.json.new &&
  mv secrets/google-adc.json.new secrets/google-adc.json
```

Check that encryption succeeded before replacing the tracked file. Commit the
ciphertext and switch each host using the updated configuration. Do not copy
plaintext into this repository or use `builtins.readFile` on it.

ADC access tokens are refreshed automatically; normal use does not require
updating SOPS. This is one shared refresh credential: revoking it affects all
three devices. SOPS distributes a frozen copy, not changes made by gcloud later.
Existing unmanaged ADC files are not deleted by this module. Once each host is
verified, they can be removed if no other workflow needs them.
