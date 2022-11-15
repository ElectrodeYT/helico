import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtGraphicalEffects 1.0

import Reddit 1.0


ColumnLayout {
    id: postTopItem

    //Layout.alignment: Qt.AlignLeft

    Layout.fillWidth: true

    property var postChild
    property bool inView: ((scrollView.flickableItem.contentY + scrollView.height) > (y - units.gu(24))) && (scrollView.flickableItem.contentY < (y + height + units.gu(24)))

    property bool _autoPlayVideo: ((scrollView.flickableItem.contentY + scrollView.height) > (y + units.gu(4))) && (scrollView.flickableItem.contentY < (y + height - units.gu(4)))

    onWidthChanged: {
        print("reddit post \"" + postChild.title + "\" width: " + width)
    }
    /*
    QtQuick.ToolSeparator {
        orientation: Qt.Horizontal
        Layout.fillWidth: true
        z: -999
    }
    */

    Item {
        Layout.preferredHeight: units.gu(1)
    }

    RedditPostLook {
        Layout.fillWidth: true

        postChild: parent.postChild
        inView: parent.inView

        autoPlayVideo: _autoPlayVideo

        MouseArea {
            width: parent.width
            height: parent.height
            //anchors.fill: parent

            // This is to make it so that the vote buttons are clickable
            //anchors.bottomMargin: units.gu(2)

            onClicked: openPost()
            z: 2000
        }
    }

    VoteLook {
        id: redditPostVote

        score: postChild.score
        fullname: postChild.name
    }

    property var openRedditPostObject

    function openPost() {
        print("should open post with name ", postChild.name)
        var openRedditPostComponent = Qt.createComponent("OpenedRedditPost.qml");
        if(openRedditPostComponent.status !== Component.Ready) {
            console.log("Error loading component: ", openRedditPostComponent.errorString());
            return;
        }
        openRedditPostObject = openRedditPostComponent.createObject(null, {
                                                           "postChild": postChild,
                                                       } );
        openRedditPostObject.voteObject.hasBeenUpvoted = redditPostVote.hasBeenUpvoted
        openRedditPostObject.voteObject.hasBeenDownvoted = redditPostVote.hasBeenDownvoted

        openRedditPostObject.voteObject.hasBeenUpvotedChanged.connect(redditPostVote.upvoteSignal)
        openRedditPostObject.voteObject.hasBeenDownvotedChanged.connect(redditPostVote.downvoteSignal)

        redditPostVote.otherVoteObject = openRedditPostObject.voteObject
        pageStack.push(openRedditPostObject);
    }
}
