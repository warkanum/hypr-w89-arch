#!/usr/bin/env python3
import configparser
from pathlib import Path
import sys
import argparse
import importlib.util
import os
import tempfile

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")
from PySide6.QtCore import QAbstractListModel, QModelIndex, QObject, Property, QTimer, QUrl, Qt, Signal, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView

class Model(QAbstractListModel):
    def __init__(self, names):
        super().__init__(); self.names=names
    def rowCount(self, parent=QModelIndex()): return len(self.names)
    def roleNames(self): return {Qt.UserRole+1: b'name'}
    def data(self, index, role=Qt.DisplayRole):
        if index.isValid() and role in (Qt.DisplayRole, Qt.UserRole+1): return self.names[index.row()]
    lastIndex = Property(int, lambda self: 0, constant=True)

class Sddm(QObject):
    loginFailed=Signal()
    loginSucceeded=Signal()
    hostName=Property(str, lambda self:'STARGATE', constant=True)
    canSuspend=Property(bool, lambda self:True, constant=True)
    canReboot=Property(bool, lambda self:True, constant=True)
    canPowerOff=Property(bool, lambda self:True, constant=True)
    @Slot(str,str,int)
    def login(self, user, password, session): self.loginFailed.emit()
    @Slot()
    def suspend(self): pass
    @Slot()
    def reboot(self): pass
    @Slot()
    def powerOff(self): pass

parser = argparse.ArgumentParser(description="Capture a rendered SDDM theme with a mock greeter; no login or system changes.")
parser.add_argument("theme", choices=["stargate", "stargate-universe", "atlantis", "lcars"])
parser.add_argument("--width", type=int, default=1920)
parser.add_argument("--height", type=int, default=1080)
parser.add_argument("--output", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("sddm_builder", root / "lib/sddm_theme.py")
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)
app = QGuiApplication(sys.argv)
package = tempfile.TemporaryDirectory(prefix="sddm-screenshot-")
folder = builder.assemble(args.theme, Path(package.name) / "theme")
conf = configparser.ConfigParser()
conf.read(folder / "theme.conf")
view = QQuickView()
view.setResizeMode(QQuickView.SizeRootObjectToView)
users = Model(["explorer", "commander"])
sessions = Model(["Plasma (Wayland)", "Hyprland"])
sddm = Sddm()
warnings = []
view.engine().warnings.connect(lambda errors: warnings.extend(str(error) for error in errors))
for key, value in [("config", dict(conf["General"])), ("userModel", users),
                   ("sessionModel", sessions), ("sddm", sddm)]:
    view.rootContext().setContextProperty(key, value)
view.setSource(QUrl.fromLocalFile(str(folder / "Main.qml")))
if view.status() == QQuickView.Error:
    sys.exit(1)
view.resize(args.width, args.height)
view.show()

def capture():
    output = args.output or root / "docs/screenshots/sddm" / (args.theme + ".png")
    output.parent.mkdir(parents=True, exist_ok=True)
    if warnings:
        print("\n".join(warnings), file=sys.stderr)
        app.exit(1)
    elif not view.grabWindow().save(str(output)):
        app.exit(2)
    else:
        print(output)
        app.quit()

# Allow image loading and the entrance animation to settle before capturing.
QTimer.singleShot(1800, capture)
result = app.exec()
view.setSource(QUrl())
package.cleanup()
sys.exit(result)
