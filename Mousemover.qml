import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: root
    property bool shouldShow: false
    Colors { id: colors }
    property int workspacesShown: 10
    property int columns: 5
    property int rows: 2
    property real workspaceWidth: 260
    property real workspaceHeight: 150
    property real workspaceSpacing: 14
    readonly property var jpN: ({
        1: "一",
        2: "二",
        3: "三",
        4: "四",
        5: "五",
        6: "六",
        7: "七",
        8: "八",
        9: "九",
        10: "十"
    })

    property var activeMonitor: Hyprland.focusedMonitor
    property real monitorWidth: activeMonitor?.width ?? 1920
    property real monitorHeight: activeMonitor?.height ?? 1080
    
    readonly property real scaleX: workspaceWidth / monitorWidth
    readonly property real scaleY: workspaceHeight / monitorHeight

    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1
    property bool isDraggingToClose: false

    property int activeWorkspaceId: Hyprland.focusedWorkspace?.id ?? 1

    property var windowList: []

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            root.activeWorkspaceId = Hyprland.focusedWorkspace?.id ?? 1
        }
        function onRawEvent(event) {
            if (event.name === "openwindow" || event.name === "closewindow" || 
                event.name === "movewindow" || event.name === "movewindowv2") {
                updateWindowList()
            }
        }
    }

    function updateWindowList() {
        getClientsProc.running = true
    }

    Process {
        id: getClientsProc
        command: ["bash", "-c", "hyprctl clients -j"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                const rawText = this.text.trim()
                
                if (rawText.length === 0 || rawText.includes("HYPRLAND_INSTANCE_SIGNATURE not set")) {
                    console.warn("Hyprland not available or not running")
                    root.windowList = []
                    return
                }
                
                try {
                    const clients = JSON.parse(rawText)
                    let windows = []
                    
                    for (let i = 0; i < clients.length; i++) {
                        let client = clients[i]
                        windows.push({
                            workspace: { id: client.workspace?.id ?? 1 },
                            address: client.address ?? "",
                            at: [client.at?.[0] ?? 0, client.at?.[1] ?? 0],
                            size: [client.size?.[0] ?? 100, client.size?.[1] ?? 100],
                            class: client.class ?? "Window",
                            floating: client.floating ?? false
                        })
                    }
                    
                    root.windowList = windows
                } catch (e) {
                    console.error("Failed to parse clients:", e)
                    root.windowList = []
                }
            }
        }
    }

    Component.onCompleted: updateWindowList()

    onShouldShowChanged: {
        if (shouldShow) {
            updateWindowList()
        }
    }

    LazyLoader {
        active: root.shouldShow
        
        PanelWindow {
            id: overviewWindow
            visible: root.shouldShow
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            
            color: "transparent"
            
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: contentItem.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            Rectangle {
                id: background
                anchors.fill: parent
                color: "#CC000000"
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.shouldShow = false
                }

                Item {
                    id: workspaceContainer
                    anchors.centerIn: parent
                    width: (root.workspaceWidth + root.workspaceSpacing) * root.columns - root.workspaceSpacing
                    height: (root.workspaceHeight + root.workspaceSpacing) * root.rows - root.workspaceSpacing

                    Repeater {
                        model: root.workspacesShown

                        Rectangle {
                            id: workspaceRect
                            required property int index

                            readonly property int workspaceId: index + 1
                            readonly property int col: index % root.columns
                            readonly property int row: Math.floor(index / root.columns)
                            readonly property bool isActive: root.activeWorkspaceId === workspaceId
                            property bool isDropTarget: false

                            x: col * (root.workspaceWidth + root.workspaceSpacing)
                            y: row * (root.workspaceHeight + root.workspaceSpacing)
                            width: root.workspaceWidth
                            height: root.workspaceHeight

                            color: isActive ? colors.color5 : "#15FFFFFF"
                            radius: 12
                            border.width: isActive ? 2 : 0
                            border.color: isActive ? colors.color3 : "transparent"
                            clip: true

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                    easing.type: Easing.OutQuad
                                }
                            }

                            Behavior on border.width {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: root.jpN[parent.workspaceId] ?? parent.workspaceId
                                color: "white"
                                font.pixelSize: 36
                                font.weight: Font.DemiBold
                                opacity: 0.15
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 10
                                text: parent.workspaceId
                                color: "white"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                opacity: 0.4
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: "transparent"
                                border.width: workspaceRect.isDropTarget ? 3 : 0
                                border.color:colors.color3 
                                opacity: 0.8
                                visible: workspaceRect.isDropTarget

                                Behavior on border.width {
                                    NumberAnimation { duration: 150 }
                                }
                            }

                            DropArea {
                                anchors.fill: parent
                                onEntered: {
                                    root.draggingTargetWorkspace = parent.workspaceId
                                    root.isDraggingToClose = false
                                    if (root.draggingFromWorkspace !== parent.workspaceId) {
                                        parent.isDropTarget = true
                                    }
                                }
                                onExited: {
                                    parent.isDropTarget = false
                                    if (root.draggingTargetWorkspace === parent.workspaceId) {
                                        root.draggingTargetWorkspace = -1
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Hyprland.dispatch(`workspace ${parent.workspaceId}`)
                                }
                            }
                        }
                    }

                    Repeater {
                        model: root.windowList

                        Item {
                            id: windowItem
                            required property var modelData
                            required property int index

                            readonly property int workspaceId: modelData.workspace?.id ?? 1
                            readonly property int workspaceIndex: workspaceId - 1
                            readonly property bool isVisible: workspaceIndex >= 0 && workspaceIndex < root.workspacesShown

                            visible: isVisible

                            readonly property int col: workspaceIndex % root.columns
                            readonly property int row: Math.floor(workspaceIndex / root.columns)
                            readonly property real baseX: col * (root.workspaceWidth + root.workspaceSpacing)
                            readonly property real baseY: row * (root.workspaceHeight + root.workspaceSpacing)

                            readonly property var atArray: modelData.at ?? [0, 0]
                            readonly property var sizeArray: modelData.size ?? [100, 100]

                            readonly property real windowX: atArray[0] ?? 0
                            readonly property real windowY: atArray[1] ?? 0
                            readonly property real windowWidth: sizeArray[0] ?? 100
                            readonly property real windowHeight: sizeArray[1] ?? 100

                            readonly property real scaledX: windowX * root.scaleX
                            readonly property real scaledY: windowY * root.scaleY
                            readonly property real scaledW: Math.max(20, windowWidth * root.scaleX)
                            readonly property real scaledH: Math.max(20, windowHeight * root.scaleY)

                            readonly property bool isActiveWorkspace: root.activeWorkspaceId === workspaceId
                            readonly property real borderWidth: isActiveWorkspace ? 2 : 0
                            readonly property real contentPadding: borderWidth + 4

                            readonly property real clampedW: Math.min(scaledW, root.workspaceWidth - (contentPadding * 2))
                            readonly property real clampedH: Math.min(scaledH, root.workspaceHeight - (contentPadding * 2))
                            readonly property real clampedX: Math.max(contentPadding, Math.min(scaledX + contentPadding, root.workspaceWidth - clampedW - contentPadding))
                            readonly property real clampedY: Math.max(contentPadding, Math.min(scaledY + contentPadding, root.workspaceHeight - clampedH - contentPadding))

                            readonly property real targetX: baseX + clampedX
                            readonly property real targetY: baseY + clampedY

                            readonly property string windowAddress: modelData.address ?? ""

                            property bool isDragging: false
                            property bool hovered: false

                            x: targetX
                            y: targetY
                            width: clampedW
                            height: clampedH
                            z: isDragging ? 100 : ((modelData.floating ?? false) ? 2 : 1)

                            Drag.active: dragArea.drag.active
                            Drag.hotSpot.x: width / 2
                            Drag.hotSpot.y: height / 2

                            Rectangle {
                                id: windowBackground
                                anchors.fill: parent
                                color: windowItem.hovered ? colors.color5 : colors.color1
                                radius: 8
                                border.width: windowItem.isDragging ? 2 : 0
                                border.color: root.isDraggingToClose ? "#FF4444" :colors.color5 

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                        easing.type: Easing.OutQuad
                                    }
                                }

                                Behavior on border.width {
                                    NumberAnimation { duration: 150 }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: windowItem.modelData?.class ?? "Window"
                                    color: "white"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    elide: Text.ElideMiddle
                                    width: Math.min(implicitWidth, windowItem.width - 20)
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: windowBackground.radius
                                color: root.isDraggingToClose && windowItem.isDragging ? "#FF4444" :colors.color4 
                                opacity: root.isDraggingToClose && windowItem.isDragging ? 0.15 : (windowItem.hovered && !windowItem.isDragging ? 0.12 : 0)

                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }
                            }

                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: pressed ? Qt.ClosedHandCursor : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)

                                drag.target: parent
                                drag.axis: Drag.XAndYAxis
                                drag.threshold: 4

                                property bool wasDragging: false

                                onEntered: windowItem.hovered = true
                                onExited: windowItem.hovered = false

                                onPressed: mouse => {
                                    wasDragging = false
                                    windowItem.isDragging = true
                                    root.draggingFromWorkspace = windowItem.workspaceId
                                    windowItem.Drag.hotSpot.x = mouse.x
                                    windowItem.Drag.hotSpot.y = mouse.y
                                }

                                onPositionChanged: {
                                    if (windowItem.isDragging) {
                                        wasDragging = true

                                        const globalPos = windowItem.mapToItem(workspaceContainer, width / 2, height / 2)
                                        const isOutside = globalPos.x < 0 || globalPos.x > workspaceContainer.width || globalPos.y < 0 || globalPos.y > workspaceContainer.height

                                        if (isOutside && root.draggingTargetWorkspace === -1) {
                                            root.isDraggingToClose = true
                                        } else {
                                            root.isDraggingToClose = false
                                        }
                                    }
                                }

                                onReleased: {
                                    const targetWs = root.draggingTargetWorkspace
                                    const fromWs = root.draggingFromWorkspace
                                    const shouldClose = root.isDraggingToClose
                                    const addr = windowItem.windowAddress

                                    windowItem.isDragging = false
                                    root.draggingFromWorkspace = -1
                                    root.draggingTargetWorkspace = -1
                                    root.isDraggingToClose = false

                                    if (shouldClose && wasDragging && addr) {
                                        Hyprland.dispatch(`closewindow address:${addr}`)
                                        Qt.callLater(root.updateWindowList)
                                    } else if (targetWs !== -1 && targetWs !== fromWs && wasDragging && addr) {
                                        Hyprland.dispatch(`movetoworkspacesilent ${targetWs},address:${addr}`)
                                        Qt.callLater(root.updateWindowList)
                                    } else {
                                        windowItem.x = windowItem.targetX
                                        windowItem.y = windowItem.targetY
                                    }

                                    wasDragging = false
                                }
                            }

                            Behavior on x {
                                enabled: !windowItem.isDragging
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on y {
                                enabled: !windowItem.isDragging
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on width {
                                enabled: !windowItem.isDragging
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on height {
                                enabled: !windowItem.isDragging
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
