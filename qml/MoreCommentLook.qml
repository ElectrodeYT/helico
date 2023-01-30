import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

import Reddit 1.0

RowLayout {
    property var commentChild: _commentChild
    property int commentDepth: _commentDepth

    property var colorArray: [ "darkgreen", "darkblue", "darkred" ]

    property bool currentlyFetchingMoreComments: false

    property bool requiresContinueThread: commentChild.children.length === 0 || commentChild.count === 0

    // The Reddit Link ID
    // Always the fullname of the RedditPost
    property string linkID: ""

    id: moreComment

    Layout.fillWidth: true



    Repeater {
        model: commentDepth
        delegate: Rectangle {
            Layout.fillHeight: true
            width: units.gu(0.3)
            //Layout.leftMargin: units.gu(0.1)
            color: colorArray[index % 3]
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Item {
            Layout.preferredHeight: units.gu(0.4)
        }

        Label {
            text: requiresContinueThread ? "Continue this thread" : commentChild.count + " " + i18n.tr("more comments...");
            textSize: Label.Small
            Layout.fillWidth: true

            enabled: !currentlyFetchingMoreComments
            visible: enabled

            MouseArea {
                width: parent.width
                height: parent.height
                onClicked: openMoreCommentsPage()
                z: 2000
            }
        }

        Item {
            Layout.preferredHeight: units.gu(0.4)
        }
    }

    function openMoreCommentsPage() {
        print("should open comment from author ", postChild.author)
        var moreCommentPageComponent = Qt.createComponent("MoreCommentsPage.qml");
        if(moreCommentPageComponent.status !== Component.Ready) {
            console.log("Error loading component: ", moreCommentPageComponent.errorString());
            return;
        }
        var moreCommentPageObject = moreCommentPageComponent.createObject(null, {
                                                           "topCommentChild": commentChild,
                                                           "linkID": linkID
                                                       } );
        pageStack.push(moreCommentPageObject);
    }
}
