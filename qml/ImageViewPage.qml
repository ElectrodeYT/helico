import QtQuick 2.7
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Lomiri.Components 1.3
import Reddit 1.0

Page {
    property string url: ""

    id: imageViewPage

    header: PageHeader {
        title: "Image"
        subtitle: url
    }

    function resetPosition() {
        postImage.width = postImageContainer.width
        postImage.height = postImageContainer.height
        //postImage.x = Screen.orientation === Qt.PortraitOrientation ? (Screen.width - postImage.width)/2 : (Screen.height - postImage.height)/2
        //postImage.x = 0
        //postImage.y = 0
    }

    property bool isPortrait: Screen.primaryOrientation === Qt.PortraitOrientation || Screen.primaryOrientation === Qt.InvertedPortraitOrientation
    property bool isLandscape: Screen.primaryOrientation === Qt.LandscapeOrientation || Screen.primaryOrientation === Qt.InvertedLandscapeOrientation

    onIsPortraitChanged: resetPosition()
    onIsLandscapeChanged: resetPosition()

    Component.onCompleted: resetPosition()

    Item {
        anchors.fill: parent
        anchors.topMargin: header.height
        height: root.height - header.height
        enabled: isImagePost
        visible: enabled

        id: postImageContainer

        AnimatedImage {
            source: url
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: true
            verticalAlignment: Image.AlignTop
            autoTransform: true
            id: postImage
            onStatusChanged: playing = (status === AnimatedImage.Ready)
            //width: parent.width
            //height: parent.height
            x: parent.width / 2 - this.width / 2
            y: parent.height / 2 - this.height / 2
        }

        QtQuick.BusyIndicator {
            anchors.centerIn: parent
            visible: (postImage.progress != 1)
        }

        ProgressBar {
            visible: (postImage.progress != 1)
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        drag.target: postImage
        drag.axis: Drag.XAndYAxis

        //drag.minimumX: -postImage.width
        //drag.minimumY: -postImage.height
        drag.minimumX: -(postImage.width - postImageContainer.width)
        drag.minimumY: -(postImage.height - postImageContainer.height)
        //drag.maximumX: postImage.width
        //drag.maximumY: postImage.height
        drag.maximumX: postImage.width - postImageContainer.width
        drag.maximumY: postImage.height - postImageContainer.height

        drag.filterChildren: true

        // propagateComposedEvents: true

        scrollGestureEnabled: false

        PinchArea {
            anchors.fill: parent
            pinch.target: postImage
            pinch.minimumRotation: 0
            pinch.maximumRotation: 0
            pinch.minimumScale: 1
            pinch.maximumScale: 10

//            pinch.minimumX: -postImage.width
//            pinch.minimumY: -postImage.height
//            pinch.maximumX: postImage.width
//            pinch.maximumY: postImage.height

            pinch.dragAxis: Pinch.NoDrag
        }
    }
}
