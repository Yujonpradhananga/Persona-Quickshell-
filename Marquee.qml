import QtQuick
Item {
    id: root

    required property string text
    required property int maxWidth

    property var font: Fonts.monoFont
    property int size: 11
    property var color: Colors.text
    property int scrollRate: 5
    property int pauseDuration: Globals.anim.durations.normal

    clip: true
    width: Math.min(maxWidth, text1.paintedWidth)
    implicitHeight: text1.implicitHeight

    Text {
        id: spaceMeasure
        text: "   "
        font.family: root.font
        font.pointSize: root.size
        visible: false
    }

    Text {
        id: text1
        text: root.text
        font.family: root.font
        font.pointSize: root.size
        color: root.color
        visible: true
    }

    Text {
        id: text2
        text: root.text
        font.family: root.font
        font.pointSize: root.size
        color: root.color
        visible: false
    }

    SequentialAnimation {
        id: scrollAnim
        loops: Animation.Infinite

        PauseAnimation {
            duration: root.pauseDuration
        }

        NumberAnimation {
            target: text1
            property: "x"
            from: 0
            to: -text1.paintedWidth - spaceMeasure.width
            duration: (text1.paintedWidth + spaceMeasure.width) * root.scrollRate
            easing.type: Easing.Linear
        }

        ScriptAction {
            script: {
                text1.x = 0;
                text2.x = text1.paintedWidth + spaceMeasure.width;
            }
        }
    }

    Connections {
        target: text1
        function onXChanged() {
            if (scrollAnim.running)
                text2.x = text1.x + text1.paintedWidth + spaceMeasure.width;
        }
    }

    function restartAnimation() {
        scrollAnim.stop();

        if (text1.paintedWidth > root.maxWidth) {
            text1.x = 0;
            text2.x = text1.paintedWidth + spaceMeasure.width;
            text2.visible = true;
            scrollAnim.start();
        } else {
            text1.x = 0;
            text2.visible = false;
        }
    }

    Component.onCompleted: restartAnimation()
    onTextChanged: restartAnimation()
    onWidthChanged: restartAnimation()
}
