import QtQuick 2.7
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3 as Popups
import Reddit 1.0

Page {
    id: mainPostsPage

    property string subreddit : ""
    property string sortingString : "/best"
    property string listingAfter : ""
    property int postsRequestID : 0

    property bool fetchingPosts : false

    property string subredditForFetching : subreddit // + sortingString

    property string search : ""

    anchors.fill: parent

    header: PageHeader {
        id: header
        title: subreddit.startsWith("r/") ? subreddit : i18n.tr("Front Page") + subreddit;
        subtitle: sortingString
        trailingActionBar.actions: [
            Action {
                text: i18n.tr("Sort by...")
                onTriggered: {
                    Popups.PopupUtils.open(dialogComponent)
                }
            }

        ]

        trailingActionBar.numberOfSlots: 0

        contents: Item {
            anchors.fill: parent
            TextField {
                id: searchBar
                anchors.fill: parent
                anchors.topMargin: units.gu(1)
                anchors.bottomMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)

                text: search

                onAccepted: {
                    search = searchBar.text
                    refetchPosts()
                }
            }
        }
    }

    // Sorting popup dialog
    Component {
        id: dialogComponent
        Popups.Dialog {
            id: dialog
            title: i18n.tr("Sort by...");
            text: i18n.tr("Select sorting method");

            Button {
                text: "Best"
                onClicked: {
                    sortingString = "best"
                    Popups.PopupUtils.close(dialog)
                }
            }
            Button {
                text: "Hot"
                onClicked: {
                    sortingString = "hot"
                    Popups.PopupUtils.close(dialog)
                }
            }
            Button {
                text: "Top"
                onClicked: {
                    sortingString = "top"
                    Popups.PopupUtils.close(dialog)
                }
            }
            Button {
                text: "New"
                onClicked: {
                    sortingString = "new"
                    Popups.PopupUtils.close(dialog)
                }
            }
            Button {
                text: "Rising"
                onClicked: {
                    sortingString = "rising"
                    PopupUtils.close(dialog)
                }
            }
        }
    }

    function cleanPosts() {
        for(let i = redditPostParent.children.length; i > 0; i--) {
            redditPostParent.children[i - 1].destroy()
        }
    }

    function refetchPosts() {
        cleanPosts()
        postsRequestID = Reddit.getPostsWithSearch(subredditForFetching, sortingString, search)
        fetchingPosts = true
    }

    onSortingStringChanged: refetchPosts()

    Connections {
        target: Reddit
        onPostsRequest: {
            if(id == postsRequestID) {
                print("got our post request")
                var redditPostComponent = Qt.createComponent("RedditPost.qml");
                if(redditPostComponent.status !== Component.Ready) {
                    print("Error loading reddit pot component: " + redditPostComponent.errorString())
                    return;
                }

                for(let i = 0; i < postListing.children.length; i++) {
                    var redditPostObject = redditPostComponent.createObject(redditPostParent, { "postChild": postListing.children[i] })
                }
                listingAfter = postListing.after
                fetchingPosts = false
                postsRequestID = 0
            }
        }
    }

    QtQuick.Frame {
        id: postsFrame
        anchors.fill: parent
        anchors.topMargin: header.height
        height: root.height - header.height
        ScrollView {
            anchors.fill: parent
            id: scrollView

            flickableItem.onAtYEndChanged:   {
                if(flickableItem.atYEnd && !fetchingPosts && listingAfter !== "") {
                    postsRequestID = Reddit.getMorePosts(subredditForFetching, sortingString, listingAfter)
                    fetchingPosts = true
                }
            }

            ColumnLayout {
                width: postsFrame.availableWidth
                //width: root.width
                id: redditPostParent
                spacing: units.gu(1)
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
        enabled: fetchingPosts
        visible: enabled
    }
}
