import QtQuick 2.7
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtGraphicalEffects 1.0
import Lomiri.Components 1.3
import Reddit 1.0

Page {
    property var postChild
    property var exactPostChild


    property string usedText: "default usedtext"

    property bool fetchingComments: true
    property int commentsRequestId: 0

    property bool hasBeenUpvoted
    property bool hasBeenDownvoted

    property var voteObject: openedRedditPostVote

    anchors.fill: parent

    id: openedRedditPostPage

    Component.onCompleted: {
        usedText = postChild.selftext_html
        print("new selftext: ", usedText)

        // Fetching comments
        commentsRequestId = Reddit.getComments(postChild.id)
    }

    header: PageHeader {
        id: header
        title: postChild.title
    }

    // Add a comment
    function addComment(comment, depth) {
//        if(comment.isMore) {
//            if(comment.count === 0) { return; }
//            moreComp.createObject(redditCommentParent, {
//                                      "commentChild": comment,
//                                      "commentDepth": depth
//                                  })
//        } else {
//            comp.createObject(redditCommentParent, {
//                                  "commentChild": comment,
//                                  "commentDepth": depth
//                              })
//            for(let i = 0; i < comment.replies.length; i++) {
//                addComment(comment.replies[i], depth + 1, comp, moreComp)
//            }
//        }
        if(comment.isMore && comment.count === 0) { return; }

        commentModel.append({
                                "commentChild": comment,
                                "commentDepth": depth
                            }
                                )
        // print("appended")
        if(!comment.isMore) {
            for(let i = 0; i < comment.replies.length; i++) {
                addComment(comment.replies[i], depth + 1)
            }
        }
    }

    Connections {
        target: Reddit
        onCommentsRequest: {
            if(id == commentsRequestId) {
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
            ColumnLayout {
                width: postsFrame.availableWidth
                id: redditPostParent
                spacing: units.gu(1)

                RedditPostLook {
                    postChild: openedRedditPostPage.postChild
                    displayTextPreview: false
                    limitTextLength: false
                    acceptImageClicks: true
                    enableFlairMouseArea: true
                }

                // The actual post itself
                Label {
                    Layout.fillWidth: true
                    enabled: usedText != ""
                    visible: enabled
                    width: parent.availableWidth
                    text: usedText
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                    textFormat: Label.RichText

                    onLinkActivated: Qt.openUrlExternally(link)
                }

                VoteLook {
                    id: openedRedditPostVote

                    score: postChild.score
                    fullname: postChild.name
                }

                QtQuick.ToolSeparator {
                    orientation: Qt.Horizontal
                    Layout.fillWidth: true
                }

                Label {
                    Layout.fillWidth: true
                    text: postChild.num_comments + " " + i18n.tr("comments:")
                }

                ListView {
                    id: redditCommentParent
                    Layout.fillWidth: true
                    Layout.preferredHeight: childrenRect.height

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
                                    commentLook = redditCommentParent.moreCommentLookComponent.createObject(commentWrapper, {_commentChild: commentChild, _commentDepth: commentDepth, width: commentWrapper.width, linkID: postChild.name})
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

    ProgressBar {
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        height: units.gu(2)
        indeterminate: true
        enabled: fetchingComments
        visible: enabled
    }
}
