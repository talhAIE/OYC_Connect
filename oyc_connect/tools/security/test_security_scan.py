import subprocess
import tempfile
from pathlib import Path
import unittest

from scan_secrets import matches, scan


class SecurityScanTests(unittest.TestCase):
    def test_reports_only_fingerprints(self):
        key = b"os_v2_" + b"app_" + b"x" * 32
        found = matches(key, "test.sql", "test")
        self.assertEqual(len(found), 1)
        self.assertNotIn(key.decode(), repr(found))
        self.assertEqual(len(found[0]["fingerprint"]), 12)

    def test_public_identifiers_are_not_private_keys(self):
        self.assertEqual(matches(b"ONESIGNAL_APP_ID=public-id\nSTRIPE_PUBLISHABLE_KEY=pk_live_public", "env", "test"), [])

    def test_history_finds_key_after_latest_file_was_cleaned(self):
        with tempfile.TemporaryDirectory(prefix="oyc-secret-scan-") as folder:
            repo = Path(folder)
            def git(*args):
                subprocess.run(["git", "-C", folder, *args], check=True, capture_output=True)
            git("init")
            git("config", "user.email", "security-test@example.invalid")
            git("config", "user.name", "Security regression test")
            (repo / "config.sql").write_text("os_v2_" + "app_" + "z" * 32)
            git("add", "config.sql")
            git("commit", "-m", "test fixture")
            (repo / "config.sql").write_text("select 'redacted';")
            git("add", "config.sql")
            git("commit", "-m", "clean latest fixture")
            self.assertEqual(scan(repo)["findings"], [])
            found = scan(repo, history=True)["findings"]
            self.assertEqual(len(found), 1)
            self.assertTrue(found[0]["reference"].startswith("git-blob:"))

    def test_ignored_flutter_env_still_gets_checked(self):
        with tempfile.TemporaryDirectory(prefix="oyc-client-env-") as folder:
            repo = Path(folder)
            subprocess.run(["git", "init", folder], check=True, capture_output=True)
            (repo / ".gitignore").write_text("**/.env\n")
            client = repo / "oyc_connect/assets/.env"
            client.parent.mkdir(parents=True)
            client.write_text("ONESIGNAL_API_KEY=legacy-secret-value")
            self.assertTrue(any(f["kind"] == "server-field-in-client-assets" for f in scan(repo)["findings"]))


if __name__ == "__main__":
    unittest.main()
