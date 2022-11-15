import QtQuick 2.7
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtGraphicalEffects 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3 as Popups
import Reddit 1.0


// The vote stuff
// TODO: put this into a QML object, repeating this isnt very good
RowLayout {
    property bool hasBeenUpvoted
    property bool hasBeenDownvoted

    property int score: 0
    property string fullname: ""

    property var otherVoteObject

    function pageUpvote() {
        if(hasBeenUpvoted) {
            hasBeenUpvoted = false
            Reddit.setVote(fullname, 0)
        } else if(hasBeenDownvoted) {
            hasBeenDownvoted = false;
            hasBeenUpvoted = true;
            Reddit.setVote(fullname, 1)
        } else {
            hasBeenUpvoted = true;
            Reddit.setVote(fullname, 1)
        }
    }

    function pageDownvote() {
        if(hasBeenDownvoted) {
            hasBeenDownvoted = false;
            Reddit.setVote(fullname, 0)
        } else if(hasBeenUpvoted) {
            hasBeenUpvoted = false;
            hasBeenDownvoted = true;
            Reddit.setVote(fullname, -1)
        } else {
            hasBeenDownvoted = true;
            Reddit.setVote(fullname, -1)
        }
    }

    function openErrorPopup() {
        Popups.PopupUtils.open(voteErrorDialogComponent)
    }

    Component {
        id: voteErrorDialogComponent
        Popups.Dialog {
            id: voteErrorDialog
            title: "Log in"
            text: "To vote, you must be logged in. To log in, go to the main page, and select \"Login\" from the top right action menu."

            Button {
                text: "OK"
                onClicked: {
                    Popups.PopupUtils.close(voteErrorDialog)
                }
            }
        }
    }


    // A bunch of signals to get allow the upvotes to update here as well
    signal upvoteSignal()
    signal downvoteSignal()

    onUpvoteSignal: {
        console.log("got upvote signal")
        hasBeenUpvoted = otherVoteObject.hasBeenUpvoted
    }

    onDownvoteSignal: {
        console.log("got downvote signal")
        hasBeenDownvoted = otherVoteObject.hasBeenDownvoted
    }

    Layout.alignment: Qt.AlignLeft
    Layout.maximumHeight: units.gu(2)
    // Upvote button
    Item {
        Layout.maximumWidth: units.gu(2)
        Layout.maximumHeight: units.gu(2)
        Layout.preferredWidth: units.gu(2)
        Layout.preferredHeight: units.gu(2)

        Image {
            source: "qrc:/assets/arrow.svg"
            anchors.fill: parent
            rotation: -90
            id: upvoteImage
            visible: false
        }

        ColorOverlay {
            anchors.fill: upvoteImage
            source: upvoteImage
            rotation: -90
            color: hasBeenUpvoted ? "red" : "darkred"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                console.log("upvote")
                if(!settings.hasLoggedIn) {
                    openErrorPopup()
                    return
                }
                pageUpvote()
            }
            z: 9999
            propagateComposedEvents: false
        }
    }

    // Page score
    Label {
        text: (score + (hasBeenUpvoted ? 1 : 0) - (hasBeenDownvoted ? 1 : 0)).toString()
    }

    // Downvote button
    Item {
        Layout.maximumWidth: units.gu(2)
        Layout.maximumHeight: units.gu(2)
        Layout.preferredWidth: units.gu(2)
        Layout.preferredHeight: units.gu(2)

        Image {
            source: "qrc:/assets/arrow.svg"
            anchors.fill: parent
            rotation: 90
            id: downVoteImage
            visible: false
        }

        ColorOverlay {
            anchors.fill: downVoteImage
            source: downVoteImage
            rotation: 90
            color: hasBeenDownvoted ? "aqua" : "midnightblue"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                console.log("downvote")
                if(!settings.hasLoggedIn) {
                    openErrorPopup()
                    return
                }
                pageDownvote()
            }
            z: 9999
            propagateComposedEvents: false
        }
    }
}
