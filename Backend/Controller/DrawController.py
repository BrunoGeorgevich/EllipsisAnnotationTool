from PySide6.QtCore import QAbstractListModel, Slot, Signal, Qt, QObject, Property
from skimage.measure import EllipseModel
from os.path import splitext, exists
import numpy as np
import json

class DrawController(QObject):
    # Constructor

    _ellipses = [] 
    _ellipse = []

    def __init__(self):
        super().__init__()

    def estimate_ellipse(self, points, canvas_width, canvas_height):
        for i in range(len(points)):
            points[i] = points[i] * (canvas_width, canvas_height)

        ell = EllipseModel()
        return ell.estimate(points), ell

    @Slot("QVariant", "QVariant")
    def export_labels(self, images, points):
        parsed_images = images.toVariant()
        parsed_points = points.toVariant()

        ellipsis = {}

        for k in parsed_points:
            ellipsis[k] = []
            for p in parsed_points[k]:
                ret, ell = self.estimate_ellipse(np.array(p), 1, 1)
                if ret:
                    xc, yc, a, b, theta = ell.params
                    ellipsis[k].append([[xc, yc], [a, b], theta])
                else:
                    ellipsis[k].append([None])
        
        for k in parsed_images:
            image_path = parsed_images[k].toString()[8:]
            annot_path = f"{splitext(image_path)[0]}.txt"
            points_path = f"{splitext(image_path)[0]}.pts"
            
            with open(annot_path, "w") as f:
                f.write(json.dumps(ellipsis[k], sort_keys=True, indent=4))
            
            with open(points_path, "w") as f:
                f.write(json.dumps(parsed_points[k], sort_keys=True, indent=4))

    @Slot("QVariant", int, int)
    def estimate_ellipse_params(self, points, canvas_width, canvas_height):        
        points = np.array(points.toVariant())
        ret, ell = self.estimate_ellipse(points, canvas_width, canvas_height)

        if ret:
            xc, yc, a, b, theta = ell.params
            self._ellipse = [xc, yc, a, b, theta]
            self._ellipses.append(self._ellipse)
        else:
            print("COULDN'T ESTIMATE THE ELLIPSE PARAMETERS")
    
    @Slot("QVariant", result=list)
    def read_points(self, image_path):
        image_path = image_path.toString()[8:]
        points_path = f"{splitext(image_path)[0]}.pts"

        points = []

        if exists(points_path):
            with open(points_path, "r") as f:
                points = json.loads(f.read())

        return points

    ellipse_changed = Signal(list)
    @Property(list, notify=ellipse_changed)
    def ellipse(self): return self._ellipse
    @ellipse.setter
    def set_ellipse(self, value): self._ellipse = value