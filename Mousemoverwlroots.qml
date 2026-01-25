import QtQuick
import Quickshell
import Quickshell.Wayland
import "."

Scope {
    id: root
    property bool shouldShow: false
    
    // Configuration
    property int workspacesShown: 9
    property int columns: 3
    property int rows: 3
    property real workspaceWidth: 260
    property real workspaceHeight: 150
    property real workspaceSpacing: 14

    // Japanese mapping
    readonly property var jpN: ({
        1: "一", 2: "二", 3: "三", 4: "四", 5: "五",
        6: "六", 7: "七", 8: "八", 9: "九"
    })

    // Drag state
    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1
    property bool isDraggingToClose: false

    // Window list from DwlWindows
    property var windowList: DwlWindows.windowList

    onShouldShowChanged: {
        if (shouldShow) {
            DwlWindows.refreshWindowList()
            DwlService.getTagState()
        }
    }

    // Connections to update window list and service state
    Connections {
        target: DwlWindows
        function onWindowsChanged() {
            root.windowList = DwlWindows.windowList
        }
    }

    Component.onCompleted: {
        DwlService.checkMangoWC()
    }

    Variants {
        model: Quickshell.screens
        
        LazyLoader {
            id: lazyLoader
            required property var modelData
            active: root.shouldShow
            
            PanelWindow {
                id: overviewWindow
                visible: root.shouldShow
                screen: lazyLoader.modelData
                
                // Track per-monitor active tag:
                readonly property string outputName: lazyLoader.modelData.name
                property int activeTagIndex: 0

                // Update active tag for this specific monitor
                function updateActiveTag() {
                    if (!DwlService.dwlAvailable) return
                    let activeTags = DwlService.getActiveTags(overviewWindow.outputName)
                    overviewWindow.activeTagIndex = activeTags.length > 0 ? activeTags[0] : 0
                }

                Component.onCompleted: updateActiveTag()

                Connections {
                    target: DwlService
                    function onStateChanged() {
                        overviewWindow.updateActiveTag()
                    }
                }
                
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                color: "transparent"
                
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                WlrLayershell.exclusionMode: ExclusionMode.Ignore

                Rectangle {
                    anchors.fill: parent
                    color: "#CC000000"
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.shouldShow = false
                    }
                    
                    // Workspace Grid
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
                                readonly property int tagIndex: index
                                readonly property int col: index % root.columns
                                readonly property int row: Math.floor(index / root.columns)
                                
                                readonly property bool isActive: overviewWindow.activeTagIndex === tagIndex
                                
                                // Tag client count specific to THIS monitor
                                readonly property int clientCount: {
                                    if (!DwlService.dwlAvailable) return 0
                                    let state = DwlService.getOutputState(overviewWindow.outputName)
                                    if (state && state.tags && state.tags[tagIndex]) {
                                        return state.tags[tagIndex].clients || 0
                                    }
                                    return 0
                                }
                                
                                property bool isDropTarget: false

                                x: col * (root.workspaceWidth + root.workspaceSpacing)
                                y: row * (root.workspaceHeight + root.workspaceSpacing)
                                width: root.workspaceWidth
                                height: root.workspaceHeight

                                color: isDropTarget ? "#40FFFFFF" : (isActive ? "#30FFFFFF" : "#15FFFFFF")
                                radius: 12
                                border.width: isActive ? 2 : (clientCount > 0 ? 1 : 0)
                                border.color: isActive ? "#FF00FF" : (clientCount > 0 ? "#40FFFFFF" : "transparent")
                                
                                Behavior on color { ColorAnimation { duration: 200 } }

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
                                    opacity: 0.4
                                }
                                
                                property int visualWindowCount: 0 
                                
                                Text {
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 10
                                    text: workspaceRect.clientCount > 0 ? workspaceRect.clientCount + " apps" : ""
                                    color: "white"
                                    font.pixelSize: 11
                                    opacity: 0.5
                                    visible: workspaceRect.clientCount > workspaceRect.visualWindowCount
                                }

                                // Click to switch - Z: 100 to be top-most
                                // REMOVED: root.shouldShow = false (no auto-close)
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    z: 100 
                                    onClicked: {
                                        console.log("Switching " + overviewWindow.outputName + " to tag " + workspaceRect.tagIndex)
                                        DwlService.switchToTag(overviewWindow.outputName, workspaceRect.tagIndex)
                                        // Overview stays open - user can click outside to close
                                    }
                                }
                                
                                DropArea {
                                    anchors.fill: parent
                                    keys: ["window"]
                                    z: 2
                                    onEntered: {
                                        root.draggingTargetWorkspace = workspaceRect.tagIndex
                                        root.isDraggingToClose = false
                                        if (root.draggingFromWorkspace !== workspaceRect.tagIndex) workspaceRect.isDropTarget = true
                                    }
                                    onExited: {
                                        workspaceRect.isDropTarget = false
                                        if (root.draggingTargetWorkspace === workspaceRect.tagIndex) root.draggingTargetWorkspace = -1
                                    }
                                }
                            }
                        }

                        // Windows
                        Repeater {
                            model: root.windowList
                            Item {
                                id: windowItem
                                required property var modelData
                                required property int index
                                
                                // Monitor Filtering
                                readonly property bool isOnThisMonitor: modelData.monitorName === overviewWindow.outputName
                                readonly property int windowTagIndex: modelData.tagIndex
                                
                                visible: isOnThisMonitor && windowTagIndex >= 0 && windowTagIndex < root.workspacesShown
                                
                                // Logic for positioning:
                                readonly property int col: windowTagIndex % root.columns
                                readonly property int row: Math.floor(windowTagIndex / root.columns)
                                readonly property real baseX: col * (root.workspaceWidth + root.workspaceSpacing)
                                readonly property real baseY: row * (root.workspaceHeight + root.workspaceSpacing)

                                readonly property int windowsInSameTag: {
                                    let count = 0
                                    for (let i = 0; i < index; i++) {
                                        let w = root.windowList[i]
                                        if (w && w.monitorName === overviewWindow.outputName && w.tagIndex === windowTagIndex) {
                                            count++
                                        }
                                    }
                                    return count
                                }
                                
                                readonly property int gridCol: windowsInSameTag % 3
                                readonly property int gridRow: Math.floor(windowsInSameTag / 3)
                                readonly property real offsetX: 10 + gridCol * (83)
                                readonly property real offsetY: 10 + gridRow * (63)

                                readonly property real targetX: baseX + offsetX
                                readonly property real targetY: baseY + offsetY

                                property bool isDragging: false
                                
                                x: targetX; y: targetY
                                width: 75; height: 55
                                z: isDragging ? 200 : 5 // Higher than workspace click area

                                Drag.active: dragArea.drag.active
                                Drag.keys: ["window"]
                                Drag.hotSpot.x: width/2; Drag.hotSpot.y: height/2

                                Rectangle {
                                    anchors.fill: parent
                                    color: windowItem.modelData.activated ? "#FF00FF" : "#404040"
                                    radius: 8
                                    border.width: windowItem.isDragging ? 2 : 0
                                    border.color: root.isDraggingToClose ? "#FF4444" : "#FF00FF"
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: (windowItem.modelData.appId || "App").substring(0,8)
                                        color: "white"
                                        font.pixelSize: 10
                                    }
                                }

                                MouseArea {
                                    id: dragArea
                                    anchors.fill: parent
                                    drag.target: parent
                                    // Make sure we don't propagate clicks to the workspace below if we are clicking a window
                                    propagateComposedEvents: false
                                    
                                    onPressed: {
                                        windowItem.isDragging = true
                                        root.draggingFromWorkspace = windowItem.windowTagIndex
                                        // Activate on press for response, but perform full switch logic on Click
                                        if (windowItem.modelData.toplevel) windowItem.modelData.toplevel.activate()
                                    }
                                    
                                    onClicked: {
                                         // Full switch sequence to "move to where the window is"
                                         if (windowItem.modelData.toplevel) {
                                             // 1. Switch workspace view
                                             DwlService.switchToTag(overviewWindow.outputName, windowItem.windowTagIndex)
                                             // 2. Activate window (redundant but safe)
                                             windowItem.modelData.toplevel.activate()
                                             // 3. Close overview
                                             root.shouldShow = false
                                         }
                                    }

                                    onReleased: {
                                        let target = root.draggingTargetWorkspace
                                        windowItem.isDragging = false
                                        root.draggingFromWorkspace = -1
                                        root.draggingTargetWorkspace = -1
                                        
                                        if (root.isDraggingToClose) {
                                            DwlWindows.closeWindow(windowItem.modelData.toplevel)
                                        } else if (target !== -1) {
                                            DwlWindows.moveWindowToTag(windowItem.modelData.toplevel, target, overviewWindow.outputName)
                                        } else {
                                            windowItem.x = windowItem.targetX
                                            windowItem.y = windowItem.targetY
                                        }
                                        root.isDraggingToClose = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
