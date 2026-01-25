import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtMultimedia

Scope {
    id: root
    Colors { id: colors }
    
    // Cava properties
    property int barCount: 60
    property int maxBarWidth: 300
    property int barHeight: 15
    property int barGap: 10
    property var cavaData: new Float32Array(barCount)
    
    // Process to run cava
    Process {
        id: cavaProcess
        running: true
        
        command: [
            "sh", "-c", 
            "printf '[general]\\nbars=" + barCount + "\\nframerate=30\\n[output]\\nmethod=raw\\nraw_target=/dev/stdout\\ndata_format=ascii\\nascii_max_range=1000\\n[smoothing]\\nintegral=50\\ngravity=100\\n' | cava -p /dev/stdin"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const raw = data; // Avoid trim() allocation if possible
                if (!raw) return;
                
                const bars = raw.split(";")
                // cava output ends with a semi-colon, so the last element is empty
                const len = bars.length > 0 && bars[bars.length-1] === "" ? bars.length - 1 : bars.length;

                if (len >= root.barCount) {
                    const vals = new Float32Array(root.barCount);
                    for (let i = 0; i < root.barCount; i++) {
                        const n = +bars[i]; // Fast string-to-number conversion
                        vals[i] = isNaN(n) ? 0 : n / 1000.0;
                    }
                    root.cavaData = vals;
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
                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.namespace: "depth-wallpaper-below"
                WlrLayershell.keyboardFocus: KeyboardFocus.None
                
                anchors {
                    left: true
                    right: true
                    top: true
                    bottom: true
                }
                
                color: "black"
                
                SystemClock {
                    id: clock
                    precision: SystemClock.Minutes
                }
                // Layer 1: Video wallpaper (background)
                Video {
                    id: wallpaper
                    source: Qt.resolvedUrl("assets/wallpapers/solo_30fps.mp4")
                    
                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectCrop
                    
                    loops: MediaPlayer.Infinite
                    volume: 0
                    autoPlay: true
                    z: 0
                    enabled: false
                }
                
                Text {
                  id:timehour 
                            text: clock.date.toLocaleString(Qt.locale("en_US"), "h")
                  font.pixelSize: 300
                  font.bold: true
                  font.family: "Glirock"
                  color:colors.color9
                  z: 1
                  anchors {
                      horizontalCenter:parent.horizontalCenter 
                      horizontalCenterOffset: -parent.width * 0.15
                      bottom:parent.bottom
                      bottomMargin: parent.height * 0.650
                  }
                }

                Text {
                  id:timemin 
                  text: clock.date.toLocaleString(Qt.locale("en_US"), "mm")
                  font.pixelSize: 300
                  font.bold: true
                  font.family: "Glirock"
                  color:colors.color6
                  z: 1
                  anchors {
                      horizontalCenter:parent.horizontalCenter 
                      horizontalCenterOffset: parent.width * 0.104  // ~10.4% right of center
                      bottom:parent.bottom
                      bottomMargin: parent.height * 0.650
                  }
                }
                // Layer 2: Cava visualizer (middle)
                Item {
                  anchors.fill: parent
                  z: 1.5
                  enabled: false
                  Row {
                    anchors {
                      horizontalCenter: parent.horizontalCenter
                      bottom: parent.bottom
                      bottomMargin:550  // Adjust this to move it up/down
                    }
                    spacing: root.barGap
                    Repeater {
                      model: root.barCount
                      Rectangle {
                        id: barItem
                        readonly property real magnitude: root.cavaData[index] || 0
                        
                        width: root.barHeight
                        height: 6 + (magnitude * root.maxBarWidth)
                        radius: root.barHeight / 2
                        
                        // Anchor to bottom so it grows upward
                        anchors.bottom: parent.bottom
                        
                        color: colors.color4
                        
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "#ffffff" }  // Top (flipped)
                            GradientStop { position: 0.3; color: colors.color4}
                            GradientStop { position: 1.0; color: colors.color5}  // Bottom
                        }
                        border.color: Qt.rgba(1, 1, 1, 0.2)
                        border.width: 1
                        opacity: 0.4 + magnitude * 0.6
                      }
                    }
                  }
                }
                // Layer 2.5: Text overlay (add this new section)
            
            // Layer 3: PNG overlay (front)
            Image {
                id: personaOverlay
                source: Qt.resolvedUrl("assets/wallpapers/foreground.png")
                
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                z: 2
                enabled: false
              }

        }
    }
}
