"""Exercise setup control flow without touching the host's preferences or apps."""
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
MOCK = r'''
import json, os, pathlib, shlex, subprocess, sys
root = pathlib.Path(os.environ["TEST_ROOT"]).resolve()
name, args = pathlib.Path(sys.argv[0]).name, sys.argv[1:]
with (root / "commands.jsonl").open("a") as f:
    f.write(json.dumps([name, *args]) + "\n")
if os.environ.get("FAIL_COMMAND") == " ".join([name, *args]):
    print("simulated command failure", file=sys.stderr)
    sys.exit(13)
if name == "uname":
    print(os.environ.get("TEST_OS", "Darwin") if args == ["-s"] else "arm64")
elif name == "sw_vers":
    print(os.environ.get("TEST_VERSION", "15.7"))
elif name == "brew":
    state_file = root / "installed.json"
    state = json.loads(state_file.read_text())
    if args == ["shellenv"]:
        print('export PATH=' + shlex.quote(str(root / "prefix/bin")) + ':' + shlex.quote(str(root / "bin")) + ':"$PATH"')
    elif args[0] == "list":
        sys.exit(0 if args[1] + ":" + args[2] in state else 1)
    elif args[0] == "install":
        state.append(args[1] + ":" + args[2].split("/")[-1])
        state_file.write_text(json.dumps(state))
    elif args[0] == "--prefix":
        print(root / "prefix" / "opt" / args[1])
elif name == "curl":
    target = root / "prefix" / "bin" / "brew"
    code = "import os; os.symlink(" + repr(str(root / "bin" / "mock")) + ", " + repr(str(target)) + ")"
    print(shlex.quote(sys.executable) + " -c " + shlex.quote(code))
elif name == "sudo":
    if args != ["-v"]:
        sys.exit(subprocess.call(args))
elif name == "php":
    if args == ["-r", "echo php_ini_loaded_file();"]:
        print(os.environ.get("TEST_INI", str(root / "php config" / "php.ini")), end="")
    else:
        values = (root / "php config/php.ini").read_text()
        sys.exit(0 if all(s in values for s in ("max_execution_time = 600", "memory_limit = 1024M", "upload_max_filesize = 512M", "post_max_size = 512M")) else 1)
elif name == "pmset":
    if args == ["-g", "batt"]:
        print("InternalBattery-0" if os.environ.get("TEST_BATTERY", "yes") == "yes" else "AC Power")
elif name == "pgrep":
    sys.exit(1)
elif name in ("cp", "sed"):
    # Only the temporary PHP configuration may reach these real file utilities.
    assert pathlib.Path(args[-1]).resolve().is_relative_to(root)
    sys.exit(subprocess.call(["/bin/cp" if name == "cp" else "/usr/bin/sed", *args]))
elif name == "mkdir":
    for p in args:
        if p != "-p":
            path = pathlib.Path(p)
            assert path.resolve().is_relative_to(root)
            path.mkdir(parents=True, exist_ok=True)
elif name not in ("defaults", "duti", "git", "chflags", "dockutil", "killall", "pwpolicy"):
    raise RuntimeError("Unexpected mocked command: " + name)
'''


class MacSetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="mac setup tests ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        mock = self.bin / "mock"
        mock.write_text("#!" + sys.executable + "\n" + MOCK)
        mock.chmod(0o755)
        for name in ("uname", "sw_vers", "brew", "curl", "sudo", "php", "pmset",
                     "pgrep", "cp", "sed", "mkdir", "defaults", "duti", "git",
                     "chflags", "dockutil", "killall", "pwpolicy"):
            (self.bin / name).symlink_to(mock)
        (self.root / "installed.json").write_text("[]")
        self.home = self.root / "home"
        for directory in ("Downloads", "Library", "Desktop"):
            (self.home / directory).mkdir(parents=True, exist_ok=True)
        (self.home / ".zprofile").write_text("# Existing zsh profile must not be sourced.\nexit 92\n")
        for directory in ("prefix/bin", "apps/VLC.app", "apps/Google Chrome.app",
                          "apps/Visual Studio Code.app", "systemapps/Mail.app",
                          "systemapps/System Settings.app", "php config"):
            (self.root / directory).mkdir(parents=True, exist_ok=True)
        self.ini = self.root / "php config" / "php.ini"
        self.original_ini = "max_execution_time = 30\nmemory_limit = 128M\nupload_max_filesize = 2M\npost_max_size = 8M\n"
        self.ini.write_text(self.original_ini)
        self.env = dict(os.environ, TEST_ROOT=str(self.root), HOME=str(self.home),
                        PATH=str(self.bin) + ":/usr/bin:/bin", SHELL="/bin/zsh")
        # Map fixed host paths into fixtures; all mutating commands are mocked.
        for script in ("1-brew-apps.sh", "2-mac-settings.sh"):
            source = (ROOT / script).read_text()
            source = source.replace("/opt/homebrew", str(self.root / "prefix"))
            source = source.replace("/usr/local", str(self.root / "intel-prefix"))
            source = source.replace("/System/Applications/", str(self.root / "systemapps") + "/")
            source = source.replace("/Applications/", str(self.root / "apps") + "/")
            (self.root / script).write_text(source)

    def run_script(self, script, **overrides):
        return subprocess.run(["/bin/bash", str(self.root / script)],
                              env=dict(self.env, **overrides), text=True,
                              capture_output=True, timeout=30)

    def commands(self):
        return [json.loads(line) for line in (self.root / "commands.jsonl").read_text().splitlines()]

    def test_apps_install_and_rerun_without_duplicate_profile_lines(self):
        first = self.run_script("1-brew-apps.sh")
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertIn(["brew", "install", "--formula", "yt-dlp"], self.commands())
        self.assertIn(["brew", "install", "--cask", "codex"], self.commands())
        self.assertIn(["brew", "install", "--cask", "handbrake-app"], self.commands())
        profile = (self.home / ".zprofile").read_text()
        second = self.run_script("1-brew-apps.sh")
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual((self.home / ".zprofile").read_text(), profile)
        subprocess.run(["/bin/zsh", "-n", str(self.home / ".zprofile")], check=True)

    def test_apps_continue_after_failure_and_exit_nonzero(self):
        result = self.run_script("1-brew-apps.sh", FAIL_COMMAND="brew install --formula yt-dlp")
        self.assertEqual(result.returncode, 1)
        self.assertIn("simulated command failure", result.stderr)
        self.assertIn("brew install --formula yt-dlp", result.stderr)
        self.assertIn(["brew", "install", "--cask", "google-chrome"], self.commands())

    def test_fresh_homebrew_authenticates_before_installer(self):
        (self.bin / "brew").unlink()
        result = self.run_script("1-brew-apps.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        commands = self.commands()
        self.assertLess(commands.index(["sudo", "-v"]), next(i for i, c in enumerate(commands) if c[0] == "curl"))

    def test_failed_installer_download_stops_before_package_installation(self):
        (self.bin / "brew").unlink()
        result = self.run_script("1-brew-apps.sh", FAIL_COMMAND="curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh")
        self.assertEqual(result.returncode, 1)
        self.assertFalse(any(c[0] == "brew" for c in self.commands()))

    def test_settings_back_up_php_and_rebuild_dock(self):
        result = self.run_script("2-mac-settings.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(["sudo", "pwpolicy", "-clearaccountpolicies"], self.commands())
        backup = self.ini.with_name("php.ini.before-macos-setup")
        self.assertEqual(backup.read_text(), self.original_ini)
        self.assertIn("memory_limit = 1024M", self.ini.read_text())
        self.assertIn(["dockutil", "--add", str(self.root / "systemapps/Mail.app"), "--no-restart"], self.commands())
        self.assertIn(["defaults", "-currentHost", "write", "com.apple.controlcenter", "BatteryShowPercentage", "-bool", "true"], self.commands())
        rerun = self.run_script("2-mac-settings.sh")
        self.assertEqual(rerun.returncode, 0, rerun.stderr)
        self.assertEqual(backup.read_text(), self.original_ini)

    def test_settings_report_failure_without_stopping_other_settings(self):
        result = self.run_script("2-mac-settings.sh", FAIL_COMMAND="defaults write com.apple.dock show-recents -bool false")
        self.assertEqual(result.returncode, 1)
        self.assertIn("simulated command failure", result.stderr)
        self.assertIn(["git", "config", "--global", "user.name", "Mustafa"], self.commands())

    def test_missing_app_preserves_dock(self):
        (self.root / "apps/Google Chrome.app").rmdir()
        result = self.run_script("2-mac-settings.sh")
        self.assertEqual(result.returncode, 1)
        self.assertFalse(any(c[0] == "dockutil" for c in self.commands()))

    def test_missing_ini_never_reaches_sed(self):
        result = self.run_script("2-mac-settings.sh", TEST_INI="")
        self.assertEqual(result.returncode, 1)
        self.assertFalse(any(c[0] == "sed" for c in self.commands()))

    def test_failed_php_backup_does_not_edit_ini(self):
        backup = self.ini.with_name("php.ini.before-macos-setup")
        result = self.run_script("2-mac-settings.sh", FAIL_COMMAND="cp " + str(self.ini) + " " + str(backup))
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.ini.read_text(), self.original_ini)
        self.assertFalse(any(c[0] == "sed" for c in self.commands()))

    def test_missing_php_directive_reports_ineffective_configuration(self):
        self.ini.write_text(self.original_ini.replace("memory_limit = 128M\n", ""))
        result = self.run_script("2-mac-settings.sh")
        self.assertEqual(result.returncode, 1)
        self.assertIn("[FAILED] php -r", result.stderr)

    @unittest.skipUnless(shutil.which("php"), "PHP is not installed")
    def test_real_php_accepts_saved_execution_time_despite_cli_override(self):
        # Use real PHP with only our temporary ini, not the host's configuration.
        php = shutil.which("php")
        (self.bin / "php").unlink()
        (self.bin / "php").symlink_to(php)
        result = self.run_script("2-mac-settings.sh", PHPRC=str(self.ini), PHP_INI_SCAN_DIR="")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("max_execution_time = 600", self.ini.read_text())

    def test_newer_desktop_macos_skips_sequoia_battery_and_pmset_write(self):
        result = self.run_script("2-mac-settings.sh", TEST_VERSION="26.3", TEST_BATTERY="no")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(any("BatteryShowPercentage" in c for c in self.commands()))
        self.assertFalse(any(c[:3] == ["sudo", "pmset", "-b"] for c in self.commands()))

    def test_unsupported_os_stops_before_changes(self):
        for script in ("1-brew-apps.sh", "2-mac-settings.sh"):
            with self.subTest(script=script):
                result = self.run_script(script, TEST_OS="Linux")
                self.assertEqual(result.returncode, 1)
        self.assertTrue(all(c[0] == "uname" for c in self.commands()))


if __name__ == "__main__":
    unittest.main()
