import QtQuick
import Quickshell.Io

QtObject {
  id: root
  
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
      root.capacity = parseInt(text().trim())
      root.updateIcon()
    }
  }
  
  property FileView statusFile: FileView {
    path: "/sys/class/power_supply/BAT0/status"
    onLoaded: {
      root.status = text().trim()
      root.updateIcon()
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
