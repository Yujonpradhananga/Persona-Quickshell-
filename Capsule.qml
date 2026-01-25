import Quickshell.Wayland
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ShellRoot {
    Colors { id: colors }
    property var mpris: Mpris.players.values[0] || null
    Variants {
        model: Quickshell.screens
        PanelWindow {
          id: pmusicWindow
          anchors {
            bottom: true
            left: true
          }
          required property var modelData
          screen: modelData
          color: "transparent"
          width: 800
          height: 400
          property int initialLayer: WlrLayer.Top
          WlrLayershell.layer: initialLayer
          WlrLayershell.exclusionMode: ExclusionMode.Ignore
          WlrLayershell.namespace: "music-player-interactive"
    
    Component.onCompleted: {
        layerSwitchTimer.start()
    }
    
    Timer {
        id: layerSwitchTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            pmusicWindow.initialLayer = WlrLayer.Bottom
        }
    }

            // Background audio image
          Image {
              id: dialogueBox
              source: "assets/components/player.png"
              transformOrigin: Item.Center
              anchors.centerIn: parent
              anchors.horizontalCenterOffset: -170
              anchors.verticalCenterOffset: -15
              width: 500
              height: 500
              rotation:10
              fillMode: Image.PreserveAspectFit
          }
          
            // Media Player overlaid on the dialogue box
          Item {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -70
            anchors.verticalCenterOffset: -60
            rotation:10
            
              ColumnLayout {
                anchors.centerIn: parent
                spacing: -5
                
                  // Album Art / Icon (stays at top)
                  Rectangle {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 100
                    Layout.alignment: Qt.AlignHCenter
                    Layout.leftMargin: -10
                    color: "#0d1929"
                    radius: 15
                    Image {
                      anchors.fill: parent
                      anchors.margins: 8
                      fillMode: Image.PreserveAspectCrop
                      source: mpris ? (mpris.trackArtUrl || mpris.artUrl || "") : ""
                      visible: source !== ""
                      Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: 5
                        border.color:colors.color5
                        border.width: 3
                      }
                    }
                    // Fallback music icon
                    Text {
                      anchors.centerIn: parent
                      text: "♪"
                      font.pixelSize: 48
                      color: "#00d4ff"
                      visible: !mpris || (!mpris.trackArtUrl && !mpris.artUrl)
                    }
                  }
                  
                  // Track Info and Controls side by side
                  RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    Layout.leftMargin: -10
                    spacing: 30
                      
                      // Track Info
                      Item {
                          Layout.alignment: Qt.AlignVCenter
                          Layout.preferredWidth: 100
                          Layout.preferredHeight: 40
                          
                          Column {
                              anchors.fill: parent
                              spacing: 1
                          
                              Text {
                                  text: mpris ? (mpris.trackTitle || mpris.title || "No title") : "No Media"
                                  font.family: "Segoe UI"
                                  font.pixelSize: 16
                                  color: "black"
                                  horizontalAlignment: Text.AlignLeft
                                  elide: Text.ElideRight
                                  width: 150
                                  height: 20
                                  clip: true
                              }
                              
                              Text {
                                  text: mpris ? (mpris.trackArtist || mpris.artist || "Unknown Artist") : ""
                                  font.family: "Segoe UI"
                                  font.pixelSize: 12
                                  color: "#80d0ff"
                                  horizontalAlignment: Text.AlignLeft
                                  elide: Text.ElideRight
                                  width: 150
                                  height: 16
                                  clip: true
                                  visible: text !== ""
                              }
                          }
                      }
                      
                      // Media Controls
                      RowLayout {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.topMargin:10
                        Layout.leftMargin:-10
                          spacing: 10
                          
                          
                          // Previous Button
                          Text {
                              text: "󰼨"
                              font.pixelSize: 25
                              color: prevMouse.containsMouse ? colors.color3 : colors.color15
                              Behavior on color {
                                  ColorAnimation { duration: 150 }
                              }
                              
                              MouseArea {
                                  id: prevMouse
                                  anchors.fill: parent
                                  hoverEnabled: true
                                  cursorShape: Qt.PointingHandCursor
                                  onClicked: {
                                      if (mpris && mpris.canGoPrevious) {
                                          mpris.previous()
                                      }
                                  }
                              }
                          }
                          
                          // Play/Pause Button
                          Text {
                              text: mpris && mpris.playbackState === MprisPlaybackState.Playing ? "󰏤" : ""
                              font.pixelSize: 25
                              color: playMouse.containsMouse ? colors.color3 : colors.color15
                              
                              Behavior on color {
                                  ColorAnimation { duration: 150 }
                              }
                              
                              MouseArea {
                                  id: playMouse
                                  anchors.fill: parent
                                  hoverEnabled: true
                                  cursorShape: Qt.PointingHandCursor
                                  onClicked: {
                                      if (mpris && mpris.canTogglePlaying) {
                                          mpris.togglePlaying()
                                      }
                                  }
                              }
                          }
                          
                          // Next Button
                          Text {
                              text: "󰼧"
                              font.pixelSize: 25
                              color: nextMouse.containsMouse ? "#40c0ff" : colors.color15
                              
                              Behavior on color {
                                  ColorAnimation { duration: 150 }
                              }
                              
                              MouseArea {
                                  id: nextMouse
                                  anchors.fill: parent
                                  hoverEnabled: true
                                  cursorShape: Qt.PointingHandCursor
                                  onClicked: {
                                      if (mpris && mpris.canGoNext) {
                                          mpris.next()
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
}
