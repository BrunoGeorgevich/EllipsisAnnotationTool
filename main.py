import sys
import os

from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QResource

from Backend.Controller.DrawController import DrawController

if __name__ == "__main__":
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"
    app = QApplication(sys.argv)
    QResource.registerResource("main.rcc")

    engine = QQmlApplicationEngine()
    ctx = engine.rootContext()

    draw_controller = DrawController()    
    ctx.setContextProperty("draw_controller", draw_controller)
    
    engine.load('qrc:/main.qml')

    sys.exit(app.exec())