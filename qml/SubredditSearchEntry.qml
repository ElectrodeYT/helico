import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

import Reddit 1.0


ColumnLayout {
    property var subreddit

//    width: subredditSearchEntryLook.width
//    height: subredditSearchEntryLook.height

    Layout.fillWidth: true

    SubredditSearchEntryLook {
        id: subredditSearchEntryLook
        subreddit: parent.subreddit
        Layout.fillWidth: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            print("should open subreddit ", subreddit)
            var mainPostsPageComponent = Qt.createComponent("MainPostsPage.qml");
            if(mainPostsPageComponent.status !== Component.Ready) {
                console.log("Error loading component: ", mainPostsPageComponent.errorString());
                return;
            }
            var mainPostsPageObject = mainPostsPageComponent.createObject(null, {
                                                               "subreddit": subredditSearchEntryLook.subredditName
                                                           } );
            pageStack.push(mainPostsPageObject);
        }
    }
}
