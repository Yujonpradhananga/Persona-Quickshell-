pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// First, create BatteryMonitor.qml as a separate file:
// (This is the QtObject that holds battery data)

ShellRoot {
  PanelWindow {
    id: window
    anchors {
      top: true
      left: true
      right: true
    }
    height: 100
    color: "#1e1e2e"
    
    // Instantiate the battery monitor
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
          console.log("Battery capacity loaded:", battery.capacity)
        }
      }
      
      property FileView statusFile: FileView {
        path: "/sys/class/power_supply/BAT0/status"
        onLoaded: {
          battery.status = text().trim()
          battery.updateIcon()
          console.log("Battery status loaded:", battery.status)
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
    
    // Display the battery info
    Row {
      anchors.centerIn: parent
      spacing: 20
      
      Text {
        text: battery.icon + " " + battery.capacity + "%"
        font.bold: true
        font.family: "Montserrat ExtraBold"
        font.pixelSize: 48
        color: "#cdd6f4"
      }
      
      Text {
        text: "Status: " + battery.status
        font.family: "Montserrat"
        font.pixelSize: 24
        color: "#a6adc8"
      }
    }
  }
}
