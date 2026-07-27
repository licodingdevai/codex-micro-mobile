import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

async function text(path: string): Promise<string> {
  return readFile(new URL(`../${path}`, import.meta.url), "utf8");
}

test("iPhone source-install docs state the public source distribution boundary", async () => {
  const [readme, install] = await Promise.all([
    text("README.md"), text("docs/IOS_INSTALL.md")
  ]);
  assert.match(readme, /Mac with Xcode/i);
  assert.match(readme, /build the bridge and iPhone app from source/i);
  assert.match(install, /source code, not through the App\s*Store/i);
  assert.match(install, /git clone https:\/\/github\.com\/licodingdevai\/codex-micro-mobile\.git/);
});

test("release docs preserve inspiration credit and independent implementation wording", async () => {
  const [readme, release] = await Promise.all([
    text("README.md"), text("docs/RELEASE_0.7.0.md")
  ]);
  for (const document of [readme, release]) {
    assert.match(document, /Shikhar \(@xikhar\)/);
    assert.match(document, /https:\/\/x\.com\/xikhar/);
    assert.match(document, /independent implementation/i);
  }
});

test("local Wi-Fi guide proves Nearby works with Tailscale off and keeps CDP private", async () => {
  const guide = await text("docs/IOS_LOCAL_WIFI.md");
  assert.match(guide, /mobile-local-config/);
  assert.match(guide, /Configure-CodexDeckMobile\.ps1 -Local/);
  assert.match(guide, /turn Tailscale off/i);
  assert.match(guide, /Keep Wi-Fi enabled/i);
  assert.match(guide, /Chrome DevTools/);
  assert.doesNotMatch(guide, /0\.0\.0\.0/);
});

test("release checksums use portable LF line endings on Windows", async () => {
  const source = await text("scripts/prepare-release.ps1");
  assert.match(source, /\$checksums -join "`n"/);
  assert.match(source, /WriteAllText/);
  assert.doesNotMatch(source, /WriteAllLines/);
});
