import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtMultimedia 5.4

import Reddit 1.0

ColumnLayout {
    property var postChild
    property bool inView: true


    property bool displayTextPreview: true
    property bool limitTextLength: true
    property bool acceptImageClicks: false

    // Image stuff
    // We convert it into properties because otherwise we get a billion errors
    property bool isImagePost: postChild.images.length !== 0
    property var redditImageToUse: isImagePost ? postChild.images[0] : null
    property string redditImageURL: isImagePost ? redditImageToUse.url : ""
    property int redditImageWidth: isImagePost ? redditImageToUse.width : 0
    property int redditImageHeight: isImagePost ? redditImageToUse.height : 0

    // Enable fliar MouseArea
    property bool enableFlairMouseArea: false

    property bool autoPlayVideo: false
    property bool videoAudioEnabled: false

    Component.onCompleted: {
        if(redditVideo.enabled && autoPlayVideo) {
            redditVideo.play()
        }
    }

    onAutoPlayVideoChanged: {
        if(redditVideo.enabled && autoPlayVideo) {
            redditVideo.play()
        }
        if(redditVideo.enabled && !autoPlayVideo) {
            redditVideo.stop()
            redditVideo.seek(0)
        }
    }

    Layout.alignment: Qt.AlignLeft
    Layout.fillWidth: true

    // Title and other things
    RowLayout {
        Layout.alignment: Qt.AlignLeft
        Layout.fillWidth: true

        // A Thumbnail, if we can find a suitable one
        Item {
            Layout.alignment: Qt.AlignLeft
            Layout.maximumWidth: units.gu(6)
            Layout.maximumHeight: units.gu(6)

            Layout.preferredWidth: Layout.maximumWidth
            Layout.preferredHeight: Layout.maximumHeight

            enabled: postChild.thumbnails.length > 0
            visible: enabled

            Image {
                source: (postChild.thumbnails.length && inView) ? postChild.thumbnails[postChild.thumbnails.length - 1] : ""
                enabled: source != "" && inView
                visible: enabled

                anchors.fill: parent
                Layout.fillWidth: true
                Layout.fillHeight: true
                fillMode: Image.PreserveAspectFit

                id: thumbnailImage
            }

            QtQuick.BusyIndicator {
                anchors.centerIn: parent
                Layout.alignment: Qt.AlignCenter
                enabled: thumbnailImage.enabled
                visible: (thumbnailImage.progress != 1) && inView && enabled
            }
        }

        // Subreddit, title, author
        ColumnLayout {
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: true
            Label {
                text: postChild.subreddit_name_prefixed + " | u/" + postChild.author + "\n" + postChild.time_ago_string
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                textSize: Label.Small
                Layout.fillWidth: true
            }

            Label {
                text: postChild.title
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                elide: Text.ElideRight
                maximumLineCount: limitTextLength ? 2 : 2000
                textSize: Label.Large

                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true
            }

            // Normal Flair
            Item {
                //width: normalFlair.enabled ? normalFlair.width : 0
                Layout.preferredHeight: normalFlair.enabled ? normalFlair.height : 0

                Layout.fillWidth: true

                enabled: postChild.link_flair_text !== ""
                visible: enabled

                FlairBox {
                    id: normalFlair
                    Layout.maximumWidth: parent.width

                    enabled: postChild.link_flair_text !== ""
                    visible: enabled

                    flairText: postChild.link_flair_text
                    boxBorderColour: postChild.link_flair_background_color
                }

                MouseArea {
    //                width: parent.width
    //                height: parent.height
                    anchors.fill: normalFlair
                    enabled: enableFlairMouseArea && postChild.link_flair_text !== ""

                    onClicked: {
                        print("should open flair search for flair ", postChild.link_flair_text)
                        var searchPostsPageComponent = Qt.createComponent("SearchPostsPage.qml");
                        if(searchPostsPageComponent.status !== Component.Ready) {
                            console.log("Error loading component: ", searchPostsPageComponent.errorString());
                            return;
                        }
                        var searchPostsPageObject = searchPostsPageComponent.createObject(null, {
                                                                           "subreddit": postChild.subreddit_name_prefixed,
                                                                           "search": "flair:\"" + postChild.link_flair_text + "\""
                                                                       } );
                        searchPostsPageObject.refetchPosts()
                        pageStack.push(searchPostsPageObject)
                    }
                }
            }
            // "Sticky flair"
            FlairBox {
                enabled: postChild.stickied
                visible: enabled

                flairText: "Stickied"
                boxBorderColour: "#21be2b"
            }
        }
    }

    // If we have images, then we display them here
    Item {
        Layout.fillWidth: true
        Layout.maximumWidth: redditImageWidth * 2
        //Layout.preferredHeight: postImage.paintedHeight
        Layout.preferredHeight: (redditImageHeight / redditImageWidth) * width
        Layout.alignment: Qt.AlignTop | Qt.AlignVCenter

        enabled: isImagePost
        visible: enabled

        AnimatedImage {
            enabled: isImagePost && inView
            visible: enabled
            source: redditImageURL
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: true
            verticalAlignment: Image.AlignTop
            autoTransform: true
            id: postImage
            anchors.fill: parent
            onStatusChanged: playing = (status == AnimatedImage.Ready)
            Layout.fillWidth: true
        }

        QtQuick.BusyIndicator {
            anchors.centerIn: parent
            visible: (postImage.progress != 1) && inView
        }

        ProgressBar {
            visible: (postImage.progress != 1) && inView
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: acceptImageClicks
            onClicked: {
                var imageViewPageComponent = Qt.createComponent("ImageViewPage.qml");
                if(imageViewPageComponent.status !== Component.Ready) {
                    console.log("Error loading component: ", imageViewPageComponent.errorString());
                    return;
                }
                var imageViewPageObject = imageViewPageComponent.createObject(null, {
                                                                   "url": redditImageURL
                                                               } );
                pageStack.push(imageViewPageObject);
            }
        }
    }

    // If this is a video post, then we add a video player here
  /*
    Item {
        Layout.fillWidth: true
        //Layout.maximumWidth: redditImageWidth * 2
        //Layout.preferredHeight: postImage.paintedHeight
        //Layout.preferredHeight: (redditImageHeight / redditImageWidth) * width
        Layout.alignment: Qt.AlignTop | Qt.AlignVCenter

        enabled: postChild.is_video
        visible: enabled
*/
        /*
        Video {
            id: redditVideo
            enabled: parent.enabled
            visible: enabled

            muted: !videoAudioEnabled
            audioRole: MediaPlayer.VideoRole

            Component.onCompleted: {
                // QML Spec says that source must be set after audioRole, this is safer
                if(redditVideo.enabled) {
                    redditVideo.source = postChild.video_url
                }
            }
        }
        */
/*
        AnimatedImage {
            id: redditVideo
            enabled: parent.enabled
            visible: enabled

            //muted: !videoAudioEnabled
            //audioRole: MediaPlayer.VideoRole

            Component.onCompleted: {
                // QML Spec says that source must be set after audioRole, this is safer
                if(redditVideo.enabled) {
                    redditVideo.source = postChild.video_url
                }
            }
        }
        */
    //}

    // Display short text preview
    Label {
        elide: Label.ElideRight
        maximumLineCount: 3
        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
        Layout.fillWidth: true
        text: postChild.selftext
        enabled: displayTextPreview && text !== ""
        visible: enabled
    }
}
