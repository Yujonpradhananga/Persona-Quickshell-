pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."

/**
 * DwlWindows - Multi-monitor Window & Tag Tracker for dwl/MangoWC
 */
Singleton {
    id: root

    // Window list with tag assignments
    property var windowList: []
    
    // Map of window key -> tag index (ONLY for manually moved windows)
    property var manualTagMap: ({})
    
    // Map of window key -> monitor name (ONLY for manually moved windows)
    property var manualMonitorMap: ({})

    signal windowsChanged()

    // Get all windows for a specific tag on a specific monitor
    function windowsForTag(monitorName, tagIndex) {
        return windowList.filter(w => w.monitorName === monitorName && w.tagIndex === tagIndex)
    }

    // Get window count per tag per monitor
    function windowCountForTag(monitorName, tagIndex) {
        return windowsForTag(monitorName, tagIndex).length
    }

    // Move a window to a different tag
    function moveWindowToTag(toplevel, targetTagIndex) {
        if (!toplevel) return
        
        let monitorName = ""
        if (toplevel.outputs && toplevel.outputs.length > 0) {
            monitorName = toplevel.outputs[0].name
        }
        
        let key = getWindowKey(toplevel)
        
        // Update MANUAL tracking (persistence)
        manualTagMap[key] = targetTagIndex
        if (monitorName) manualMonitorMap[key] = monitorName
        
        // Activate and move
        toplevel.activate()
        
        let outputToUse = monitorName || DwlService.activeOutput
        
        moveTimer.targetTag = targetTagIndex
        moveTimer.targetOutput = outputToUse
        moveTimer.restart()
        
        Qt.callLater(refreshWindowList)
    }

    function closeWindow(toplevel) {
        if (!toplevel) return
        let key = getWindowKey(toplevel)
        delete manualTagMap[key]
        delete manualMonitorMap[key]
        toplevel.requestClose()
        Qt.callLater(refreshWindowList)
    }

    function getWindowKey(toplevel) {
        return (toplevel.appId || "unknown") + "_" + (toplevel.title || "untitled")
    }

    function refreshWindowList() {
        let toplevels = ToplevelManager.toplevels.values.filter(t => t && t.title !== "")
        let newWindowList = []
        
        // Get known outputs from DwlService
        let outputNames = Object.keys(DwlService.outputs)
        
        // 1. Prepare target counts (truth from mmsg)
        let monitorTagCounts = {} 
        for (let name of outputNames) {
            let state = DwlService.getOutputState(name)
            if (state && state.tags) {
                monitorTagCounts[name] = state.tags.map(t => t.clients || 0)
            } else {
                monitorTagCounts[name] = Array(9).fill(0)
            }
        }
        
        // Track how many slots we have filled
        let monitorAssignedCounts = {}
        for (let name of outputNames) {
            monitorAssignedCounts[name] = Array(9).fill(0)
        }

        // Helper to check if a monitor has room
        function monitorHasRoom(mName) {
            if (!monitorTagCounts[mName]) return false
            // Check if total assigned < total expected
            let totalExpected = monitorTagCounts[mName].reduce((a,b) => a+b, 0)
            let totalAssigned = monitorAssignedCounts[mName].reduce((a,b) => a+b, 0)
            return totalAssigned < totalExpected
        }
        
        // 2. Separate Toplevels into Known vs Unknown Monitor/Tag
        let knownToplevels = []
        let unknownToplevels = [] 
        
        for (let toplevel of toplevels) {
            let key = getWindowKey(toplevel)
            
            // Explicit manual override?
            if (manualMonitorMap[key]) {
                toplevel.manualMonitor = manualMonitorMap[key]
                toplevel.manualTag = manualTagMap[key]
                knownToplevels.push(toplevel)
                continue
            }
            
            // Check ForeignToplevel outputs
            let foundOutput = false
            if (toplevel.outputs && toplevel.outputs.length > 0) {
                 // Try to match an output name
                 for (let o of toplevel.outputs) {
                     if (outputNames.includes(o.name)) {
                         toplevel.detectedMonitor = o.name
                         foundOutput = true
                         break
                     }
                 }
            }
            
            if (foundOutput) {
                knownToplevels.push(toplevel)
            } else {
                unknownToplevels.push(toplevel)
            }
        }
        
        // 3. Process Known Monitor Windows
        for (let toplevel of knownToplevels) {
            let key = getWindowKey(toplevel)
            let monitorName = toplevel.manualMonitor || toplevel.detectedMonitor
            
            let assignedTag = -1
            
            if (toplevel.manualTag !== undefined) {
                assignedTag = toplevel.manualTag
            } else {
                // Heuristic on THIS monitor
                let counts = monitorTagCounts[monitorName] || Array(9).fill(0)
                let assigneds = monitorAssignedCounts[monitorName] || Array(9).fill(0)
                
                for (let t = 0; t < 9; t++) {
                    if (counts[t] > 0 && assigneds[t] < counts[t]) {
                        assignedTag = t
                        break
                    }
                }
                if (assignedTag === -1) {
                     let activeTags = DwlService.getActiveTags(monitorName)
                     assignedTag = activeTags.length > 0 ? activeTags[0] : 0
                }
            }
            
            if (!monitorAssignedCounts[monitorName]) monitorAssignedCounts[monitorName] = Array(9).fill(0)
            monitorAssignedCounts[monitorName][assignedTag]++
            
            newWindowList.push({
                toplevel: toplevel,
                tagIndex: assignedTag,
                monitorName: monitorName,
                appId: toplevel.appId || "unknown",
                title: toplevel.title || "untitled",
                activated: toplevel.activated || false
            })
        }
        
        // 4. Process Unknown Windows (Global Accounting)
        for (let toplevel of unknownToplevels) {
            let chosenMonitor = ""
            
            // Prefer active monitor if it has room
            if (monitorHasRoom(DwlService.activeOutput)) {
                chosenMonitor = DwlService.activeOutput
            } else {
                // Find any monitor with room
                for (let m of outputNames) {
                    if (monitorHasRoom(m)) {
                        chosenMonitor = m
                        break
                    }
                }
            }
            
            // STRICTER FALLBACK: Do NOT default to random output if no room is found.
            // This prevents "monitor leak" (phantom windows).
            if (!chosenMonitor) continue
            
            // Now fit into tag
            let counts = monitorTagCounts[chosenMonitor] || Array(9).fill(0)
            let assigneds = monitorAssignedCounts[chosenMonitor] || Array(9).fill(0)
            let assignedTag = -1
            
            for (let t = 0; t < 9; t++) {
                if (counts[t] > 0 && assigneds[t] < counts[t]) {
                    assignedTag = t
                    break
                }
            }
            if (assignedTag === -1) {
                 let activeTags = DwlService.getActiveTags(chosenMonitor)
                 assignedTag = activeTags.length > 0 ? activeTags[0] : 0
            }
            
            if (!monitorAssignedCounts[chosenMonitor]) monitorAssignedCounts[chosenMonitor] = Array(9).fill(0)
            monitorAssignedCounts[chosenMonitor][assignedTag]++
            
            newWindowList.push({
                toplevel: toplevel,
                tagIndex: assignedTag,
                monitorName: chosenMonitor,
                appId: toplevel.appId || "unknown",
                title: toplevel.title || "untitled",
                activated: toplevel.activated || false
            })
        }
        
        windowList = newWindowList
        windowsChanged()
    }

    Timer {
        id: moveTimer
        property int targetTag: -1
        property string targetOutput: ""
        interval: 150
        onTriggered: {
            if (targetTag >= 0 && targetOutput !== "") {
                DwlService.moveToTag(targetOutput, targetTag)
                DwlService.getTagState()
                targetTag = -1
                targetOutput = ""
            }
        }
    }

    Connections {
        target: ToplevelManager
        function onToplevelsChanged() { refreshWindowList() }
    }

    Connections {
        target: DwlService
        function onStateChanged() { refreshWindowList() }
    }

    Component.onCompleted: refreshWindowList()
}
