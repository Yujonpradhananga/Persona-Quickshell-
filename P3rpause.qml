import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtMultimedia

Scope {
    id: root
    property bool shouldShow: false
    property var targetScreen: null
    Colors { id: colors }
    
    // Process for poweroff command
    Process {
        id: poweroffProcess
        command: ["loginctl", "poweroff"]
        running: false
    }
    
    // Process for restart command
    Process {
        id: restartProcess
        command: ["loginctl", "reboot"]
        running: false
    }
    
    // Process for logout command (Placeholder, adjust for specific WM/setup)
    Process {
        id: logoutProcess
        command: ["loginctl", "terminate-session", "self"]
        running: false
    }
    
    // Preload PNG images for faster startup
    property var preloadedImages: []
    Component.onCompleted: {
    // Preload PNG images
    for (var i = 0; i < 12; i++) {
        var img = Qt.createQmlObject('import QtQuick; Image { visible: false; source: "' + 
            Qt.resolvedUrl("assets/p3r menu/png/pngseq" + String(i).padStart(2, '0') + ".png") + '" }', root)
        preloadedImages.push(img)
    }
    
    // Preload videos by creating hidden Video components
    var video1 = Qt.createQmlObject('import QtQuick; import QtMultimedia; Video { visible: false; source: "' + 
        Qt.resolvedUrl("assets/p3r menu/part2.mp4") + '" }', root)
    var video2 = Qt.createQmlObject('import QtQuick; import QtMultimedia; Video { visible: false; source: "' + 
        Qt.resolvedUrl("assets/p3r menu/part3.mp4") + '" }', root)
    
    preloadedImages.push(video1)
    preloadedImages.push(video2)
}
    
    // Cleanup function to free memory
    function cleanup() {
        for (var i = 0; i < preloadedImages.length; i++) {
            if (preloadedImages[i]) {
                preloadedImages[i].destroy()
            }
        }
        preloadedImages = []
    }
    

    LazyLoader {
        active: true
        
        PanelWindow {
            id: p3rpauseWindow
            visible: root.shouldShow
            screen: root.targetScreen
            color: "transparent"
            onVisibleChanged: {
              if (visible) {
              overlay.resetMenu()
                }
              }
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Normal
            
            anchors {
                right: true
                left: true
                top: true
                bottom: true
            }
            
            Rectangle {
                id: overlay
                anchors.fill: parent
                color: "transparent"
                
                // Track current stage: 0=png sequence, 1=part2, 2=part3
                property int stage: 0
                
                // Slide up transform for exit animation
                transform: Translate {
                    id: slideTransform
                    y: 0
                  }

                function resetMenu() {
                    // Reset stage
                    overlay.stage = 0
                    overlay.opacity = 1
                    slideTransform.y = 0
                    
                    // Reset PNG sequence
                    pngSequence.currentFrame = 0
                    pngSequence.visible = true
                    
                    // Reset videos
                    part2Video.stop()
                    part2Video.visible = false
                    part2Video.seek(0)
                    
                    part3Video.stop()
                    part3Video.visible = false
                    part3Video.seek(0)
                    
                    // Preload videos again
                    part2Video.play()
                    part2Video.pause()
                    part2Video.seek(0)
                    part3Video.play()
                    part3Video.pause()
                    part3Video.seek(0)
                    
                    // Start animation
                    frameAnimation.start()
                }
                
                // Slide up and fade out animation for closing
                ParallelAnimation {
                    id: hideAnimation
                    running: false
                    
                    NumberAnimation {
                        target: slideTransform
                        property: "y"
                        from: 0
                        to: -overlay.height
                        duration: 300
                        easing.type: Easing.InCubic
                    }
                    
                    NumberAnimation {
                        target: overlay
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 300
                        easing.type: Easing.InCubic
                    }
                    
                    onFinished: {
                        frameAnimation.stop()
                        destroyTimer.start()
                    }
                }
                
                    Timer {
                        id: destroyTimer
                        interval: 10
                        repeat: false
                        onTriggered: {
                            root.shouldShow = false
                            // Don't destroy, just reset state
                            overlay.stage = 0
                            pngSequence.currentFrame = 0
                        }
                    }
                
                    Component.onCompleted: {
                        // Preload part2 and part3 videos
                        part2Video.play()
                        part2Video.pause()
                        part2Video.seek(0)
                        part3Video.play()
                        part3Video.pause()
                        part3Video.seek(0)
                        // Start PNG sequence animation
                        pngSequence.visible = true
                        frameAnimation.start()
                    }
                
                // PNG Sequence with transparency (plays first)
                Image {
                    id: pngSequence
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    visible: true
                    cache: true
                    asynchronous: false
                    
                    property int currentFrame: 0  
                    property int totalFrames: 12
                    property int frameRate: 60
                    
                    source: Qt.resolvedUrl("assets/p3r menu/png/pngseq" + String(currentFrame).padStart(2, '0') + ".png")
                    
                    Timer {
                        id: frameAnimation
                        interval: 1000 / pngSequence.frameRate
                        repeat: true
                        running: false
                        
                        onTriggered: {
                            if (pngSequence.currentFrame < pngSequence.totalFrames - 1) {
                                pngSequence.currentFrame++
                            } else {
                                frameAnimation.stop()
                                pngSequence.visible = false
                                overlay.stage = 1
                                part2Video.visible = true
                                part2Video.play()
                            }
                        }
                    }
                }
                
                // Part 2 video - plays once after PNG sequence
                Video {
                    id: part2Video
                    anchors.fill: parent
                    source: Qt.resolvedUrl("assets/p3r menu/part2.mp4")
                    fillMode: VideoOutput.PreserveAspectCrop
                    volume: 0
                    visible: false
                    
                    onPositionChanged: {
                        if (duration > 0 && position >= duration - 50 && overlay.stage === 1) {
                            part2Video.visible = false
                            overlay.stage = 2
                            part3Video.visible = true
                            part3Video.play()
                        }
                    }
                    
                    onPlaybackStateChanged: {
                        if (playbackState === MediaPlayer.StoppedState && overlay.stage === 1) {
                            part2Video.visible = false
                            overlay.stage = 2
                            part3Video.visible = true
                            part3Video.play()
                        }
                    }
                }
                
                // Part 3 video - loops infinitely
                Video {
                    id: part3Video
                    anchors.fill: parent
                    source: Qt.resolvedUrl("assets/p3r menu/part3.mp4")
                    fillMode: VideoOutput.PreserveAspectCrop
                    loops: MediaPlayer.Infinite
                    volume: 0
                    visible: false
                }
                
                // Power Options Container - use Item instead of Column to prevent shifting
                Item {
                    id: powerOptionsContainer
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 50
                    anchors.verticalCenterOffset: 10
                    width: 800
                    height: 500
                    visible: overlay.stage >= 1
                    z: 10
                    
                    // Shutdown Option - fixed position
                    Item {
                        id: poweroffItem
                        x: 30
                        y: -75
                        width: 900
                        height: 350
                        rotation: 3
                        property bool hovered: false
                        scale: hovered ? 1.1 : 1.0
                        transformOrigin: Item.Center
                        
                        Behavior on scale {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        
                        MouseArea {
                          anchors.centerIn: parent
                          width: parent.width * 0.4
                          height: parent.height * 0.4
                          hoverEnabled: true
                          onEntered: parent.hovered = true
                          onExited: parent.hovered = false
                          onClicked: poweroffProcess.running = true
                        }
                        
                        // Image (swaps on hover)
                        Image {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            source: poweroffItem.hovered ? Qt.resolvedUrl("assets/iconpack/shutdown1.png") : Qt.resolvedUrl("assets/iconpack/shutdown.png")
                        }
                    }
                    
                    // Restart Option - fixed position
                    Item {
                        id: restartItem
                        x: 30
                        y: 100
                        width: 900
                        height: 350
                        rotation: -5
                        property bool hovered: false
                        scale: hovered ? 1.1 : 1.0
                        transformOrigin: Item.Center
                        
                        Behavior on scale {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        
                        MouseArea {
                            anchors.centerIn: parent
                            hoverEnabled: true
                            width: parent.width * 0.4
                            height: parent.height * 0.4
                            onEntered: parent.hovered = true
                            onExited: parent.hovered = false
                            onClicked: restartProcess.running = true
                        }
                        
                        // Image (swaps on hover)
                        Image {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            source: restartItem.hovered ? Qt.resolvedUrl("assets/iconpack/restart1.png") : Qt.resolvedUrl("assets/iconpack/restart.png")
                        }
                    }
                    
                    // Logout Option - fixed position
                    Item {
                        id: logoutItem
                        x: 30
                        y: 300
                        width: 900
                        height: 350
                        rotation: -12
                        property bool hovered: false
                        scale: hovered ? 1.1 : 1.0
                        transformOrigin: Item.Center
                        
                        Behavior on scale {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        
                        MouseArea {
                            anchors.centerIn: parent
                            hoverEnabled: true
                            width: parent.width * 0.4
                            height: parent.height * 0.4
                            onEntered: parent.hovered = true
                            onExited: parent.hovered = false
                            onClicked: logoutProcess.running = true
                        }
                        
                        // Image (swaps on hover)
                        Image {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            source: logoutItem.hovered ? Qt.resolvedUrl("assets/iconpack/logout1.png") : Qt.resolvedUrl("assets/iconpack/logout.png")
                        }
                    }
                }

                
                // Click anywhere to exit (behind power options)
                FocusScope {
                    anchors.fill: parent
                    focus: true
                    
                    MouseArea {
                        anchors.fill: parent
                        z: -1  // Behind power options
                        onClicked: hideAnimation.start()
                    }
                    
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            hideAnimation.start()
                            event.accepted = true
                        }
                    }

                    
                    Component.onCompleted: {
                        forceActiveFocus()
                    }
                }

        }
    }
    }
}
