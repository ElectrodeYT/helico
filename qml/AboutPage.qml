import QtQuick 2.7
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Lomiri.Components 1.3
import Reddit 1.0

Page {
    header: PageHeader {
        title: i18n.tr("About")
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: header.height

        Image {
            id: logo

            source: "qrc:/assets/logo.png"

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: units.gu(3)

            fillMode: Image.PreserveAspectFit
            antialiasing: true

            property var bestWidthHeight: (parent.width < parent.height) ? parent.width : parent.height

            width: bestWidthHeight / 2
            height: bestWidthHeight / 2
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo.bottom
            anchors.topMargin: units.gu(2)

            text: {
                // TRANSLATORS: Add your name to the list after version informations like this:
                // "<br>Version %1<br>name-of-language translations by x,y,z,....
                var str = i18n.tr("<h1>Helico For Reddit</h1><br>Version %1").arg(Qt.application.version)
                return str
            }
            horizontalAlignment: Label.AlignHCenter
            textFormat: Label.StyledText
            id: logoText
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: logoText.bottom

            anchors.topMargin: units.gu(3)

            Button {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                text: "Github"
                onClicked: {
                    print("should open github")
                    Qt.openUrlExternally("https://github.com/ElectrodeYT/helico")
                }
            }

            Button {
                text: i18n.tr("Donate")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                onClicked: {
                    print("should open liberapay")
                    Qt.openUrlExternally("https://liberapay.com/Electrode")
                }
            }
        }
    }
}
