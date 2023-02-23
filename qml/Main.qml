import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Lomiri.Components.Popups 1.3 as Popups
import Reddit 1.0

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'helico.alexanderrichards'
    automaticOrientation: true

    theme.name: {
        if (settings.theme == 1) {
            return "Lomiri.Components.Themes.Ambiance";
        } else if (settings.theme == 2) {
            return "Lomiri.Components.Themes.SuruDark";
        } else {
            return "";
        }
    }


    function connectToReddit() {
        if(settings.hasLoggedIn && settings.savedRefreshToken == "") {
            // The initial login has failed, so we clear the hasLoggedIn state
            print("recovering from failed login")
            settings.hasLoggedIn = false;
        }

        Reddit.connectToReddit(settings.hasLoggedIn, settings.savedRefreshToken)
    }

    QtQuick.BusyIndicator {
        id: busyIndicatorMainPage
        enabled: true
        visible: enabled
        anchors.centerIn: parent
    }
    Component {
        id: linkingErrorDialogComponent
        Popups.Dialog {
            id: linkingErrorDialog
            title: "Error"
            text: i18n.tr("Linking with Reddit failed.")

            Button {
                text: i18n.tr("Retry")
                onClicked: {
                    connectToReddit()
                    Popups.PopupUtils.close(linkingErrorDialog)
                }
            }

            Button {
                text: i18n.tr("Retry (logout and login as anonymous)")
                onClicked: {
                    settings.savedRefreshToken = ""
                    settings.hasLoggedIn = ""
                    connectToReddit()
                    Popups.PopupUtils.close(linkingErrorDialog)
                }
            }
        }
    }
    Connections {
        target: Reddit
        onOpenBrowser: {
            print("openBrowser")
            print("url: " + url)
            var loginPageComponent = Qt.createComponent("LoginPage.qml");
            if(loginPageComponent.status !== Component.Ready) {
                print("Error loading login page component: " + loginPageComponent.errorString())
                return;
            }

            var loginPageObject = loginPageComponent.createObject(null, { "url": url })

            pageStack.push(loginPageObject)
        }

        onLinkingSucceeded: {
            print("reddit authed successfully")
            busyIndicatorMainPage.enabled = false
            pageStack.push(Qt.resolvedUrl("MainPostsPage.qml"));
        }

        onLinkingFailed: {
            print("reddit auth failed")
            Popups.PopupUtils.open(linkingErrorDialogComponent)
        }

        onCommandRedditRestart: {
            if(comesWithRefreshToken) {
                settings.savedRefreshToken = newRefreshToken
                settings.hasLoggedIn = newHasLoggedIn
            }
            pageStack.clear()

            if(callConnect) {
                connectToReddit()
            }
        }

        onSaveRefreshToken: {
            print("got new refresh token", refreshToken)

            settings.savedRefreshToken = refreshToken
        }
    }

    Settings {
        id: settings
        property bool hasLoggedIn: false
        property string savedRefreshToken: ""
        property int theme: 0
    }

    PageStack {
        id: pageStack

        Component.onCompleted: {
            connectToReddit()
        }
    }
}
