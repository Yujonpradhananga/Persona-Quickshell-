import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
Scope {
    id: root
    Colors { id: colors }
    property int barCount: 30
    property int maxBarWidth: 400
    property int barHeight: 15
    property int barGap: 6
    property var cavaData: {
        var arr = []
        for (var i = 0; i < barCount; i++) arr.push(0)
        return arr
    }
    // Process to run cava
    Process {
        id: cavaProcess
        running: true
        
        command: [
            "sh", "-c", 
            "printf '[general]\\nbars=" + barCount + "\\nframerate=60\\n[output]\\nmethod=raw\\nraw_target=/dev/stdout\\ndata_format=ascii\\nascii_max_range=1000\\n[smoothing]\\nintegral=50\\ngravity=100\\n' | cava -p /dev/stdin"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var bars = data.trim().split(";")
                
                if (bars.length > 0 && bars[bars.length - 1] === "") {
                    bars.pop()
                }
                if (bars.length >= root.barCount) {
                    var vals = []
                    for (var i = 0; i < root.barCount; i++) {
                        var n = parseInt(bars[i]) / 1000.0
                        vals.push(isNaN(n) ? 0 : n)
                    }
                    root.cavaData = vals
                }
            }
        }
        
        stderr: SplitParser {
            onRead: data => console.log("Cava Debug:", data)
        }
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: window
            required property var modelData
            screen: modelData
            color: "transparent"
            
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            
            anchors {
                right: true  // Changed to right side
                top: true
                bottom: true
            }
            
            implicitWidth: root.maxBarWidth 
            // Container for the visualizer to ensure it's "planted" firmly on the right
            Rectangle {
                anchors.fill: parent
                color: "transparent" // Keep background transparent as per request
                Column {
                    anchors {
                        right: parent.right  // Anchor to right side
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: root.barGap
                    
                    Repeater {
                        model: root.barCount
                        Rectangle {
                            id: barItem
                            readonly property real magnitude: root.cavaData[index] || 0
                            
                            height: root.barHeight
                            width: 6 + (magnitude * root.maxBarWidth)
                            radius: root.barHeight / 2
                            
                            // Anchor each bar to the right so it grows leftward
                            anchors.right: parent.right
                            
                            color: colors.color4
                            
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                // Reversed gradient for right side
                                GradientStop { position: 0.0; color: "#ffffff" }
                                GradientStop { position: 0.3; color: colors.color4}
                                GradientStop { position: 1.0; color: colors.color5}
                            }
                            border.color: Qt.rgba(1, 1, 1, 0.2)
                            border.width: 1
                            opacity: 0.4 + magnitude * 0.6
                        }
                    }
                }
            }
        }
    }
}
