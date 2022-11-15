import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtWebView 1.1

import Reddit 1.0

Page {
    id: loginPage

    property string url: ""

    WebView {
        id: loginWebView
        anchors.fill: parent

        onUrlChanged: {
            console.log(url);
            var test = /^http:\/\/helico\//
            if(test.test(url)) {
                loginWebView.visible = false;
                Reddit.loginURLRespone(url)
            }
        }
    }

    Connections {
        target: Reddit
        onCloseBrowser: { pageStack.pop(); }
    }

    Component.onCompleted: { loginWebView.url = url; }
}
