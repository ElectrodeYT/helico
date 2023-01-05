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

    property string sortingString : "best"
    property string sortingTimeString : ""

    property string listingAfter : ""
    property int postsRequestID : 0

    property bool fetchingPosts : false

    property string subredditForFetching : subreddit

    anchors.fill: parent

    onWidthChanged: {
        print("mainPostsPage width: " + width)
    }

    header: PageHeader {
        id: header
        title: subreddit.startsWith("r/") ? subreddit : i18n.tr("Front Page") + subreddit;
        subtitle: sortingString + (sortingString == "top" ? (", " + sortingTimeString) : "")
        trailingActionBar.actions: [
            Action {
                iconName: "find"
                text: i18n.tr("Search Subreddits...")
                onTriggered: {
                    pageStack.push(Qt.resolvedUrl("SubredditSearchPage.qml"))
                }
            },
            Action {
                iconName: "find"
                text: i18n.tr("Search Posts...")
                onTriggered: {
                    var searchPostsPageComponent = Qt.createComponent("SearchPostsPage.qml");
                    if(searchPostsPageComponent.status !== Component.Ready) {
                        console.log("Error loading component: ", searchPostsPageComponent.errorString());
                        return;
                    }
                    var searchPostsPageObject = searchPostsPageComponent.createObject(null, {
                                                                       "subreddit": subreddit
                                                                   } );
                    pageStack.push(searchPostsPageObject);
                }
            },
            Action {
                text: i18n.tr("Sort by...")
                onTriggered: {
                    Popups.PopupUtils.open(dialogComponent)
                }
            },
            Action {
                text: i18n.tr("About")
                onTriggered: {
                    pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                }
            },
            Action {
                text: settings.hasLoggedIn ? i18n.tr("Logout") : i18n.tr("Login")
                onTriggered: {
                    if(settings.hasLoggedIn) {
                        // Trigger logout
                        Reddit.triggerLogout();
                    } else {
                        // Trigger login
                        Reddit.loginToReddit();
                    }
                }
            }

        ]

        trailingActionBar.numberOfSlots: 0
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
                    sortingTimeString = ""
                    refetchPosts()
                    Popups.PopupUtils.close(dialog)
                }
            }
            Button {
                text: "Hot"
                onClicked: {
                    sortingString = "hot"
                    sortingTimeString = ""
                    refetchPosts()
                    Popups.PopupUtils.close(dialog)
                }
            }
            Button {
                text: "Top"
                onClicked: {
                    sortingString = "top"
                    sortingTimeString = ""
                    Popups.PopupUtils.close(dialog)
                    Popups.PopupUtils.open(sortingTimeDialogComponent)
                }
            }
            Button {
                text: "New"
                onClicked: {
                    sortingString = "new"
                    sortingTimeString = ""
                    refetchPosts()
                    Popups.PopupUtils.close(dialog)
                }
            }
            Button {
                text: "Rising"
                onClicked: {
                    sortingString = "rising"
                    sortingTimeString = ""
                    refetchPosts()
                    Popups.PopupUtils.close(dialog)
                }
            }
        }
    }

    Component {
        id: sortingTimeDialogComponent
        Popups.Dialog {
            id: sortingTimeDialog
            title: i18n.tr("Sort by...");
            Button {
                text: "Hour"
                onClicked: {
                    sortingTimeString = "hour"
                    Popups.PopupUtils.close(sortingTimeDialog)
                    refetchPosts()
                }
            }
            Button {
                text: "Day"
                onClicked: {
                    sortingTimeString = "day"
                    Popups.PopupUtils.close(sortingTimeDialog)
                    refetchPosts()
                }
            }
            Button {
                text: "Week"
                onClicked: {
                    sortingTimeString = "week"
                    Popups.PopupUtils.close(sortingTimeDialog)
                }
            }
            Button {
                text: "Month"
                onClicked: {
                    sortingTimeString = "month"
                    Popups.PopupUtils.close(sortingTimeDialog)
                    refetchPosts()
                }
            }
            Button {
                text: "Year"
                onClicked: {
                    sortingTimeString = "year"
                    Popups.PopupUtils.close(sortingTimeDialog)
                    refetchPosts()
                }
            }
            Button {
                text: "All Time"
                onClicked: {
                    sortingTimeString = "all"
                    Popups.PopupUtils.close(sortingTimeDialog)
                    refetchPosts()
                }
            }
        }
    }

    Component.onCompleted: {
        refetchPosts()
    }

    function cleanPosts() {
        for(let i = postsModel.count; i >= 0; i--) {
            postsModel.remove(i)
        }
    }

    function refetchPosts() {
        cleanPosts()
        postsRequestID = Reddit.getPosts(subredditForFetching, sortingString, sortingTimeString)
        fetchingPosts = true
    }

    Connections {
        target: Reddit
        onPostsRequest: {
            if(id === postsRequestID) {
                print("got our post request")
                var redditPostComponent = Qt.createComponent("RedditPost.qml");
                if(redditPostComponent.status !== Component.Ready) {
                    print("Error loading reddit post component: " + redditPostComponent.errorString())
                    return;
                }
                /*
                for(let i = 0; i < postListing.children.length; i++) {
                    var redditPostObject = redditPostComponent.createObject(redditPostParent, { "postChild": postListing.children[i] })
                }
                */

                for(let i = 0; i < postListing.children.length; i++) {
                    postsModel.append({"_postChild": postListing.children[i]})
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

        onContentYChanged:   {
            //if(flickableItem.atYEnd && !fetchingPosts && listingAfter !== "") {
            if(contentY === contentHeight - height && !fetchingPosts && listingAfter !== "") {
                postsRequestID = Reddit.getMorePosts(subredditForFetching, sortingString, sortingTimeString, listingAfter)
                fetchingPosts = true
            }
        }

        onWidthChanged: {
            print("postscontainer width: " + width)
        }

        model: ListModel {
            id: postsModel
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
