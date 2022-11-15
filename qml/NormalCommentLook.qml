import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

import Reddit 1.0

RowLayout {
    property var _commentChild
    property int _commentDepth: 0

    property var colorArray: [ "darkgreen", "darkblue", "darkred" ]

    Layout.fillWidth: true


    Repeater {
        model: _commentDepth
        delegate: Rectangle {
            Layout.fillHeight: true
            width: units.gu(0.3)
            //Layout.leftMargin: units.gu(0.1)
            color: colorArray[index % 3]
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: "u/" + _commentChild.author
                textSize: Label.Small
            }

            Label {
                text: _commentChild.author_flair_text
                textSize: Label.Small
                Layout.fillWidth: true
                maximumLineCount: 1
                wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                elide: Label.ElideRight
            }
        }
        Label {
            text: _commentChild.body_html
            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
            Layout.fillWidth: true

            textFormat: Label.RichText

            onLinkActivated: Qt.openUrlExternally(link)
        }
        Item {
            Layout.preferredHeight: units.gu(0.2)
        }
        VoteLook {
            score: _commentChild.score
            fullname: _commentChild.name
            hasBeenUpvoted: _commentChild.upvoted
            hasBeenDownvoted: _commentChild.downvoted
        }
        Item {
            Layout.preferredHeight: units.gu(0.2)
        }
    }
}
