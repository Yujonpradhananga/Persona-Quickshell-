import Quickshell
import QtQuick

Rectangle {
  id: root
  width: parent.width
  height: parent.height/2
  color: "transparent"
  Repeater {
    model: {
      const min=20
      const max=50
      return Math.floor(Math.random() * (max - min + 1)) + min
    }
    Rectangle {
      height: {
        const min=70
        const max=root.height-40
        return Math.floor(Math.random() * (max - min - 1)) + min + 1
      }
      width: 3
      color: "#bf" + Color.colors.primary
      bottomLeftRadius: width/2
      bottomRightRadius: width/2
      x: {
        function createUniqueRandom(min, max) {
          const pool = []
          for (let i = min + 1; i < max; i++) pool.push(i)
          return function () {
            if (!pool.length) return undefined
            return pool.splice(Math.random() * pool.length | 0, 1)[0]
          }
        }
        const min = 20
        const max = root.width
        const rand = createUniqueRandom(min, max)
        return rand()
      }

      Text {
        text: {
          const options = ["󰽧", ""]
          return options[Math.floor(Math.random() * options.length)]
        }
        font.family: "Symbols Nerd Font"
        color: "#bf" + Color.colors.primary
        font.pointSize: text === "󰽧" ? 28 : 25
        rotation: text === "󰽧" ? 45 : 0
        anchors.horizontalCenterOffset: text === "󰽧" ? -5.6 : 0
        anchors.top: parent.bottom
        anchors.topMargin: text === "󰽧" ? -5 : -3
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }
  }
}
