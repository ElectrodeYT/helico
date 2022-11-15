import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

import Reddit 1.0

QtQuick.Frame {
    property string flairText
    property string boxBorderColour

    property int maximumWidth

    leftPadding: units.gu(1) / 2
    rightPadding: units.gu(1) / 2
    topPadding: units.gu(1) / 2
    bottomPadding: units.gu(1) / 2

    background: Rectangle {
        color: "transparent"
        border.color: boxBorderColour
        radius: units.gu(1)
    }

    Label {
        text: flairText
        textSize: Label.Small
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        maximumLineCount: 3
        anchors.fill: parent
    }
}
