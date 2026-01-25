import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtMultimedia


Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            property var modelData
            
            screen: modelData
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "wallpaper"
            
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }
            
            color: "black"

Video {
    id: wallpaper
    source: Qt.resolvedUrl("assets/wallpapers/solo_1080p.mp4")
    
    anchors.fill: parent
    fillMode: VideoOutput.PreserveAspectCrop
    
    loops: MediaPlayer.Infinite
    volume: 0
    autoPlay: true
}
        }
    }
}
