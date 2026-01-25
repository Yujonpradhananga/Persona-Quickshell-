import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Io
import QtQuick.Effects
import "Vitreus/be/effects" as Effects
import "Vitreus/be/glass" as GlassEffect

Scope {
    id: root
    
    Colors { id: colors }
    
    // Shared state for IPC toggling
    property bool forcedOpen: false

    IpcHandler {
        target: "searchapp"
        function toggle() {
             root.forcedOpen = !root.forcedOpen
        }
        function open() {
             root.forcedOpen = true
        }
        function close() {
             root.forcedOpen = false
        }
    }

    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            id: window
            property var modelData
            screen: modelData
            
            visible: root.forcedOpen 

            anchors {
                top: true
                left: true
                bottom: true
            }

            implicitWidth: contentItem.width + 20
            
            color: "transparent" 
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "searchapp"
            WlrLayershell.keyboardFocus: contentItem.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            Timer {
                id: focusTimer
                interval: 50
                repeat: false
                onTriggered: {
                    if (window.visible) {
                        search.forceActiveFocus()
                        carousel.currentIndex = 0
                    }
                }
            }

            Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }

            Item {
                id: contentItem
                
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 50

                width: 300 + searchContainer.implicitWidth
                height: 900

                onVisibleChanged: {
                    if (visible) {
                        search.text = ""
                        focusTimer.restart()
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 10

                    // Carousel container
                    Item {
                        id: carousel
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.leftMargin: -90
                        
                        property int currentIndex: 0
                        property real arcRadius: 150
                        property real arcAngleSpan: 100
                        
                        // Filter apps based on search
                        property var filteredApps: {
                            const stxt = search.text.toLowerCase();
                            if (stxt === "") {
                                return DesktopEntries.applications.values;
                            }
                            
                            return DesktopEntries.applications.values.filter(app => {
                                const ntxt = app.name.toLowerCase();
                                let ni = 0;
                                for (let si = 0; si < stxt.length; ++si) {
                                    const sc = stxt[si];
                                    while (ni < ntxt.length) {
                                        if (ntxt[ni++] == sc) break;
                                        if (ni == ntxt.length) return false;
                                    }
                                }
                                return true;
                            });
                        }
// Glass arc background
// Glass arc background
Rectangle {
    id: glassArc
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: -carousel.arcRadius * 0.85
    width: (carousel.arcRadius + 50) * 2
    height: (carousel.arcRadius + 50) * 2
    radius: carousel.arcRadius + 30
    z: -1
    
    color: Qt.rgba(15/255, 15/255, 15/255, 0.4)
}
                        // Background arc


                        // Mouse wheel handler
                        MouseArea {
                            anchors.fill: parent
                            propagateComposedEvents: true
                            hoverEnabled: true
                            
                            onWheel: wheel => {
                                if (wheel.angleDelta.y > 0) {
                                    carousel.currentIndex = Math.max(0, carousel.currentIndex - 1)
                                } else {
                                    carousel.currentIndex = Math.min(carousel.filteredApps.length - 1, carousel.currentIndex + 1)
                                }
                                wheel.accepted = true
                            }
                        }

                        // App icons on arc
                        Repeater {
                            model: carousel.filteredApps
                            
                            Item {
                                id: appDelegate
                                
                                required property var modelData
                                required property int index
                                
                                property int relativePos: index - carousel.currentIndex
                                visible: Math.abs(relativePos) <= 1
                                
                                property real angle: relativePos * carousel.arcAngleSpan
                                property real angleRad: angle * Math.PI / 180
                                
                                x: 120 - (1 - Math.cos(angleRad)) * carousel.arcRadius * 0.3
                                y: carousel.height / 2 + Math.sin(angleRad) * carousel.arcRadius - 45
                                
                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                
                                width: 80
                                height: 80
                                
                                property bool isHovered: false
                                property bool isCenter: relativePos === 0
                                property real baseScale: isCenter ? 1.3 : 0.85
                                property real hoverScale: isHovered ? 1.15 : 1.0

                                // Drop shadow
                                Rectangle {
                                    id: dropShadow
                                    visible: appDelegate.isCenter || appDelegate.isHovered
                                    anchors.centerIn: parent
                                    width: 100
                                    height: 100
                                    radius: 35
                                    color: "transparent"
                                    z: 0
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        radius: 40
                                        color: "#20000000"
                                        z: -3
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        radius: 38
                                        color: "#30000000"
                                        z: -2
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: -2
                                        radius: 36
                                        color: "#40000000"
                                        z: -1
                                    }
                                    
                                    transform: Scale {
                                        origin.x: dropShadow.width / 2
                                        origin.y: dropShadow.height / 2
                                        xScale: appDelegate.baseScale * appDelegate.hoverScale
                                        yScale: appDelegate.baseScale * appDelegate.hoverScale
                                        
                                        Behavior on xScale { NumberAnimation { duration: 150 } }
                                        Behavior on yScale { NumberAnimation { duration: 150 } }
                                    }
                                    
                                    rotation: appDelegate.isCenter ? +5 : appDelegate.angle * 1.5
                                    Behavior on rotation { NumberAnimation { duration: 200 } }
                                }
                                
                                // App button
                                Rectangle {
                                    id: appButton
                                    anchors.centerIn: parent
                                    width: 90
                                    height: 90
                                    color: colors.color2
                                    radius: 30
                                    opacity: appDelegate.isCenter ? 1.0 : 0.8
                                    z: 1
                                    
                                    transform: Scale {
                                        origin.x: appButton.width / 2
                                        origin.y: appButton.height / 2
                                        xScale: appDelegate.baseScale * appDelegate.hoverScale
                                        yScale: appDelegate.baseScale * appDelegate.hoverScale
                                        
                                        Behavior on xScale { NumberAnimation { duration: 150 } }
                                        Behavior on yScale { NumberAnimation { duration: 150 } }
                                    }
                                    
                                    rotation: appDelegate.isCenter ? +5 : appDelegate.angle * 1.5
                                    Behavior on rotation { NumberAnimation { duration: 200 } }
                                    
                                    // Fallback background
                                    Rectangle {
                                        id: fallbackBg
                                        anchors.fill: parent
                                        radius: 25
                                        visible: appIcon.status !== Image.Ready
                                        color: colors.color2
                                        z: 1
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: appDelegate.modelData.name ? appDelegate.modelData.name.charAt(0).toUpperCase() : "?"
                                            font.pixelSize: 24
                                            font.weight: Font.Bold
                                            color: "#ffffff"
                                        }
                                    }

                                    // App icon
                                    Image {
                                        id: appIcon
                                        anchors.centerIn: parent
                                        width: 55
                                        height: 50
                                        source: appDelegate.modelData.icon ? "image://icon/" + appDelegate.modelData.icon : ""
                                        sourceSize.width: 60
                                        sourceSize.height: 60
                                        fillMode: Image.PreserveAspectFit
                                        visible: status === Image.Ready
                                        smooth: true
                                        z: 2
                                    }
                                    
                                    MouseArea {
                                        id: appMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        
                                        property bool isClicking: false
                                        
                                        onClicked: {
                                            if (isClicking) return
                                            isClicking = true
                                            
                                            clickAnimation.start()
                                            Qt.callLater(function() {
                                                appDelegate.modelData.execute()
                                                if (root.forcedOpen) root.forcedOpen = false
                                                isClicking = false
                                            })
                                        }
                                        
                                        onEntered: {
                                            if (!isClicking) {
                                                appDelegate.isHovered = true
                                                carousel.currentIndex = appDelegate.index
                                            }
                                        }
                                        
                                        onExited: {
                                            if (!isClicking) {
                                                appDelegate.isHovered = false
                                            }
                                        }
                                    }
                                    
                                    SequentialAnimation {
                                        id: clickAnimation
                                        NumberAnimation {
                                            target: appButton
                                            property: "scale"
                                            to: 0.85
                                            duration: 100
                                            easing.type: Easing.OutQuad
                                        }
                                        NumberAnimation {
                                            target: appButton
                                            property: "scale"
                                            to: 1.0
                                            duration: 100
                                            easing.type: Easing.OutQuad
                                        }
                                    }
                                }
                                
                                // Tooltip
                                Rectangle {
                                    visible: appDelegate.isCenter
                                    color: colors.color9
                                    radius: 6
                                    width: tooltipText.width + 16
                                    height: tooltipText.height + 10
                                    z: 10
                                    rotation: -2
                                    
                                    anchors {
                                        left: parent.right
                                        leftMargin: 45
                                        verticalCenter: parent.verticalCenter
                                    }
                                    
                                    Text {
                                        id: tooltipText
                                        anchors.centerIn: parent
                                        text: appDelegate.modelData.name || ""
                                        color: "#ffffff"
                                        font.pixelSize: 14
                                    }
                                }
                            }
                        }
                    }

                    // Search box (hidden but functional)
                    Rectangle {
                        id: searchContainer
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 0
                        implicitHeight: 0
                        visible: false
                        color:"transparent"
                        border.width:3
                        radius: 3
                        border.color:colors.color3

                        RowLayout {
                            id: searchbox
                            anchors.fill: parent
                            anchors.margins: 5

                            IconImage {
                                implicitSize: parent.height
                                source: "root:icons/magnifying-glass.svg" 
                            }

                            TextInput {
                                id: search
                                Layout.fillWidth: true
                                color: "white"

                                focus: true
                                Keys.onEscapePressed: {
                                     if (root.forcedOpen) root.forcedOpen = false
                                }

                                Keys.onPressed: event => {
                                    if (event.key == Qt.Key_Left || event.key == Qt.Key_Up) {
                                        carousel.currentIndex = carousel.currentIndex == 0 ? carousel.filteredApps.length - 1 : carousel.currentIndex - 1;
                                        event.accepted = true;
                                    } else if (event.key == Qt.Key_Right || event.key == Qt.Key_Down) {
                                        carousel.currentIndex = carousel.currentIndex == carousel.filteredApps.length - 1 ? 0 : carousel.currentIndex + 1;
                                        event.accepted = true;
                                    } else if (event.modifiers & Qt.ControlModifier) {
                                        if (event.key == Qt.Key_J) {
                                            carousel.currentIndex = carousel.currentIndex == carousel.filteredApps.length - 1 ? 0 : carousel.currentIndex + 1;
                                            event.accepted = true;
                                        } else if (event.key == Qt.Key_K) {
                                            carousel.currentIndex = carousel.currentIndex == 0 ? carousel.filteredApps.length - 1 : carousel.currentIndex - 1;
                                            event.accepted = true;
                                        }
                                    }
                                }

                                onAccepted: {
                                    if (carousel.filteredApps.length > 0 && carousel.currentIndex >= 0 && carousel.currentIndex < carousel.filteredApps.length) {
                                        carousel.filteredApps[carousel.currentIndex].execute();
                                        if (root.forcedOpen) root.forcedOpen = false;
                                    }
                                }

                                onTextChanged: {
                                    carousel.currentIndex = 0;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
