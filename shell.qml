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
    readonly property int cornerRadius: 12
    readonly property color panelColor: "#202020"
    readonly property color borderColor: "#383838"
    readonly property color rowHighlight: "#2d2d2d"
    readonly property color boxColor: "#1a1a1a"
    readonly property color textColor: "#ffffff"
    readonly property color subTextColor: "#9a9a9a"
    readonly property string placeholder: "Search"
    readonly property string typeLabel: "App"
    // ====================================================

    property bool open: false
    property var history: ({})   // desktop entry id -> last launched (ms since epoch)

    readonly property string stateDir:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quicksearch"

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

    function launch(entry) {
        entry.execute()
        const h = Object.assign({}, root.history)
        h[entry.id] = Date.now()
        root.history = h
        histFile.setText(JSON.stringify(h))
        root.open = false
    }

    // Control from a terminal or shortcut:
    //   qs -c quicksearch ipc call launcher toggle
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
            if (visible) {
                field.text = ""
                field.forceActiveFocus()
            }
        }

        property var results: {
            const q = field.text.toLowerCase()
            const apps = Array.from(DesktopEntries.applications.values)
                .filter(a => !a.noDisplay)

            if (q === "") {
                return apps
                    .filter(a => root.history[a.id] !== undefined)
                    .sort((a, b) => root.history[b.id] - root.history[a.id])
                    .slice(0, root.maxResults)
            }

            const starts = apps.filter(a => a.name.toLowerCase().startsWith(q))
            const contains = apps.filter(a => {
                const n = a.name.toLowerCase()
                return !n.startsWith(q) && n.includes(q)
            })
            return starts.concat(contains).slice(0, root.maxResults)
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
                            TapHandler { onTapped: root.launch(modelData) }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                spacing: 14

                                Image {
                                    source: Quickshell.iconPath(modelData.icon, true)
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
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
                                            ? root.timeAgo(root.history[modelData.id]) + " \u2022 " + root.typeLabel
                                            : root.typeLabel
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
                        text: field.text === "" ? "Start typing to search apps" : "No results"
                        color: root.subTextColor
                        font.pixelSize: 14
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.searchBoxHeight
                    radius: 8
                    color: root.boxColor
                    border.color: root.borderColor

                    TextInput {
                        id: field
                        anchors.fill: parent
                        anchors.margins: 16
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

                        Keys.onEscapePressed: root.open = false
                        Keys.onDownPressed: list.currentIndex = Math.min(list.currentIndex + 1, list.count - 1)
                        Keys.onUpPressed: list.currentIndex = Math.max(list.currentIndex - 1, 0)
                        Keys.onReturnPressed: launchSelected()
                        Keys.onEnterPressed: launchSelected()

                        function launchSelected() {
                            if (win.results.length > 0)
                                root.launch(win.results[list.currentIndex])
                        }
                    }
                }
            }
        }
    }
}
