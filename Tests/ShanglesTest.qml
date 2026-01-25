import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {

  Variants{
    model: Quickshell.screens

  PanelWindow {
    anchors {
      top: true
      left: true
      right: true
    }
    
    height: 400 // Adjust as needed
    required property var modelData
    screen: modelData
    color: "transparent"
      WlrLayershell.layer: WlrLayer.Bottom
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
    
    Shangles {
      anchors.fill: parent
    }
  }
  }

}
