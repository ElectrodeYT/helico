import QtQuick 2.7
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Lomiri.Components 1.3
import Reddit 1.0

Page {
    id: subredditSearchPage

    property bool fetchingSubreddits: false
    property int requestID: 0

    header: PageHeader {
        id: header
        contents: Item {
            anchors.fill: parent
            TextField {
                id: searchBar
                anchors.fill: parent
                anchors.topMargin: units.gu(1)
                anchors.bottomMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)

                onAccepted: fetchSubreddits()
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
                for(let i = 0; i < subreddits.length; i++) {
                    subredditsModel.append({"_subreddit": subreddits[i]});
                }
                fetchingSubreddits = false
            }
        }
    }

    ListView {
        anchors.fill: parent
        anchors.topMargin: header.height

        anchors.leftMargin: units.gu(1)
        anchors.rightMargin: units.gu(1)

        id: scrollView
        spacing: units.gu(1)

        Layout.maximumWidth: width

        maximumFlickVelocity: units.gu(500)

        model: ListModel {
            id: subredditsModel
            dynamicRoles: true
        }

        clip: true

        Component {
            id: subredditDelegate
            SubredditSearchEntry {
                width: ListView.view.width
                subreddit: _subreddit
            }
        }

        delegate: subredditDelegate

        PullToRefresh {
            refreshing: fetchingSubreddits
            onRefresh: fetchSubreddits();
        }
    }

    function cleanSearches() {
        for(let i = subredditsModel.count; i >= 0; i--) {
            subredditsModel.remove(i)
        }
    }

    function fetchSubreddits() {
        cleanSearches()
        fetchingSubreddits = true
        requestID = Reddit.getSubreddits(searchBar.text)
    }
}
