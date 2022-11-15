import QtQuick 2.7
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Lomiri.Components 1.3
import Reddit 1.0

Page {
    property bool fetchingSubreddits: false
    property int requestID: 0

    header: PageHeader {
        contents: Item {
            anchors.fill: parent
            TextField {
                id: searchBar
                anchors.fill: parent
                anchors.topMargin: units.gu(1)
                anchors.bottomMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)

                onAccepted: {
                    fetchingSubreddits = true
                    cleanSearches()
                    requestID = Reddit.getSubreddits(searchBar.text)
                }
            }
        }
    }

    ProgressBar {
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        height: units.gu(2)
        indeterminate: true
        enabled: fetchingSubreddits
        visible: enabled
    }

    Connections {
        target: Reddit
        onSubredditRequest: {
            if(id == requestID) {
                print("got subreddit request")
                var subredditSearchEntryComponent = Qt.createComponent("SubredditSearchEntry.qml");
                if(subredditSearchEntryComponent.status !== Component.Ready) {
                    console.log("Error loading component: ", subredditSearchEntryComponent.errorString());
                    return;
                }
                for(let i = 0; i < subreddits.length; i++) {
                    var subredditSearchEntryObject = subredditSearchEntryComponent.createObject(subredditSearchParent, {
                                                                       "subreddit": subreddits[i]
                                                                   } );
                }
                fetchingSubreddits = false
            }
        }
    }

    QtQuick.Frame {
        id: postsFrame
        anchors.fill: parent
        anchors.topMargin: header.height
        ScrollView {
            anchors.fill: parent
            id: scrollView

            ColumnLayout {
                width: postsFrame.availableWidth
                id: subredditSearchParent
                spacing: units.gu(1)
            }
        }
    }

    function cleanSearches() {
        for(let i = subredditSearchParent.children.length; i > 0; i--) {
            subredditSearchParent.children[i - 1].destroy()
        }
    }
}
