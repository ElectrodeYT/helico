import QtQuick 2.7
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3 as Popups
import Reddit 1.0

Page {
    id: searchPostsPage

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
                text: i18n.tr("Best")
                onClicked: {
                    sortingString = "best"
                    Popups.PopupUtils.close(dialog)
                }
            }
            Button {
                text: i18n.tr("Hot")
                onClicked: {
                    sortingString = "hot"
                    Popups.PopupUtils.close(dialog)
                }
            }
            Button {
                text: i18n.tr("Top")
                onClicked: {
                    sortingString = "top"
                    Popups.PopupUtils.close(dialog)
                }
            }
            Button {
                text: i18n.tr("New")
                onClicked: {
                    sortingString = "new"
                    Popups.PopupUtils.close(dialog)
                }
            }
            Button {
                text: i18n.tr("Rising")
                onClicked: {
                    sortingString = "rising"
                    PopupUtils.close(dialog)
                }
            }
        }
    }

    function cleanPosts() {
        for(let i = postsModel.count; i >= 0; i--) {
            postsModel.remove(i)
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
            if(id === postsRequestID) {
                print("got our post request")
                for(let i = 0; i < postListing.children.length; i++) {
                    searchPostsModel.append({"_postChild": postListing.children[i]})
                }

                listingAfter = postListing.after
                fetchingPosts = false
                postsRequestID = 0
            }
        }
    }


    ListView {
        anchors.fill: parent
        anchors.topMargin: header.height

        anchors.leftMargin: units.gu(1)
        anchors.rightMargin: units.gu(1)

        id: redditPostParent
        spacing: units.gu(1)

        Layout.maximumWidth: width

        maximumFlickVelocity: units.gu(500)

        onAtYEndChanged: {
            if(atYEnd && !fetchingPosts && listingAfter !== "") {
                postsRequestID = Reddit.getMorePosts(subredditForFetching, sortingString, sortingTimeString, listingAfter)
                fetchingPosts = true
            }
        }

        onWidthChanged: {
            print("postscontainer width: " + width)
        }

        model: ListModel {
            id: searchPostsModel
            dynamicRoles: true
        }

        clip: true

        Component {
            id: redditPostDelegate
            RedditPost {
                width: ListView.view.width
                postChild: _postChild
                inView: true
            }
        }

        delegate: redditPostDelegate

        PullToRefresh {
            refreshing: fetchingPosts
            onRefresh: refetchPosts();
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
