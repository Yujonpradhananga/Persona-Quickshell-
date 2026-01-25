import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    QtObject {
        id: colors
        property color foreground: "#ffffff"
    }
    
    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            id: clickWindow
            required property var modelData
            screen: modelData
            
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            
            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                onClicked: (mouse) => {
                    console.log("Click detected at", mouse.x, mouse.y);
                    effectComponent.createObject(clickWindow.contentItem, {
                        x: mouse.x - 10,
                        y: mouse.y - 10
                    });
                    mouse.accepted = false;  // Let clicks pass through
                }
            }
            
            Component {
                id: effectComponent
                
                Item {
                    id: root
                    width: 20
                    height: 20
                    
                    component ThisAnim: SequentialAnimation {
                        id: thisanim
                        property int animDuration: 150
                        property var animTarget
                        property string animProperty
                        running: true
                        NumberAnimation {
                            target: thisanim.animTarget
                            property: thisanim.animProperty
                            to: 4
                            duration: thisanim.animDuration
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: thisanim.animTarget
                                property: thisanim.animProperty
                                to: 8
                                duration: thisanim.animDuration
                            }
                            NumberAnimation {
                                target: thisanim.animTarget
                                property: "scale"
                                to: 0.5
                                duration: thisanim.animDuration
                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: thisanim.animTarget
                                property: thisanim.animProperty
                                to: 12
                                duration: thisanim.animDuration
                            }
                            NumberAnimation {
                                target: thisanim.animTarget
                                property: "scale"
                                to: 0
                                duration: thisanim.animDuration
                            }
                        }
                        onFinished: {
                            root.destroy();
                        }
                    }
                    
                    component ThisRectangle: Rectangle {
                        color: colors.foreground
                    }
                    
                    component PartialEffect: Item {
                        id: effect
                        property real wid: 4
                        property real hei: 8
                        ThisRectangle {
                            id: top
                            width: effect.wid
                            height: effect.hei
                            anchors.bottom: center.top
                            anchors.horizontalCenter: center.horizontalCenter
                            transformOrigin: Item.Top
                            ThisAnim {
                                animTarget: top
                                animProperty: "anchors.bottomMargin"
                            }
                        }
                        Rectangle {
                            id: center
                            width: 20
                            height: 20
                            color: "transparent"
                            anchors.centerIn: parent
                        }
                        ThisRectangle {
                            id: left
                            transformOrigin: Item.Left
                            width: effect.hei
                            height: effect.wid
                            anchors.right: center.left
                            anchors.verticalCenter: center.verticalCenter
                            ThisAnim {
                                animTarget: left
                                animProperty: "anchors.rightMargin"
                            }
                        }
                    }
                    
                    PartialEffect {
                        id: vert
                    }
                    
                    PartialEffect {
                        id: fourtyFive
                        rotation: 45
                    }
                }
            }
        }
    }
}
