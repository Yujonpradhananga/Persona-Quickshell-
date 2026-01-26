import Quickshell.Wayland
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell.Hyprland


ShellRoot{
  Colors { id: colors } 
  StatsDetail {
        id: statsDetail
    }
  Variants{
    model: Quickshell.screens
    PanelWindow
    {
      id: window
      anchors {
          top: true
          left: true
          right: true
          bottom: true
      }
      required property var modelData
      screen: modelData
      color: "transparent"
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      property real middleOuterSlant: 0
      property real middleInnerSlant: 0
      property bool middleHovered: false
      

      SequentialAnimation {
          loops: Animation.Infinite
          running: window.middleHovered
          
          NumberAnimation {
              target: window
              property: "middleOuterSlant"
              from: 0
              to: 2
              duration: 1800
              easing.type: Easing.InOutSine
          }
          NumberAnimation {
              target: window
              property: "middleOuterSlant"
              from: 2
              to: 0
              duration: 1800
              easing.type: Easing.InOutSine
          }
      }
      SequentialAnimation {
          loops: Animation.Infinite
          running: window.middleHovered
          
          NumberAnimation {
              target: window
              property: "middleInnerSlant"
              from: 0
              to: 2
              duration: 1800
              easing.type: Easing.InOutSine
          }
          NumberAnimation {
              target: window
              property: "middleInnerSlant"
              from: 2
              to: 0
              duration: 1800
              easing.type: Easing.InOutSine
          }
      }
      BatteryMonitor { id: battery }
      Column{
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 300
        anchors.horizontalCenterOffset: 750
        spacing: 20
        
          Item {
          width: batteryText.width + 50
          height: batteryText.height + 50
          transform: Scale { xScale: -1; origin.x: (batteryText.width + 50) / 2 }
          
          property bool hovered: false
          scale: hovered ? 1.2 : 1.0
          opacity: hovered ? 1.0 : 0.6
          rotation: hovered ? -2: 0             
          Behavior on scale {
              NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
          }
          Behavior on opacity {
              NumberAnimation { duration: 200 }
            }
          Behavior on rotation {
                  NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
              }
          
          MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: {
                  parent.hovered = true
                  window.middleHovered = true
              }
              onExited: {
                  parent.hovered = false
                  window.middleHovered = false
              }
          }
          

                  Canvas {
                    anchors.fill: parent
                    anchors.margins: -10
                    rotation: window.middleOuterSlant
                    transformOrigin: Item.Center
                    
                    Behavior on rotation {
                        enabled: false
                    }
                    
                  onPaint: {
                      var ctx = getContext("2d");
                      ctx.fillStyle = colors.color3;
                      ctx.beginPath();
                      var offsetTop = 50;
                      var offsetRight = 90;

                      ctx.moveTo(parent.width - (80 + (parent.width - offsetTop)), 0);
                      ctx.lineTo(parent.width - (20 + parent.width + offsetRight), parent.height);
                      ctx.lineTo(parent.width - 90, parent.height);
                      ctx.closePath();
                      ctx.fill();
                    }
                  }

                  Canvas {
                    anchors.fill: parent
                    anchors.margins: -10
                    rotation: window.middleInnerSlant
                    transformOrigin: Item.Center

                    Behavior on rotation {
                        enabled: false
                    }

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.fillStyle = "white";
                        ctx.beginPath();
                        var offset = -10;

                        ctx.moveTo(parent.width - (30 + (parent.width - offset)), 10);
                        ctx.lineTo(parent.width - (30 + parent.width), parent.height - 10);
                        ctx.lineTo(parent.width - 30, parent.height - 10);
                        ctx.closePath();
                        ctx.fill();
                      }
                  }
                  Row{
                    anchors.centerIn: parent
                    spacing: 20
                    anchors.horizontalCenterOffset: -80
                    anchors.verticalCenterOffset: 10
                    rotation: window.middleInnerSlant
                    transform: Scale { xScale: -1; origin.x: batteryText.width / 2 }
                    Text {
                      id: batteryText
                      text: battery.icon + " " + battery.capacity + "%"
                      font.bold: true
                      font.family: "Montserrat ExtraBold"
                      font.pixelSize: 80
                      color:"black"
                    }
                  }
        }
      }
    }
  }
}
