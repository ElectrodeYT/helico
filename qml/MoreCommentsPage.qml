import QtQuick 2.7
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtGraphicalEffects 1.0
import Lomiri.Components 1.3
import Reddit 1.0

Page {
    property var topCommentChild;

    property bool fetchingComments: true
    property int commentsRequestId: 0

    property int maximumCommentThreadsToFetch: 20

    // The Reddit Link ID
    // Always the fullname of the RedditPost
    property string linkID: ""

    anchors.fill: parent

    Component.onCompleted: {
        // Create list of comments to add
        var commentFetchArray = [];
        for(let i = 0; i < topCommentChild.children.length; i++) {
            if(i > maximumCommentThreadsToFetch) { break; }
            commentFetchArray.push(topCommentChild.children[i])
        }

        // Fetching comments
        commentsRequestId = Reddit.getMoreComments(linkID, commentFetchArray)

        // Add top comment
        commentModel.append({
                                "commentChild": topCommentChild,
                                "commentDepth": 0
                            })
    }

    header: PageHeader {
        id: header
    }

    // Add a comment
    function addComment(comment, depth) {
        if(comment.isMore && comment.count === 0) { return; }

        commentModel.append({
                                "commentChild": comment,
                                "commentDepth": depth
                            }
                                )
        if(!comment.isMore) {
            for(let i = 0; i < comment.replies.length; i++) {
                addComment(comment.replies[i], depth + 1)
            }
        }
    }

    Connections {
        target: Reddit
        onCommentsRequest: {
            if(id === commentsRequestId) {
                print("got our comment request")

                for(let i = 0; i < commentListing.comments.length; i++) {
                    addComment(commentListing.comments[i], 0)
                }

                commentsRequestId = 0
                fetchingComments = false
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
            ListView {
                id: redditCommentParent
        //        Layout.fillWidth: true
        //        Layout.preferredHeight: childrenRect.height

                maximumFlickVelocity: units.gu(500)

                model: ListModel {
                    id: commentModel
                    dynamicRoles: true
                }

                clip: true

                // Some components used by the comments
                property var normalCommentLookComponent
                property var moreCommentLookComponent

                Component.onCompleted: {
                    normalCommentLookComponent = Qt.createComponent("NormalCommentLook.qml");
                    moreCommentLookComponent = Qt.createComponent("MoreCommentLook.qml");
                }

                Component {
                    id: commentDelegate
                    Item {
                        id: commentWrapper
                        property var commentLook

                        height: commentLook.height
                        width: ListView.view.width
                        // property bool inView: ((ListView.view.contentY + ListView.view.height) > (y - units.gu(24))) && (ListView.view.contentY < (y + height + units.gu(24)))

                        /*onInViewChanged: {
                            if(commentChild.isMore) {
                                print("moreComment: " + inView)
                            } else {
                                print(commentChild.author + ": " + inView)
                            }
                        }*/

                        Component.onCompleted: {
                            if(commentChild.isMore) {
                                commentLook = redditCommentParent.moreCommentLookComponent.createObject(commentWrapper, {_commentChild: commentChild, _commentDepth: commentDepth, width: commentWrapper.width})
                            } else {
                                commentLook = redditCommentParent.normalCommentLookComponent.createObject(commentWrapper, {_commentChild: commentChild, _commentDepth: commentDepth, width: commentWrapper.width})
                            }
                        }
                    }
                }

                delegate: commentDelegate
            }
        }
    }
}
