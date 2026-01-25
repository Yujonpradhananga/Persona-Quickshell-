import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import Quickshell.Wayland


Scope {
	id: root
  Colors { id: colors }
	PwObjectTracker {
		objects: [ Pipewire.defaultAudioSink ]
	}
	Connections {
		target: Pipewire.defaultAudioSink?.audio ?? null
		enabled: target !== null
		function onVolumeChanged() {
			root.shouldShowOsd = true;
			hideTimer.restart();
		}
	}
	property bool shouldShowOsd: false
	Timer {
		id: hideTimer
		interval: 1000
		onTriggered: root.shouldShowOsd = false
	}
	LazyLoader {
		active: root.shouldShowOsd
		
		PanelWindow {
			anchors.top: true
			margins.top: screen.height / 9
			exclusiveZone: 0
			WlrLayershell.layer: WlrLayer.Overlay
			implicitWidth: 550
			implicitHeight: 50
			color: "transparent"
			mask: Region {}
			
			Rectangle {
				anchors.fill: parent
				radius: height / 2
        color: colors.color2
				
				RowLayout {
					anchors {
						fill: parent
						leftMargin: 15
						rightMargin: 15
					}
					spacing: 10
					
					// Volume icon (optional - you can add this)
					Text {
						text: {
							var vol = Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100);
							var muted = Pipewire.defaultAudioSink?.audio.muted ?? false;
							if (muted || vol === 0) return "󰖁";
							else return "󰕾";
						}
            color: "#ffffff"
						font.pixelSize: 25
						font.family: "Montserrat Light"
					}
					
					// Slider
					Rectangle {
						Layout.fillWidth: true
						implicitHeight: 10
						radius: 20
            color: colors.color3
						
						Rectangle {
							anchors {
								left: parent.left
								top: parent.top
								bottom: parent.bottom
							}
							implicitWidth: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
							radius: parent.radius
							color: "#ffffff"
						}
					}
					
					// Percentage text
					Text {
						text: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%"
						color: "#ffffff"
						font.pixelSize: 20
						font.family: "Montserrat Light"
						font.weight: Font.Bold
						Layout.minimumWidth: 50
						horizontalAlignment: Text.AlignRight
					}
				}
			}
		}
	}
}
