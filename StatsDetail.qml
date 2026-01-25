import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property bool shouldShow: false
    
    // --- CPU Logic ---
    property var previousCpuStats: null
    property double cpuUsage: 0
    
    FileView {
        id: cpuFile
        path: "/proc/stat"
        onLoaded: {
            const cpuLine = text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }
                previousCpuStats = { total, idle }
            }
        }
    }

    // --- RAM Logic ---
    property double memUsage: 0
    property string memText: "..."
    
    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: {
            const data = text()
            const totalMatch = data.match(/MemTotal:\s+(\d+)/)
            const availMatch = data.match(/MemAvailable:\s+(\d+)/)
            
            if (totalMatch && availMatch) {
                const memoryTotal = parseInt(totalMatch[1])
                const memoryAvailable = parseInt(availMatch[1])
                const memoryUsed = memoryTotal - memoryAvailable
                memUsage = memoryUsed / memoryTotal
                
                const usedGB = (memoryUsed / 1024 / 1024).toFixed(1)
                const totalGB = (memoryTotal / 1024 / 1024).toFixed(1)
                memText = usedGB + " / " + totalGB + " GB"
            }
        }
    }

    // --- Disk Logic ---
    property double diskUsage: 0
    property string diskText: "..."
    
    Process {
        id: diskProcess
        command: ["df", "-P", "/"]
        stdout: SplitParser {
            onRead: data => {
                let lines = data.trim().split("\n")
                for (let line of lines) {
                    let parts = line.trim().split(/\s+/)
                    if (parts.length >= 6 && parts[5] === "/") {
                        let total = Number(parts[1])
                        let used = Number(parts[2])
                        if (total > 0) {
                            diskUsage = used / total
                            diskText = (used / 1024 / 1024).toFixed(1) + " / " + (total / 1024 / 1024).toFixed(1) + " GB"
                        }
                    }
                }
            }
        }
    }
    
    // Timer runs when shouldShow is true, updating all data sources
    Timer {
        interval: 1000
        running: root.shouldShow
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuFile.reload()
            memFile.reload()
            if (!diskProcess.running) diskProcess.running = true
        }
    }
    
    PanelWindow {
        id: statsWindow
        visible: root.shouldShow
        color: "transparent"
        
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Normal
        
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        
        // Overlay to close on click
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            
            MouseArea {
                anchors.fill: parent
                onClicked: root.shouldShow = false
            }
            
            // Stats Card centered
            Item {
                id: contentCard
                anchors.top:parent.top
anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: 50
                width: 420
                height: 200
                
              Image {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -140
                anchors.verticalCenterOffset: -130
                source: "assets/components/dialogue2.png"
                fillMode: Image.PreserveAspectFit
                width: 1200
                height: 1000
              }
                
                // Animation properties
                opacity: 0
                transform: Translate {
                    id: slideTransform
                    y: 100
                }
                
                states: State {
                    name: "visible"
                    when: root.shouldShow
                    PropertyChanges { target: contentCard; opacity: 1 }
                    PropertyChanges { target: slideTransform; y: 0 }
                }
                
                transitions: Transition {
                    from: "*"
                    to: "visible"
                    ParallelAnimation {
                        NumberAnimation { 
                            target: contentCard
                            property: "opacity"
                            duration: 300
                            easing.type: Easing.OutQuad 
                        }
                        NumberAnimation { 
                            target: slideTransform
                            property: "y"
                            duration: 400
                            easing.type: Easing.OutBack
                            easing.overshoot: 0.8
                        }
                    }
                }
                
                onVisibleChanged: {
                    if (!visible) {
                        slideTransform.y = 100
                        contentCard.opacity = 0
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20
                    
                    // CPU
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width
                            spacing: 8
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "CPU"
                                color: "#6c7086"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Math.round(root.cpuUsage * 100) + "%"
                                color: "#cdd6f4"
                                font.pixelSize: 24
                                font.bold: true
                            }
                        }
                    }

                    // RAM
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width
                            spacing: 8
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "RAM"
                                color: "#6c7086"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Math.round(root.memUsage * 100) + "%"
                                color: "#cdd6f4"
                                font.pixelSize: 24
                                font.bold: true
                            }
                        }
                    }

                    // Disk
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width
                            spacing: 8
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "DISK"
                                color: "#6c7086"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Math.round(root.diskUsage * 100) + "%"
                                color: "#cdd6f4"
                                font.pixelSize: 24
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }
    }
}
