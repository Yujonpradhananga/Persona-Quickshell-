pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// DwlService for MangoWC
Singleton {
    id: root

    property bool dwlAvailable: false
    property var outputs: ({})
    property int tagCount: 9
    property string activeOutput: ""

    signal stateChanged()

    Component.onCompleted: {
        checkMangoWC()
    }

    // Timer to poll MangoWC state - faster polling for better responsiveness
    Timer {
        interval: 100  // Poll every 100ms for quick updates
        running: root.dwlAvailable
        repeat: true
        onTriggered: root.getTagState()
    }

    // Check if MangoWC is running
    Process {
        id: checkProcess
        command: ["sh", "-c", "pgrep -x mango || pgrep -x dwl"]
        running: false

        onExited: exitCode => {
            const wasAvailable = dwlAvailable
            dwlAvailable = (exitCode === 0)
            
            if (dwlAvailable && !wasAvailable) {
                getTagState()
            } else if (!dwlAvailable && wasAvailable) {
                outputs = {}
                stateChanged()
            }
        }
    }

    // Get tag state using mmsg -g -t -l (tags + layout)
    Process {
        id: tagStateProcess
        command: ["mmsg", "-g", "-t", "-l"]
        running: false
        
        property var lineBuffer: []

        stdout: SplitParser {
            onRead: data => {
                tagStateProcess.lineBuffer.push(data)
            }
        }

        onExited: exitCode => {
            if (exitCode === 0 && tagStateProcess.lineBuffer.length > 0) {
                const fullOutput = tagStateProcess.lineBuffer.join('\n')
                parseTagOutput(fullOutput)
            }
            tagStateProcess.lineBuffer = []
        }
    }

    function parseTagOutput(data) {
        try {
            const lines = data.trim().split('\n')
            const newOutputs = {}
            
            for (const line of lines) {
                const parts = line.trim().split(/\s+/)
                
                if (parts.length < 3) continue
                
                const outputName = parts[0]
                const key = parts[1]
                
                // Initialize output if needed
                if (!newOutputs[outputName]) {
                    newOutputs[outputName] = {
                        name: outputName,
                        tags: Array(tagCount).fill(null).map((_, i) => ({
                            tag: i,
                            state: 0,
                            clients: 0
                        })),
                        layout: "",
                        isSelected: true
                    }
                }
                
                if (key === "tag" && parts.length >= 5) {
                    const tagNum = parseInt(parts[2]) - 1
                    const state = parseInt(parts[3])
                    const clients = parseInt(parts[4])
                    
                    if (tagNum >= 0 && tagNum < tagCount) {
                        newOutputs[outputName].tags[tagNum] = {
                            tag: tagNum,
                            state: state,
                            clients: clients
                        }
                    }
                } else if (key === "layout") {
                    newOutputs[outputName].layout = parts[2]
                }
            }
            
            outputs = newOutputs
            if (Object.keys(newOutputs).length > 0) {
                activeOutput = Object.keys(newOutputs)[0]
            }
            
            stateChanged()
            
        } catch (e) {
            console.error("Error parsing tag output:", e)
        }
    }

    function checkMangoWC() {
        checkProcess.running = true
    }

    function getTagState() {
        if (dwlAvailable) {
            tagStateProcess.running = true
        }
    }

    function getOutputState(outputName) {
        return outputs[outputName] || null
    }

    function getActiveTags(outputName) {
        const output = getOutputState(outputName)
        if (!output || !output.tags) return []
        
        return output.tags
            .filter(tag => tag.state === 1)
            .map(tag => tag.tag)
    }

    // Switch to a specific tag (uses tag number directly, not bitmask)
    function switchToTag(outputName, tagIndex) {
        if (!dwlAvailable) {
            console.warn("MangoWC not available")
            return
        }
        
        // tagIndex is 0-based, so tag 0 = "1", tag 1 = "2", etc.
        const tagNumber = tagIndex + 1
        console.log("Switching to tag", tagNumber, "on output", outputName)
        
        // Use mmsg -t <tag_number> to switch focus to that tag
        Quickshell.execDetached(["mmsg", "-t", tagNumber.toString()])
        
        // Refresh state after a short delay
        refreshTimer.restart()
    }

    function toggleTag(outputName, tagIndex) {
        if (!dwlAvailable) return

        const output = getOutputState(outputName)
        if (!output || !output.tags) return

        // Calculate current mask
        let currentMask = 0
        output.tags.forEach(tag => {
            if (tag.state === 1) {
                currentMask |= (1 << tag.tag)
            }
        })

        const clickedMask = 1 << tagIndex
        let newMask = currentMask ^ clickedMask

        // If toggling off the last tag, switch to it instead
        if (newMask === 0) {
            newMask = clickedMask
        }
        
        console.log("Toggling tag", tagIndex + 1, "on output", outputName, "new mask", newMask)
        
        // Use -v for viewing
        Quickshell.execDetached(["mmsg", "-o", outputName, "-v", newMask.toString()])
        refreshTimer.restart()
    }

    function moveToTag(outputName, tagIndex) {
        if (!dwlAvailable) {
            console.warn("MangoWC not available")
            return
        }
        
        const tagNumber = tagIndex + 1
        console.log("Moving window to tag", tagNumber, "on output", outputName)
        
        // Use -s -t to set/move the focused window to a tag
        Quickshell.execDetached(["mmsg", "-o", outputName, "-s", "-t", tagNumber.toString()])
        
        refreshTimer.restart()
    }

    // Refresh state after commands
    Timer {
        id: refreshTimer
        interval: 150
        onTriggered: root.getTagState()
    }

    // Periodic check if MangoWC is still running
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            if (!root.dwlAvailable) {
                root.checkMangoWC()
            }
        }
    }
}
