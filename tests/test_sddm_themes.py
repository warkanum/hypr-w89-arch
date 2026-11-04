import configparser
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
THEMES = ("stargate", "stargate-universe", "atlantis", "lcars")
spec = importlib.util.spec_from_file_location("sddm_builder", ROOT / "lib/sddm_theme.py")
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class SddmPackageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)

    def test_all_themes_export_with_local_components_and_background(self):
        result = subprocess.run(["bash", str(ROOT / "sddm-theme.sh"), "themes"],
                                text=True, capture_output=True, check=True)
        self.assertEqual(set(result.stdout.splitlines()), set(THEMES))
        for name in THEMES:
            output = builder.assemble(name, self.directory / name)
            conf = configparser.ConfigParser()
            conf.read(output / "theme.conf")
            self.assertTrue((output / conf["General"]["background"]).is_file())
            self.assertNotIn('import "../shared"', (output / "Main.qml").read_text())
            component = "Gate.qml" if name == "stargate" else "LoginPanel.qml"
            self.assertTrue((output / component).is_file())

    def test_palette_and_external_background_overrides(self):
        image = self.directory / "my wallpaper.png"
        image.write_bytes(b"image fixture")
        output = builder.assemble("atlantis", self.directory / "export",
                                  scheme=ROOT / "assets/themes/stargate-dark.json", background=str(image))
        conf = configparser.ConfigParser()
        conf.read(output / "theme.conf")
        self.assertEqual(conf["General"]["accent"], "#9fb4c4")
        self.assertEqual((output / conf["General"]["background"]).read_bytes(), image.read_bytes())

    def test_bad_inputs_do_not_create_package(self):
        output = self.directory / "export"
        for name in ("missing", "../stargate"):
            with self.assertRaises(ValueError): builder.assemble(name, output)
            self.assertFalse(output.exists())
        with self.assertRaises(ValueError): builder.assemble("atlantis", output, background="missing.png")
        self.assertFalse(output.exists())

    def test_export_keeps_existing_directory(self):
        output = self.directory / "export"
        output.mkdir()
        marker = output / "keep"
        marker.write_text("user data")
        with self.assertRaises(ValueError): builder.assemble("atlantis", output)
        self.assertEqual(marker.read_text(), "user data")


os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")
try:
    from PySide6.QtCore import QAbstractListModel, QModelIndex, QObject, Property, Qt, Signal, Slot, QUrl, QMetaObject
    from PySide6.QtGui import QGuiApplication
    from PySide6.QtQuick import QQuickView
    from PySide6.QtTest import QTest
    QT_AVAILABLE = True
except ImportError:
    QT_AVAILABLE = False

if QT_AVAILABLE:
    class Model(QAbstractListModel):
        def rowCount(self, parent=QModelIndex()): return 1
        def roleNames(self): return {Qt.UserRole + 1: b"name"}
        def data(self, index, role=Qt.DisplayRole): return "explorer" if index.isValid() else None
        lastIndex = Property(int, lambda self: 0, constant=True)

    class Greeter(QObject):
        loginFailed = Signal()
        loginSucceeded = Signal()
        hostName = Property(str, lambda self: "TEST", constant=True)
        canSuspend = Property(bool, lambda self: True, constant=True)
        canReboot = Property(bool, lambda self: True, constant=True)
        canPowerOff = Property(bool, lambda self: True, constant=True)
        calls = 0
        @Slot(str, str, int)
        def login(self, user, password, session): self.calls += 1
        @Slot()
        def suspend(self): pass
        @Slot()
        def reboot(self): pass
        @Slot()
        def powerOff(self): pass


@unittest.skipUnless(QT_AVAILABLE, "Install pyside6 to run offscreen QML checks")
class SddmRenderTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = QGuiApplication.instance() or QGuiApplication([])

    def test_render_and_authentication_states(self):
        with tempfile.TemporaryDirectory() as temp:
            cases = [(name, True) for name in THEMES] + [(name, False) for name in THEMES if name != "stargate"]
            for name, motion in cases:
                with self.subTest(theme=name, animations=motion):
                    package = builder.assemble(name, Path(temp) / f"{name}-{motion}",
                                               animations=None if name == "stargate" else motion)
                    config = configparser.ConfigParser()
                    config.read(package / "theme.conf")
                    view, users, sessions, greeter = QQuickView(), Model(), Model(), Greeter()
                    view.setResizeMode(QQuickView.SizeRootObjectToView)
                    warnings = []
                    view.engine().warnings.connect(lambda errors: warnings.extend(str(e) for e in errors))
                    for key, value in (("config", dict(config["General"])), ("userModel", users),
                                       ("sessionModel", sessions), ("sddm", greeter)):
                        view.rootContext().setContextProperty(key, value)
                    view.setSource(QUrl.fromLocalFile(str(package / "Main.qml")))
                    self.assertNotEqual(view.status(), QQuickView.Error)
                    for width, height in ((1366, 768), (1024, 600)):
                        view.resize(width, height)
                        view.show()
                        self.app.processEvents()
                        self.assertFalse(view.grabWindow().isNull())
                    if name != "stargate":
                        phase = view.rootObject().property("ambientPhase")
                        QTest.qWait(100)
                        updated = view.rootObject().property("ambientPhase")
                        if motion:
                            self.assertNotEqual(phase, updated)
                        else:
                            self.assertEqual(phase, updated)
                        panel = view.rootObject().findChild(QObject, "loginPanel")
                        if not motion: self.assertEqual(panel.property("opacity"), 1)
                        password = panel.findChild(QObject, "passwordField")
                        password.setProperty("text", "test-only")
                        QMetaObject.invokeMethod(panel, "submit")
                        self.assertTrue(panel.property("busy"))
                        self.assertEqual(greeter.calls, 1)
                        QMetaObject.invokeMethod(panel, "submit")
                        self.assertEqual(greeter.calls, 1)
                        greeter.loginFailed.emit()
                        self.assertFalse(panel.property("busy"))
                        self.assertTrue(panel.property("rejected"))
                        self.assertFalse(panel.property("accepted"))
                        self.assertEqual(password.property("text"), "")
                        self.assertIn("ACCESS DENIED", panel.property("status"))
                        password.setProperty("text", "test-only")
                        QMetaObject.invokeMethod(panel, "submit")
                        greeter.loginSucceeded.emit()
                        self.assertTrue(panel.property("accepted"))
                        self.assertEqual(password.property("text"), "")
                        self.assertEqual(panel.property("status"), "ACCESS GRANTED")
                    self.assertFalse(warnings, warnings)
                    view.close()
                    view.setSource(QUrl())
