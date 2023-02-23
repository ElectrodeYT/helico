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
        if(comment.isMore && comment.count === 0) { return; }

        commentModel.append({
                                "_commentChild": comment,
                                "_commentDepth": depth
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

    ScrollView {
        anchors.fill: parent
        anchors.topMargin: header.height
        anchors.leftMargin: units.gu(1)
        anchors.rightMargin: units.gu(1)

        flickableItem.maximumFlickVelocity: units.gu(500)

        ColumnLayout {
            //anchors.fill: parent
            id: redditPostParent
            spacing: units.gu(1)

            width: openedRedditPostPage.width - units.gu(2)

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

                Layout.leftMargin: units.gu(0.5)
                Layout.rightMargin: units.gu(0.5)

                model: ListModel {
                    id: commentModel
                    dynamicRoles: true
                }

                clip: true

                interactive: false

                // Some components used by the comments
                property var normalCommentLookComponent
                property var moreCommentLookComponent

                Component.onCompleted: {
                    normalCommentLookComponent = Qt.createComponent("NormalCommentLook.qml");
                    moreCommentLookComponent = Qt.createComponent("MoreCommentLook.qml");
                }

                Component {
                    id: commentDelegate
                    required property var _commentChild
                    required property int _commentDepth
                    Loader {
                        source: if(_commentChild.isMore) { return "MoreCommentLook.qml" } else { return "NormalCommentLook.qml" }
                    }
                }

                delegate: commentDelegate
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
