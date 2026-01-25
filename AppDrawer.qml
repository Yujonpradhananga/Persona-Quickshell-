import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    Colors { id: colors }
    Mousemover { id: mousemover }
    Mousemoverwlroots { id: mousemoverwlroots }
    P3rpause { id: p3rpause }
    StatsDetail { id: statsDetail }
    
    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            id: panel
            property var modelData
            screen: modelData
            anchors {
                left: true
                top: true
                bottom: true
            }
            
            implicitWidth: toolskiRoot.isExpanded ? 500 : (toolskiRoot.isHovered ? 300 : 10)
            
            color: "transparent"
            
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: KeyboardFocus.None

            Item {
                id: toolskiRoot
                anchors.fill: parent
                property bool isHovered: false
                property bool isExpanded: false

                Timer {
                    id: autoHideTimer
                    interval: 1000
                    running: false
                    repeat: false
                    onTriggered: {
                        if (!toolskiRoot.isExpanded) {
                            toolskiRoot.isHovered = false;
                            toolskiRoot.isExpanded = false;
                        }
                    }
                }

                // Hover detection area
                Item {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 100

                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered) {
                                toolskiRoot.isHovered = true;
                                autoHideTimer.stop();
                            } else {
                                if (!toolskiRoot.isExpanded) {
                                    autoHideTimer.restart();
                                }
                            }
                        }
                    }
                }

                // Main Circle (The Launcher)
                Item {
                    id: mainCircle
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 80
                    height: 80
                    visible: ballX > -99

                    property real ballX: toolskiRoot.isHovered ? 10 : -150
                    property real shakeOffset: 0

                    transform: [
                        Translate {
                            x: mainCircle.ballX + mainCircle.shakeOffset
                        }
                    ]

                    Behavior on ballX {
                        SpringAnimation {
                            spring: 2.5
                            damping: 0.2
                            epsilon: 0.01
                            velocity: 1500
                        }
                    }

                    SequentialAnimation {
                        id: shakeAnimation
                        running: false

                        NumberAnimation {
                            target: mainCircle
                            property: "shakeOffset"
                            to: -10
                            duration: 50
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: mainCircle
                            property: "shakeOffset"
                            to: 10
                            duration: 100
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: mainCircle
                            property: "shakeOffset"
                            to: -10
                            duration: 100
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: mainCircle
                            property: "shakeOffset"
                            to: 10
                            duration: 100
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: mainCircle
                            property: "shakeOffset"
                            to: 0
                            duration: 50
                            easing.type: Easing.InQuad
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        radius: width / 2
                        color: colors.bg
                        border.color: colors.accent
                        border.width: 2

                        scale: mainCircleHover.hovered ? 1.05 : 1.0

                        Behavior on scale {
                            SpringAnimation {
                                spring: 3.0
                                damping: 0.3
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ":3"
                        color: colors.foreground
                        font.pixelSize: 26
                        font.bold: true
                    }

                    HoverHandler {
                        id: mainCircleHover
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: {
                            if (hovered) {
                                toolskiRoot.isHovered = true;
                                autoHideTimer.stop();
                            } else {
                                if (!toolskiRoot.isExpanded) {
                                    autoHideTimer.restart();
                                }
                            }
                        }
                    }

                    TapHandler {
                        onTapped: {
                            toolskiRoot.isExpanded = !toolskiRoot.isExpanded;
                            if (toolskiRoot.isExpanded) {
                                autoHideTimer.stop();
                            } else {
                                autoHideTimer.restart();
                            }
                        }
                    }
                }

                // Blades Container
                Item {
                    id: bladesContainer
                    anchors.left: mainCircle.right
                    anchors.leftMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    width: 400
                    height: 300
                    visible: mainCircle.visible

                    Repeater {
                        model: [
                            {
                                icon: "^▽^",
                                label: "Windows",
                                action: () => { mousemover.shouldShow = true }
                            },
                            {
                                icon: "╥_╥",
                                label: "Stats",
                                action: () => { statsDetail.shouldShow = true }
                            },
                            {
                                icon: "•́︿•̀",
                                label: "Power",
                                action: () => { p3rpause.shouldShow = true }
                            }
                        ]

                        Rectangle {
                            id: blade
                            width: 120
                            height: 40
                            radius: 10
                            color: colors.color3
                            border.color: bladeHoverHandler.hovered ? colors.foreground : colors.color1
                            border.width: bladeHoverHandler.hovered ? 2 : 1
                            visible: toolskiRoot.isExpanded || targetRotation !== 0

                            transformOrigin: Item.Left
                            x: 0
                            y: bladesContainer.height / 2 - height / 2

                            property real targetRotation: toolskiRoot.isExpanded ? (index - 1) * 20 : 0
                            property real targetX: toolskiRoot.isExpanded ? 15 : 0
                            property real hoverScale: bladeHoverHandler.hovered ? 1.15 : 1.0

                            rotation: targetRotation

                            Behavior on hoverScale {
                                SpringAnimation {
                                    spring: 3.5
                                    damping: 0.3
                                }
                            }

                            transform: [
                                Translate {
                                    x: blade.targetX
                                },
                                Scale {
                                    origin.x: blade.width / 2
                                    origin.y: blade.height / 2
                                    xScale: blade.hoverScale
                                    yScale: blade.hoverScale
                                }
                            ]

                            Behavior on targetRotation {
                                SpringAnimation {
                                    spring: 2.5
                                    damping: 0.25
                                }
                            }

                            Behavior on targetX {
                                SpringAnimation {
                                    spring: 2.5
                                    damping: 0.25
                                }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 8
                                
                                Text {
                                    text: modelData.icon
                                    color: colors.foreground
                                    font.pixelSize: 14
                                }
                                
                                Text {
                                    text: modelData.label
                                    color: colors.foreground
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            HoverHandler {
                                id: bladeHoverHandler
                                cursorShape: Qt.PointingHandCursor
                                onHoveredChanged: {
                                    if (hovered) {
                                        autoHideTimer.stop();
                                    }
                                }
                            }

                            MouseArea {
                                id: bladeMouseArea
                                anchors.fill: parent
                                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                property real startX: 0
                                property real dragStartX: 0

                                onPressed: mouse => {
                                    startX = blade.x;
                                    dragStartX = mouse.x;
                                }

                                onPositionChanged: mouse => {
                                    if (pressed) {
                                        var delta = mouse.x - dragStartX;
                                        if (delta > 0) {
                                            blade.x = startX + delta;
                                        }
                                    }
                                }

                                onReleased: mouse => {
                                    var delta = mouse.x - dragStartX;
                                    if (delta > 50) {
                                        modelData.action();
                                        toolskiRoot.isExpanded = false;
                                        toolskiRoot.isHovered = false;
                                    }
                                    blade.x = Qt.binding(() => startX);
                                }
                            }

                            Behavior on x {
                                SpringAnimation {
                                    spring: 3.0
                                    damping: 0.3
                                }
                            }
                        }
                    }
                }

                // Click outside to close
                MouseArea {
                    anchors.fill: parent
                    enabled: toolskiRoot.isExpanded
                    z: -1
                    
                    onClicked: {
                        toolskiRoot.isExpanded = false;
                        autoHideTimer.restart();
                    }
                }
            }
        }
    }
}
