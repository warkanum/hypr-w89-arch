"""Exercise desktop dispatch with isolated homes and mocked session tools."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DesktopTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.bin = self.home / "bin"
        self.bin.mkdir()
        self.log = self.home / "commands"
        self.env = dict(os.environ, HOME=str(self.home),
                        XDG_CONFIG_HOME=str(self.home / "config"),
                        XDG_DATA_HOME=str(self.home / "data"),
                        XDG_STATE_HOME=str(self.home / "state"),
                        PATH=f"{self.bin}:{os.environ['PATH']}",
                        TEST_LOG=str(self.log), XDG_CURRENT_DESKTOP="KDE",
                        DBUS_SESSION_BUS_ADDRESS="test-bus",
                        HYPRLAND_INSTANCE_SIGNATURE="test-instance")

    def mock(self, name, status=0):
        path = self.bin / name
        path.write_text(f'#!/bin/bash\nprintf "%s\\n" "{name}:$*" >> "$TEST_LOG"\nexit {status}\n')
        path.chmod(0o755)

    def run_script(self, script, *args, ok=True):
        result = subprocess.run(["bash", str(ROOT / script), *args], env=self.env,
                                cwd=self.home, text=True, capture_output=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def test_discovery_and_plasma_dry_run_have_no_side_effects(self):
        result = self.run_script("install.sh", "--list-desktops")
        self.assertEqual(result.stdout.splitlines(), ["hyprland", "plasma"])
        self.mock("sudo", 99)
        result = self.run_script("install.sh", "--desktop", "plasma", "--dry-run",
                                 "--scheme", "stargate-blue", "--wallpaper",
                                 "stargate-alien-water-world")
        self.assertIn("Scheme: stargate-blue-dark", result.stdout)
        self.assertIn("plasma-desktop", result.stdout)
        self.assertNotIn("hyprland", result.stdout)
        self.assertFalse(self.log.exists())
        self.assertFalse((self.home / "Pictures").exists())

    def test_invalid_input_fails_before_writes(self):
        self.mock("plasma-apply-colorscheme")
        for args in [("--desktop", "../plasma", "--scheme", "stargate-dark"),
                     ("--desktop", "plasma", "--scheme", "missing"),
                     ("--desktop", "plasma", "--scheme", "stargate-dark",
                      "--wallpaper", "missing"), ("--desktop",)]:
            self.run_script("desktop.sh", *args, ok=False)
        self.assertFalse(self.log.exists())
        self.assertFalse((self.home / "data").exists())

    def test_plasma_palette_and_wallpaper_with_spaces(self):
        self.mock("plasma-apply-colorscheme")
        self.mock("plasma-apply-wallpaperimage")
        conf = self.home / "config"
        conf.mkdir()
        original = "[General]\nColorScheme=Old\nOther=preserved\n"
        (conf / "kdeglobals").write_text(original)
        wallpaper = self.home / "a wallpaper.png"
        wallpaper.write_bytes(b"test image")
        self.run_script("desktop.sh", "--desktop", "plasma", "--scheme",
                        "stargate-blue", "--wallpaper", str(wallpaper))
        self.assertTrue((self.home / "data/color-schemes/stargate-blue-dark.colors").is_file())
        # Generate-only must leave kdeglobals for Plasma's own activation tool.
        self.assertEqual((conf / "kdeglobals").read_text(), original)
        commands = self.log.read_text()
        self.assertIn("plasma-apply-colorscheme:stargate-blue-dark", commands)
        self.assertIn(f"plasma-apply-wallpaperimage:{wallpaper}", commands)
        self.assertNotIn("hypr", commands)

    def test_live_failure_propagates(self):
        self.mock("plasma-apply-colorscheme", 7)
        self.run_script("desktop.sh", "--desktop", "plasma", "--scheme",
                        "stargate-dark", ok=False)
        self.assertIn("plasma-apply-colorscheme", self.log.read_text())

    def test_hyprland_dispatch(self):
        self.mock("hypr-theme")
        self.mock("awww")
        self.run_script("desktop.sh", "--desktop", "hyprland", "--scheme",
                        "stargate-dark", "--wallpaper", "stargate-alien-water-world")
        commands = self.log.read_text()
        self.assertIn("hypr-theme:set stargate-dark", commands)
        self.assertIn("awww:img ", commands)
        self.assertNotIn("plasma", commands)

    def test_wallpaper_requires_correct_session_before_scheme_changes(self):
        self.mock("plasma-apply-colorscheme")
        self.mock("plasma-apply-wallpaperimage")
        self.env["XDG_CURRENT_DESKTOP"] = "Hyprland"
        self.run_script("desktop.sh", "--desktop", "plasma", "--scheme",
                        "stargate-dark", "--wallpaper", "stargate-alien-water-world", ok=False)
        self.assertFalse(self.log.exists())

    def test_wallpaper_copy_preserves_existing_files(self):
        destination = self.home / "wall papers"
        destination.mkdir()
        existing = destination / "stargate-alien-water-world.png"
        existing.write_bytes(b"user version")
        self.run_script("wallpapers.sh", "--install", str(destination))
        self.assertEqual(existing.read_bytes(), b"user version")
        self.assertTrue((destination / "stargate-alien-city-centre.png").is_file())

    def test_kde_conversion_creates_fresh_config_and_preserves_settings(self):
        command = ["python3", "-I", str(ROOT / "assets/themes/kde-colors.py"),
                   str(ROOT / "assets/themes/stargate-dark.json"), "stargate-dark"]
        subprocess.run(command, env=self.env, check=True)
        globals_file = self.home / "config/kdeglobals"
        self.assertIn("ColorScheme=stargate-dark", globals_file.read_text())
        with globals_file.open("a") as stream:
            stream.write("\n[UserSettings]\nKeep=yes\n")
        subprocess.run(command, env=self.env, check=True)
        self.assertIn("Keep=yes", globals_file.read_text())

    def test_legacy_theme_plasma_target_and_shared_catalogue(self):
        self.mock("plasma-apply-colorscheme")
        self.run_script("theme.sh", "--scheme", "stargate-dark", "--plasma")
        self.assertIn("plasma-apply-colorscheme:stargate-dark", self.log.read_text())
        self.assertIn("stargate-dark", self.run_script("theme.sh", "--list").stdout)
        self.assertIn("stargate-alien-water-world", self.run_script("sddm-theme.sh", "backgrounds").stdout)

    def test_plasma_offline_theme_install_is_independent_of_hyprland(self):
        self.env["XDG_CURRENT_DESKTOP"] = ""
        self.env["DBUS_SESSION_BUS_ADDRESS"] = ""
        self.mock("sudo", 99)
        self.mock("hypr-theme", 99)
        destination = self.home / "shared wallpapers"
        result = self.run_script("install.sh", "--desktop", "plasma", "--theme-only",
                                 "--wallpapers-dir", str(destination), "--wallpaper",
                                 "stargate-alien-water-world")
        self.assertTrue((destination / "stargate-alien-water-world.png").is_file())
        self.assertIn("ColorScheme=stargate-carbon-dark",
                      (self.home / "config/kdeglobals").read_text())
        self.assertIn("After logging into Plasma", result.stdout)
        self.assertFalse((self.home / ".config/hypr").exists())
        self.assertFalse(self.log.exists())

    def test_failed_package_install_stops_before_config_changes(self):
        self.mock("pacman")
        self.mock("sudo", 42)
        self.run_script("install.sh", "--desktop", "plasma", ok=False)
        self.assertIn("sudo:pacman -S --needed --noconfirm plasma-desktop", self.log.read_text())
        self.assertFalse((self.home / "Pictures").exists())
        self.assertFalse((self.home / "config").exists())

    def test_theme_target_failure_is_not_reported_as_success(self):
        self.mock("plasma-apply-colorscheme", 7)
        result = self.run_script("theme.sh", "--scheme", "stargate-dark", "--plasma", ok=False)
        self.assertNotIn("Done:", result.stdout)

    def test_installer_rejects_unknown_backend_before_package_commands(self):
        self.mock("sudo", 99)
        result = self.run_script("install.sh", "--desktop", "missing", ok=False)
        self.assertIn("Unknown desktop", result.stderr)
        self.assertFalse(self.log.exists())

    def test_hyprland_help_and_invalid_flags_do_not_start_installer(self):
        self.mock("sudo", 99)
        self.mock("pacman", 99)
        self.assertIn("--preset", self.run_script("install.sh", "--desktop", "hyprland", "--help").stdout)
        self.run_script("install.sh", "--desktop", "hyprland", "--dry-run", ok=False)
        self.assertFalse(self.log.exists())


if __name__ == "__main__":
    unittest.main()
