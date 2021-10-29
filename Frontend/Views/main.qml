import QtQuick 6.1

import Qt.labs.platform 1.1
import QtQml.Models 2.1

import QtQuick.Controls 6.1
import QtQuick.Controls.Material 6.1

ApplicationWindow {
    id: root
    visible: true
    width: 640; height: 480
    minimumWidth: 640; minimumHeight: 480

    property int numOfEllipses: 0
    property int currentIndex: -1
    property int lastIndex: 0
    property var images: {}
    property var points: {}

    onHeightChanged: canvas.redraw()
    onWidthChanged: canvas.redraw()

    onCurrentIndexChanged: {
        if (root.images && root.points) {
            canvas.unloadImage(root.images[root.lastIndex]);
            let imagesLength = Object.keys(root.images).length;
            
            if (root.currentIndex >= imagesLength) root.currentIndex = imagesLength - 1
            if (root.currentIndex < 0) root.currentIndex = 0
            
            canvas.loadImage(root.images[root.currentIndex]);
            root.lastIndex = root.currentIndex;

            root.points[root.currentIndex]
        }
    }


    menuBar: MenuBar {
        Menu {
            title: qsTr("&File")

            Action { 
                text: "Open Images"
                onTriggered: {
                    fileDialog.open();
                }
            }

            Action { 
                text: "Export Labels"
                enabled: root.currentIndex != -1
                onTriggered: {
                    draw_controller.export_labels(root.images, root.points)
                }
            }
        }
    }

    Item {
        focus: true
        Keys.onPressed: {
            switch(event.key) {
                case 65:
                 root.currentIndex -= 1;
                 break;
                case 68:
                 root.currentIndex += 1;
                 break;
                case 81:
                 Qt.quit();
                 break;
                case 79:
                 fileDialog.open();
                 break;
            }
        }
    }

    FileDialog {
        id: fileDialog
        folder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
        fileMode: "OpenFiles"
        nameFilters: ["Image Files (*.jpg *.png *.bmp *.jpeg, *.tif)"]

        onAccepted: {

            root.images = {}
            root.points = {}

            let i = 0;
            fileDialog.currentFiles.forEach(element => {
                root.images[i] = element;
                root.points[i] = draw_controller.read_points(element);
                i += 1;
            });
            
            root.currentIndex = 0;
            canvas.loadImage(root.images[root.currentIndex]);
            canvas.redraw();
        }
    }

    Row {
        anchors.fill: parent

        Rectangle {                
            width: parent.width * 0.75
            height: parent.height
            color: "#333"

            Label {
                anchors {
                    fill: parent
                    margins: 150
                }
                color: "white"
                wrapMode: "Wrap"
                verticalAlignment: "AlignVCenter"
                horizontalAlignment: "AlignHCenter"
                font.pointSize: 15
                text: "OPEN IMAGES ON THE FILE MENU"
            }

            Canvas {
                id:canvas
                anchors {
                    fill: parent
                    margins: 10
                }

                property var points: []

                function clear() {
                    let ctx = getContext('2d');
                    ctx.reset();
                    canvas.points = [];
                    canvas.requestPaint();
                }

                function drawImage() {
                    let ctx = canvas.getContext('2d');

                    ctx.save()
                    ctx.drawImage(root.images[root.currentIndex], 0, 0, canvas.width, canvas.height);
                    ctx.stroke();          
                    ctx.restore()
                    canvas.requestPaint();  
                }

                function addPoint(x,y) {
                    let ctx = canvas.getContext('2d');

                    ctx.save()
                    ctx.strokeStyle = Qt.rgba(1, 0, 0, 1);
                    ctx.lineWidth = 4;

                    let dotSize = (root.width + root.height)/(320 + 240) * 3;
                    ctx.ellipse((x * canvas.width) - dotSize/2, (y * canvas.height) - dotSize/2, dotSize, dotSize);
                    ctx.stroke();          
                    ctx.restore()
                    canvas.requestPaint();  
                }

                function addEllipse(params, id) {
                    let x = params[0]
                    let y = params[1]
                    let w = 2 * params[2]
                    let h = 2 * params[3]
                    let theta = params[4]
                    var ctx = canvas.getContext('2d');
                    
                    ctx.save()
                    ctx.strokeStyle = Qt.rgba(1, 0, 0, 1);
                    ctx.lineWidth = (root.width + root.height)/(320 + 240);
                    ctx.font = `${parseInt(6 * (root.width + root.height)/(320 + 240))}px sans-serif`;
                    ctx.text(id, x, y);
                    ctx.translate(x, y)
                    ctx.rotate(theta);
                    ctx.translate(-x, -y)
                    ctx.ellipse(x - w/2, y - h/2, w, h);
                    ctx.stroke();          
                    ctx.restore()
                    canvas.requestPaint();  
                }

                function redraw() {                    
                    canvas.clear();
                    canvas.drawImage()
                    let i = 0;
                    root.numOfEllipses = 0;
                    root.points[root.currentIndex].forEach(points => {
                        draw_controller.estimate_ellipse_params(points, canvas.width, canvas.height);
                        canvas.addEllipse(draw_controller.ellipse, i);
                        root.numOfEllipses += 1
                        i += 1;
                    });
                }

                onImageLoaded: {
                    canvas.redraw();
                }

                MouseArea {
                    id:mouseArea
                    anchors.fill: parent

                    onClicked: {
                        if (root.images && root.points) {
                            canvas.points.push([mouseArea.mouseX/canvas.width, mouseArea.mouseY/canvas.height])
                            canvas.addPoint(mouseArea.mouseX/canvas.width, mouseArea.mouseY/canvas.height)
                            
                            if (canvas.points.length >= 5) {
                                draw_controller.estimate_ellipse_params(canvas.points, canvas.width, canvas.height)
                                root.points[root.currentIndex].push(canvas.points);
                                canvas.points = []
                                canvas.redraw()
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: sideBar
            width: parent.width - canvas.width
            height: parent.height
            color: "#333"

            ListView {
                id: ellipsesList
                anchors {
                    fill: parent
                    margins: 10
                }
                boundsBehavior: "StopAtBounds"
                spacing: 10

                model: root.numOfEllipses

                header: Item {
                            height: root.numOfEllipses > 0 ? 40 : 80; width: ellipsesList.width - 20
                            Column {
                                anchors.fill: parent
                                Rectangle {
                                    color: "#FFFEF2"
                                    height: 40; width: ellipsesList.width - 20

                                    Label {
                                        anchors.centerIn: parent
                                        text: "Ellipsis"
                                        font {
                                            bold: true
                                            pointSize: 20
                                        }
                                    }
                                }
                                Rectangle {
                                    visible: root.numOfEllipses == 0
                                    color: "#CCC"
                                    height: 40; width: ellipsesList.width - 20

                                    Label {
                                        anchors.centerIn: parent
                                        text: "No ellipse drawn"
                                        font {
                                            pixelSize: 18
                                        }
                                    }
                                }
                            }
                    }

                delegate: Rectangle {
                    width: sideBar.width - 40
                    height: 50
                    color: "#CCC"

                    Label {
                        anchors.left: parent.left
                        height: parent.height
                        width: parent.width*0.3
                        verticalAlignment: "AlignVCenter"
                        horizontalAlignment: "AlignHCenter"
                        font.pointSize: 20
                        text: index
                    }

                    Item {
                        anchors.right: parent.right
                        height: parent.height
                        width: height

                        Label {
                            anchors.fill: parent
                            verticalAlignment: "AlignVCenter"
                            horizontalAlignment: "AlignHCenter"
                            font {
                                pointSize: 20
                                bold: true
                            }
                            color: "red"
                            text: "X"
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                root.points[root.currentIndex].splice(index, 1);
                                canvas.redraw();
                            }
                        }
                    }
                }
            }
        }
    }
}