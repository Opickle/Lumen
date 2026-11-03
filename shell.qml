import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    // ===================== SETTINGS =====================
    // Edit these to change how the launcher looks.
    readonly property int panelWidth: 500
    readonly property int bottomMargin: 60
    readonly property int maxResults: 7
    readonly property int rowHeight: 60
    readonly property int searchBoxHeight: 80
    readonly property int powerButtonSize: 48
    readonly property int animationMs: 260   // power menu animation speed (ms)
    readonly property int cornerRadius: 12
    readonly property color panelColor: "#202020"
    readonly property color borderColor: "#383838"
    readonly property color rowHighlight: "#2d2d2d"
    readonly property color boxColor: "#1a1a1a"
    readonly property color menuColor: "#2b2b2b"
    readonly property color textColor: "#ffffff"
    readonly property color subTextColor: "#9a9a9a"
    readonly property string placeholder: "Search"
    readonly property string typeLabel: "App"
    readonly property string actionLabel: "Action"

    // ---------------- QUICK ACTIONS ----------------
    // Type any of the words below (e.g. "mute", "max brightness") and the
    // action shows up in the results. Press Enter to run it.
    //   name     - what is shown in the list
    //   keywords - extra words that find it (all typed words must match)
    //   icon     - icon theme name (a letter badge is used if it is missing)
    //   cmd      - the command to run, as a list: program first, then arguments
    readonly property var actions: [
        { name: "Mute / unmute volume", icon: "audio-volume-muted",
          keywords: ["mute", "unmute", "silent", "sound", "audio"],
          cmd: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] },
        { name: "Max volume", icon: "audio-volume-high",
          keywords: ["max", "maximum", "full", "loud", "sound", "audio"],
          cmd: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "1.0"] },
        { name: "Volume up", icon: "audio-volume-high",
          keywords: ["louder", "increase", "raise", "sound", "audio"],
          cmd: ["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+"] },
        { name: "Volume down", icon: "audio-volume-low",
          keywords: ["quieter", "decrease", "lower", "sound", "audio"],
          cmd: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"] },
        { name: "Mute / unmute microphone", icon: "microphone-sensitivity-muted",
          keywords: ["mic", "microphone", "mute", "unmute"],
          cmd: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"] },
        { name: "Max brightness", icon: "video-display",
          keywords: ["maximum", "full", "bright", "screen"],
          cmd: ["brightnessctl", "set", "100%"] },
        { name: "Min brightness", icon: "video-display",
          keywords: ["minimum", "lowest", "dim", "dark", "screen"],
          cmd: ["brightnessctl", "set", "1%"] },
        { name: "Brightness up", icon: "video-display",
          keywords: ["increase", "brighter", "bright", "screen"],
          cmd: ["brightnessctl", "set", "10%+"] },
        { name: "Brightness down", icon: "video-display",
          keywords: ["decrease", "dimmer", "dim", "screen"],
          cmd: ["brightnessctl", "set", "10%-"] },
        { name: "Lock screen", icon: "system-lock-screen",
          keywords: ["lock"],
          cmd: ["loginctl", "lock-session"] },
        { name: "Sleep", icon: "system-suspend",
          keywords: ["suspend"],
          cmd: ["systemctl", "suspend"] },
        { name: "Open File Explorer", icon: "system-file-manager",
          keywords: ["files", "folder", "dolphin", "explorer"],
          cmd: ["dolphin"] },
        { name: "Wi-Fi on", icon: "network-wireless",
          keywords: ["wifi", "wireless", "network", "enable"],
          cmd: ["nmcli", "radio", "wifi", "on"] },
        { name: "Wi-Fi off", icon: "network-wireless-disconnected",
          keywords: ["wifi", "wireless", "network", "disable"],
          cmd: ["nmcli", "radio", "wifi", "off"] },
        { name: "Bluetooth on", icon: "bluetooth",
          keywords: ["enable"],
          cmd: ["bluetoothctl", "power", "on"] },
        { name: "Bluetooth off", icon: "bluetooth-disabled",
          keywords: ["disable"],
          cmd: ["bluetoothctl", "power", "off"] }
    ]

    // Entries in the power menu (the round button next to the search box).
    readonly property var powerItems: [
        { label: "Lock",      cmd: ["loginctl", "lock-session"] },
        { label: "Sleep",     cmd: ["systemctl", "suspend"] },
        { label: "Log out",   cmd: ["dbus-send", "--session", "--type=method_call",
                                    "--dest=org.kde.Shutdown", "/Shutdown",
                                    "org.kde.Shutdown.logout"] },
        { label: "Restart",   cmd: ["systemctl", "reboot"] },
        { label: "Shut down", cmd: ["systemctl", "poweroff"] }
    ]
    // ====================================================

    property bool open: false
    property bool powerMenuOpen: false
    property var history: ({})   // item id -> last used (ms since epoch)

    readonly property string stateDir:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/lumen"

    // Make sure the folder for the history file exists.
    Process {
        command: ["mkdir", "-p", root.stateDir]
        running: true
    }

    function timeAgo(ms) {
        const mins = Math.floor((Date.now() - ms) / 60000)
        if (mins < 1) return "Just now"
        if (mins < 60) return mins + " min" + (mins === 1 ? "" : "s") + " ago"
        const hrs = Math.floor(mins / 60)
        if (hrs < 24) return hrs + " hour" + (hrs === 1 ? "" : "s") + " ago"
        const days = Math.floor(hrs / 24)
        return days + " day" + (days === 1 ? "" : "s") + " ago"
    }

    // Run a result: launch an app, or run a quick action's command.
    function activate(item) {
        if (item.kind === "app") item.entry.execute()
        else Quickshell.execDetached(item.cmd)

        const h = Object.assign({}, root.history)
        h[item.id] = Date.now()
        root.history = h
        histFile.setText(JSON.stringify(h))
        root.open = false
    }

    function runPower(cmd) {
        Quickshell.execDetached(cmd)
        root.powerMenuOpen = false
        root.open = false
    }

    // Control from a terminal or shortcut:
    //   qs -c lumen ipc call launcher toggle
    IpcHandler {
        target: "launcher"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
    }

    FileView {
        id: histFile
        path: root.stateDir + "/history.json"
        printErrors: false
        onLoaded: {
            try { root.history = JSON.parse(text()) } catch (e) {}
        }
    }

    PanelWindow {
        id: win
        visible: root.open
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        anchors.bottom: true
        margins.bottom: root.bottomMargin
        implicitWidth: root.panelWidth
        implicitHeight: root.rowHeight * root.maxResults + root.searchBoxHeight + 24

        onVisibleChanged: {
            root.powerMenuOpen = false
            if (visible) {
                field.text = ""
                field.forceActiveFocus()
            }
        }

        // Every result is a plain object: { kind, id, name, icon, label, entry | cmd }
        property var results: {
            const q = field.text.trim().toLowerCase()

            const apps = Array.from(DesktopEntries.applications.values)
                .filter(a => !a.noDisplay)
                .map(a => ({
                    kind: "app", id: a.id, name: a.name, icon: a.icon,
                    label: root.typeLabel, entry: a
                }))

            const acts = root.actions.map(a => ({
                kind: "action", id: "action:" + a.name, name: a.name, icon: a.icon,
                label: root.actionLabel, cmd: a.cmd, keywords: a.keywords || []
            }))

            // Empty search box: show recently used apps and actions.
            if (q === "") {
                return apps.concat(acts)
                    .filter(i => root.history[i.id] !== undefined)
                    .sort((a, b) => root.history[b.id] - root.history[a.id])
                    .slice(0, root.maxResults)
            }

            const words = q.split(/\s+/)
            const startsWith = apps.filter(i => i.name.toLowerCase().startsWith(q))
            const matchedActions = acts.filter(i => {
                const hay = (i.name + " " + i.keywords.join(" ")).toLowerCase()
                return words.every(w => hay.includes(w))
            })
            const contains = apps.filter(i => {
                const n = i.name.toLowerCase()
                return !n.startsWith(q) && n.includes(q)
            })
            return startsWith.concat(matchedActions, contains).slice(0, root.maxResults)
        }

        Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            color: root.panelColor
            border.color: root.borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        id: list
                        anchors.fill: parent
                        clip: true
                        model: win.results
                        currentIndex: 0
                        interactive: false

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: list.width
                            height: root.rowHeight
                            radius: 6
                            color: index === list.currentIndex || hover.hovered
                                ? root.rowHighlight : "transparent"

                            HoverHandler { id: hover }
                            TapHandler { onTapped: root.activate(modelData) }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                spacing: 14

                                // Icon, or a letter badge if the icon is not found
                                Item {
                                    id: iconBox
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    property string src: modelData.icon
                                        ? Quickshell.iconPath(modelData.icon, true) : ""

                                    Image {
                                        anchors.fill: parent
                                        source: iconBox.src
                                        sourceSize.width: 32
                                        sourceSize.height: 32
                                        visible: iconBox.src !== ""
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: root.rowHighlight
                                        visible: iconBox.src === ""
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.name.charAt(0)
                                            color: root.textColor
                                            font.pixelSize: 16
                                        }
                                    }
                                }

                                ColumnLayout {
                                    spacing: 2
                                    Text {
                                        text: modelData.name
                                        color: root.textColor
                                        font.pixelSize: 15
                                    }
                                    Text {
                                        text: field.text === ""
                                            ? root.timeAgo(root.history[modelData.id]) + " \u2022 " + modelData.label
                                            : modelData.label
                                        color: root.subTextColor
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: win.results.length === 0
                        text: field.text === "" ? "Start typing to search apps and actions" : "No results"
                        color: root.subTextColor
                        font.pixelSize: 14
                    }
                }

                // Search box with the power button on the right
                Rectangle {
                    id: searchBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.searchBoxHeight
                    radius: 8
                    color: root.boxColor
                    border.color: root.borderColor

                    TextInput {
                        id: field
                        anchors.left: parent.left
                        anchors.right: powerButton.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 16
                        anchors.rightMargin: 8
                        color: root.textColor
                        font.pixelSize: 15
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignTop

                        Text {
                            visible: field.text === ""
                            text: root.placeholder
                            color: root.subTextColor
                            font: field.font
                        }

                        onTextChanged: list.currentIndex = 0

                        Keys.onEscapePressed: {
                            if (root.powerMenuOpen) root.powerMenuOpen = false
                            else root.open = false
                        }
                        Keys.onDownPressed: list.currentIndex = Math.min(list.currentIndex + 1, list.count - 1)
                        Keys.onUpPressed: list.currentIndex = Math.max(list.currentIndex - 1, 0)
                        Keys.onReturnPressed: runSelected()
                        Keys.onEnterPressed: runSelected()

                        function runSelected() {
                            if (win.results.length > 0)
                                root.activate(win.results[list.currentIndex])
                        }
                    }

                    Rectangle {
                        id: powerButton
                        width: root.powerButtonSize
                        height: root.powerButtonSize
                        radius: width / 2
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        color: powerHover.hovered || root.powerMenuOpen
                            ? root.rowHighlight : "transparent"
                        border.color: root.borderColor

                        Behavior on color { ColorAnimation { duration: 120 } }

                        HoverHandler { id: powerHover }
                        TapHandler { onTapped: root.powerMenuOpen = !root.powerMenuOpen }

                        // Power symbol: open circle with a line at the top
                        Canvas {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.strokeStyle = root.textColor.toString()
                                ctx.lineWidth = 2
                                ctx.lineCap = "round"
                                ctx.beginPath()
                                ctx.arc(11, 12, 7.5, -Math.PI / 2 + 0.65, 3 * Math.PI / 2 - 0.65, false)
                                ctx.stroke()
                                ctx.beginPath()
                                ctx.moveTo(11, 3)
                                ctx.lineTo(11, 11)
                                ctx.stroke()
                            }
                        }
                    }
                }
            }

            // Power menu: grows out of the power button (and shrinks back into it)
            Item {
                id: powerMenu
                z: 10
                width: 190
                height: root.powerItems.length * 40 + 12

                // Right edge lines up with the power button, bottom sits just above it
                anchors.right: parent.right
                anchors.rightMargin: 8 + 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8 + (root.searchBoxHeight + root.powerButtonSize) / 2 + 8

                // 0 = closed (inside the button), 1 = fully open
                property real prog: root.powerMenuOpen ? 1 : 0
                Behavior on prog {
                    NumberAnimation { duration: root.animationMs; easing.type: Easing.OutCubic }
                }

                visible: prog > 0.001
                opacity: Math.min(1, prog * 1.6)

                // Scale around the centre of the power button
                transform: Scale {
                    origin.x: powerMenu.width - root.powerButtonSize / 2
                    origin.y: powerMenu.height + 8 + root.powerButtonSize / 2
                    xScale: 0.15 + 0.85 * powerMenu.prog
                    yScale: 0.15 + 0.85 * powerMenu.prog
                }

                Rectangle {
                    id: menuBody
                    anchors.fill: parent
                    radius: 8
                    color: root.menuColor
                    border.color: root.borderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 6

                        Repeater {
                            model: root.powerItems

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: menuBody.width - 12
                                height: 40
                                radius: 6
                                color: itemHover.hovered ? root.rowHighlight : "transparent"

                                // Items nearest the button appear first
                                property real delay: (root.powerItems.length - 1 - index) * 0.07
                                opacity: Math.max(0, Math.min(1, (powerMenu.prog - delay) / 0.45))

                                Behavior on color { ColorAnimation { duration: 100 } }

                                HoverHandler { id: itemHover }
                                TapHandler { onTapped: root.runPower(modelData.cmd) }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    color: root.textColor
                                    font.pixelSize: 14
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
