import Quickshell.Wayland
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell.Hyprland
import "." as Local
import QtQuick.Effects

ShellRoot {
    Colors { id: colors }

    Variants{
        model: Quickshell.screens
        PanelWindow {
            id: bar
            anchors {
                bottom: true
                right: true
                left: true
            }

            required property var modelData
            screen: modelData
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            property int selectedIndex: 0
            property var outputState: DwlService.getOutputState(modelData.name)

            property int activeTag: {
                if (!outputState || !outputState.tags) return 1
                for (let i = 0; i < outputState.tags.length; i++) {
                    if (outputState.tags[i].state === 1) {
                        return i + 1
                    }
                }
                return 1
            }

            property string layoutSymbol: outputState?.layout || ""

            Connections {
                target: DwlService
                function onStateChanged() {
                    bar.outputState = DwlService.getOutputState(bar.modelData.name)
                }
            }

            // Battery Monitor
            QtObject {
                id: battery
                
                property int capacity: 0
                property string status: ""
                property string icon: "󰁺"
                
                property Timer updateTimer: Timer {
                    interval: 5000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        capacityFile.reload()
                        statusFile.reload()
                    }
                }
                
                property FileView capacityFile: FileView {
                    path: "/sys/class/power_supply/BAT0/capacity"
                    onLoaded: {
                        battery.capacity = parseInt(text().trim())
                        battery.updateIcon()
                    }
                }
                
                property FileView statusFile: FileView {
                    path: "/sys/class/power_supply/BAT0/status"
                    onLoaded: {
                        battery.status = text().trim()
                        battery.updateIcon()
                    }
                }
                
                function updateIcon() {
                    var icons = ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"]
                    var index = Math.floor(capacity / 10)
                    if (index > 9) index = 9
                    
                    if (status.includes("Charging")) {
                        icon = "󰂄"
                    } else if (status.includes("Full") || status.includes("Not charging")) {
                        icon = "󰂄"
                    } else {
                        icon = icons[index]
                    }
                }
            }

            Column{
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 10
                anchors.horizontalCenterOffset: -790
                spacing: 20

                Item {
                    anchors.centerIn: parent
                    width: allContent.implicitWidth + 100
                    implicitHeight: 50

                    Canvas {
                        id: backgroundCanvas
                        anchors.fill: parent

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = "black"; 
                            ctx.beginPath();
                            ctx.moveTo(20, 0); 
                            ctx.lineTo(parent.width, 0);
                            ctx.lineTo(parent.width - 20, parent.height);
                            ctx.lineTo(0, parent.height);
                            ctx.closePath();
                            ctx.fill();
                            ctx.fillStyle = colors.color3;
                            ctx.beginPath();
                            ctx.moveTo(parent.width - 15, 0);
                            ctx.lineTo(parent.width, 0);
                            ctx.lineTo(parent.width - 20, parent.height);
                            ctx.lineTo(parent.width - 35, parent.height);
                            ctx.closePath();
                            ctx.fill();
                        }
                    }

                    Row {
                        id: allContent
                        anchors.centerIn: parent
                        spacing: 20

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: battery.icon + " " + battery.capacity + "%"
                            font.family: "Linux Biolinum"
                            font.bold: true
                            font.pixelSize: 30
                            color: "white"
                        }

                        Row {
                            id: contentRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: "Linux Biolinum"
                                font.pixelSize: 30
                                color: colors.color7
                                text: bar.activeTag
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: "Linux Biolinum"
                                font.weight: Font.Light
                                font.pixelSize: 30
                                color: colors.color7
                                text: bar.layoutSymbol
                                visible: bar.layoutSymbol !== ""
                            }
                        }
                    }
                }
            }
        }
    }
}
