pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

Singleton {
    id: root

    // --- Public API ---

    // Whether we are connected to a supported window manager with full features
    readonly property bool isHyprland: Hyprland.connected

    // Current active workspace ID (1-based index usually)
    property int activeWorkspaceId: isHyprland ? (Hyprland.focusedWorkspace?.id ?? 1) : (DwlService.activeTag ?? 1)

    // List of windows/clients
    // Format: { address: string, workspaceId: int, class: string, title: string, x: int, y: int, width: int, height: int, focus: bool }
    property var windows: []

    // Move a window to a specific workspace
    function moveToWorkspace(address, workspaceId) {
        if (isHyprland) {
            Hyprland.dispatch(`movetoworkspacesilent ${workspaceId},address:${address}`)
        } else {
            // Attempt using DwlService
             DwlService.moveToTag(DwlService.activeOutput, workspaceId - 1)
        }
    }
    
    // Switch to a specific workspace
    function switchToWorkspace(workspaceId) {
        if (isHyprland) {
            Hyprland.dispatch(`workspace ${workspaceId}`)
        } else {
             // Fallback for DWL/MangoWC using DwlService if available
             // Assuming workspaceId maps to tags 1-9
             // DwlService expects 0-indexed tag index
             DwlService.switchToTag(DwlService.activeOutput, workspaceId - 1)
        }
    }

    // --- Internal Logic ---

    // Hyprland Data Mapping
    Connections {
        target: Hyprland
        enabled: root.isHyprland
        
        function onClientsChanged() {
            root.updateHyprlandWindows()
        }
        function onFocusedWorkspaceChanged() {
            // Binding handles activeWorkspaceId, but ensuring updates
        }
    }

    function updateHyprlandWindows() {
        if (!isHyprland) return;

        let newWindows = [];
        let clients = Hyprland.clients;
        
        for (let i = 0; i < clients.length; i++) {
            let client = clients[i];
            newWindows.push({
                address: client.address,
                workspaceId: client.workspace.id,
                class: client.class,
                title: client.title,
                x: client.at[0],
                y: client.at[1],
                width: client.size[0],
                height: client.size[1],
                focus: client.focus
            });
        }
        root.windows = newWindows;
    }

    // Generic Data Mapping (ToplevelManager)
    Connections {
        target: ToplevelManager
        enabled: !root.isHyprland
        
        function onToplevelsChanged() {
            root.updateGenericWindows()
        }
    }

    function updateGenericWindows() {
         if (isHyprland) return; // Hyprland path takes precedence

         let newWindows = [];
         let toplevels = ToplevelManager.toplevels.values;
         let activeWs = root.activeWorkspaceId;

         for (let i = 0; i < toplevels.length; i++) {
             let t = toplevels[i];
             
             // Generic protocol usually acts on active workspace or doesn't share workspace info easily.
             // We assign them to current active workspace so they are visible in mousemover.
             
             newWindows.push({
                 address: t.appId + i, // Fake address
                 workspaceId: activeWs, 
                 class: t.appId,
                 title: t.title,
                 x: 50 + (i * 30), // Cascade
                 y: 50 + (i * 30),
                 width: 400, // Default size
                 height: 300,
                 focus: t.active
             });
         }
         root.windows = newWindows;
    }
    
    // Initial load
    Component.onCompleted: {
        if (isHyprland) {
            updateHyprlandWindows();
        } else {
            updateGenericWindows();
        }
    }
    
    // Generic/DWL Support
    // Since standard protocols don't give us window lists easily, 'windows' will remain empty.
    // Mousemover will simply render empty workspaces.
}
