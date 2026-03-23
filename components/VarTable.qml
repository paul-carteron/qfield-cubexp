import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtCore
import org.qfield
import Theme

Rectangle {
    id: root
    anchors.fill: parent
    color: Theme.mainBackgroundColorSemiOpaque

    property var model
    property string prfMode: ""

    // safe space for drawers (tune if needed)
    property int drawerSide: 54

    // available screen width for the table
    property int availableWidth: Math.max(0, parent.width - drawerSide * 2)

    // computed table width: as small as possible, but never > availableWidth
    property int tableWidth: Math.min(gridLayout.implicitWidth, availableWidth)

    Item {
        id: tableContainer

        width: root.tableWidth
        height: gridLayout.implicitHeight
        anchors.centerIn: parent

        GridLayout {
            id: gridLayout
            anchors.fill: parent
            columns: 6
            rowSpacing: 6
            columnSpacing: 8

            // ===== TITLE =====
            Text {
                text: "PRF : " + root.prfMode
                font.bold: true
                font.pointSize: 12
                color: Theme.mainTextColor
                Layout.columnSpan: 6
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
            }

            // ===== HEADERS =====
            Text {
                text: "Ess."
                font.bold: true
                font.pointSize: 12
                color: Theme.mainTextColor

                // KEY: Essence is the only flexible column
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
            }

            Text { text: "Vtot"; font.bold: true; font.pointSize: 12; color: Theme.mainTextColor; Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter }
            Text { text: "Vu";   font.bold: true; font.pointSize: 12; color: Theme.mainTextColor; Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter }
            Text { text: "Vha";  font.bold: true; font.pointSize: 12; color: Theme.mainTextColor; Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter }
            Text { text: "Gha";  font.bold: true; font.pointSize: 12; color: Theme.mainTextColor; Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter }
            Text { text: "Nb";   font.bold: true; font.pointSize: 12; color: Theme.mainTextColor; Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter }

            // ===== DATA =====

            // Essence: flexible + elide
            Repeater {
                model: root.model
                delegate: Text {
                    text: essence
                    font.pointSize: 12
                    color: Theme.mainTextColor

                    Layout.row: index + 2
                    Layout.column: 0
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter

                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    clip: true
                }
            }

            // Numeric columns: NOT fillWidth => they keep minimal width
            Repeater {
                model: root.model
                delegate: Text {
                    text: totalVolume
                    font.pointSize: 12
                    color: Theme.mainTextColor
                    Layout.row: index + 2
                    Layout.column: 1
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Repeater {
                model: root.model
                delegate: Text {
                    text: volumeUnitaire
                    font.pointSize: 12
                    color: Theme.mainTextColor
                    Layout.row: index + 2
                    Layout.column: 2
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Repeater {
                model: root.model
                delegate: Text {
                    text: volumeHa
                    font.pointSize: 12
                    color: Theme.mainTextColor
                    Layout.row: index + 2
                    Layout.column: 3
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Repeater {
                model: root.model
                delegate: Text {
                    text: gha
                    font.pointSize: 12
                    color: Theme.mainTextColor
                    Layout.row: index + 2
                    Layout.column: 4
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Repeater {
                model: root.model
                delegate: Text {
                    text: effectif
                    font.pointSize: 12
                    color: Theme.mainTextColor
                    Layout.row: index + 2
                    Layout.column: 5
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}