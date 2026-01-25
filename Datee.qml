import Quickshell.Wayland
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell.Hyprland
import "." as Local

ShellRoot {
    Colors { id: colors }

    Variants{
        model: Quickshell.screens

        PanelWindow {
            id: bar

            anchors {
                top: true
                right: true
                left: true
                bottom:true
            }
            required property var modelData
            screen: modelData
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            property int selectedIndex: 0

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            // Date module - positioned relative to screen width
            Column {
                anchors.right: parent.horizontalCenter
                anchors.rightMargin: parent.width * -0.42
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -465
                spacing: 20

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: dateRow.implicitWidth + 100
                    height: 50
                    Row {
                        id: dateRow
                        anchors.centerIn: parent
                        spacing: 1
                        Text {
                            text: clock.date.toLocaleString(Qt.locale("en_US"), "M/dd")
                            font.family: "Linux Biolinum"
                            font.pixelSize: 50
                            color: "white"
                            font.letterSpacing: -3
                            transform: Scale {
                                yScale: 1.3
                                xScale: 1.0
                            }
                        }
                    }
                }
            }

            // Triangle/Day module - positioned relative to screen width
            Item {
                anchors.left: parent.horizontalCenter
                anchors.leftMargin: parent.width * 0.42  // 40% from center to the right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -430

                Column {
                    id: triangleColumn
                    anchors.centerIn: parent

                    Canvas {
                        id: triangleCanvas
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 80
                        height: 80
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.fillStyle = "black"
                            ctx.beginPath()
                            ctx.moveTo(width / 2, height)      // Bottom point (tip)
                            ctx.lineTo(0, 0)                   // Top left
                            ctx.lineTo(width, 0)               // Top right
                            ctx.closePath()
                            ctx.fill()
                        }
                    }
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: dayText.implicitWidth
                        height: dayText.implicitHeight
                        Text {
                          id: dayText
                          anchors.centerIn: parent
                          anchors.verticalCenterOffset: -79
                          text: clock.date.toLocaleString(Qt.locale("en_US"), "ddd")
                          font.family: "Linux Biolinum"
                          font.bold: true
                          font.pixelSize: 25
                          color: "white"
                          font.letterSpacing: -2
                          transform: Scale {
                              yScale: 2.0
                              xScale: 1.0
                          }
                        }
                    }
                }
            }
        }
    }
}
