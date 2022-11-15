import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

import Reddit 1.0


RowLayout {
    property var subreddit

    property string subredditName: subreddit.display_name_prefixed
    property string iconURL: subreddit.icon_img

    Layout.fillWidth: true

    Image {
        source: iconURL
        Layout.preferredWidth: units.gu(2)
        Layout.preferredHeight: Layout.preferredWidth
    }

    Label {
        text: subreddit.display_name_prefixed
        elide: Label.ElideRight
        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
        Layout.fillWidth: true
    }
}
