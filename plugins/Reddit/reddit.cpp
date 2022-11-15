#include <QDebug>
#include <QtNetwork>
#include <QJsonObject>
#include "reddit.h"
#include "constants.h"

// JSON defines
// These just make the code for json look a little bit less cancerous
#define readIfExistsString(object, name, variable) { if(object.contains(name)) { variable = object[name].toString(); } }
#define readIfExistsInt(object, name, variable) { if(object.contains(name)) { variable = object[name].toInt(0); } }
#define readIfExistsBool(object, name, variable) { if(object.contains(name)) { variable = object[name].toBool(); } }
#define readIfExistsUInt64(object, name, variable) { if(object.contains(name)) { variable = object[name].toInteger(0); } }
#define checkAndCompareString(object, name, compared) (object.contains(name) && object[name] == compared)

Reddit::Reddit() {
    manager = new QNetworkAccessManager(this);
    accessTokenRefreshTimer = new QTimer(this);
    accessTokenRefreshTimer->setSingleShot(true);
}

void Reddit::connectToReddit(bool anon, QString savedRefreshToken) {
    qDebug() << "Reddit::login";
    qDebug() << "Used User agent: " << userAgent;
    // if(anon) { login without account } else { try to login using saved creds }
    Request* connectionRequest = new Request(Request::RequestType::AccessTokenFetch, manager, this);

    connectionRequest->setURL(QUrl("https://www.reddit.com/api/v1/access_token"));
    connectionRequest->setDeviceId(deviceID);
    connectionRequest->setClientSecret("");
    connectionRequest->setHttpType(Request::HTTPType::POST);


    if(!anon) {
        // Connect anonymously
        // Add the grant_type and device_id parameters
        connectionRequest->addParameter("grant_type", "https://oauth.reddit.com/grants/installed_client");
        connectionRequest->addParameter("device_id", deviceID);
    } else {
        // Attempt a refresh token auth
        qDebug() << "connecting with saved refresh token";
        Q_ASSERT(savedRefreshToken != "");
        connectionRequest->addParameter("grant_type", "refresh_token");
        connectionRequest->addParameter("refresh_token", savedRefreshToken);
    }

    connect(connectionRequest, SIGNAL(request_done(QNetworkReply*, quint32)), SLOT(onAccessTokenRequest(QNetworkReply*, quint32)));
    connect(connectionRequest, SIGNAL(request_failed(quint32)), SLOT(onAccessTokenRequestFailed(quint32)));

    currentRequests.push_back(connectionRequest);

    connectionRequest->send();
}

void Reddit::loginToReddit() {
    emit openBrowser(QUrl("https://www.reddit.com/api/v1/authorize.compact?client_id=" + clientID + "&response_type=code&state=LOGIN&redirect_uri=http://helico/&duration=permanent&scope=identity edit flair history modconfig modflair modlog modposts modwiki mysubreddits privatemessages read report save submit subscribe vote wikiedit wikiread"));
}

void Reddit::triggerLogout() {
    accessToken = "";
    refreshToken = "";

    emit commandRedditRestart(true, "", false, true);
}

void Reddit::loginURLRespone(const QString& url) {
    QUrlQuery url_query(url);
    // Check if we have an error
    QString error = url_query.queryItemValue("error", QUrl::PrettyDecoded);
    if(error != "") {
        qDebug() << "OAUTH returned an error: " << error;
        // TODO: inform user about error
        emit closeBrowser();
        return;
    }
    // Now we can read the code
    QString code = url_query.queryItemValue("code", QUrl::PrettyDecoded);
    if(code == "") { qDebug() << "code not existant"; emit closeBrowser(); return; }

    // The code can sometimes (for some reason) end with "#_"
    // We clean this out
    if(code.endsWith("#_", Qt::CaseSensitive)) {
        code.remove(code.length() - 2, 2);
    }

    // We have all we need to login to reddit again, send a command reddit restart command
    // At this moment, we still dont know if the login will work, so we dont send over much of anything
    // We do tell it to save a null refresh token and the hasLoggedIn flag, as if everything failes
    // there should be logic to clear it if there is no refresh token

    Request* connectionRequest = new Request(Request::RequestType::AccessTokenFetch, manager, this);

    connectionRequest->setURL(QUrl("https://www.reddit.com/api/v1/access_token"));
    connectionRequest->setDeviceId(deviceID);
    connectionRequest->setHttpType(Request::HTTPType::POST);
    connectionRequest->addParameter("code", code);
    connectionRequest->addParameter("redirect_uri", "http://helico/");
    connectionRequest->addParameter("grant_type", "authorization_code");

    connect(connectionRequest, SIGNAL(request_done(QNetworkReply*, quint32)), SLOT(onAccessTokenRequest(QNetworkReply*, quint32)));
    connect(connectionRequest, SIGNAL(request_failed(quint32)), SLOT(onAccessTokenRequestFailed(quint32)));

    currentRequests.push_back(connectionRequest);

    emit commandRedditRestart(true, "", true, false);
    connectionRequest->send();
}

quint32 Reddit::getSubreddits(QString search) {
    Request* request = new Request(Request::RequestType::Normal, manager, this);

    QString built_url = "https://oauth.reddit.com/subreddits/search/.json?limit=50&q=\"" + search + "\"";

    request->setAccessToken(accessToken);
    request->setURL(QUrl(built_url));
    request->setHttpType(Request::HTTPType::GET);

    connect(request, SIGNAL(request_done(QNetworkReply*, quint32)), SLOT(onSubredditRequest(QNetworkReply*, quint32)));

    currentRequests.push_back(request);

    qDebug() << "sending subreddit search request with id " << request->ID;
    return request->send();
}

void Reddit::onSubredditRequest(QNetworkReply* reply, quint32 id) {
    qDebug() << "got subreddit request with id " << id;
    if(reply->error() != QNetworkReply::NoError) {
        QString errorString = reply->errorString();
        qDebug() << "subreddit request returned an error: " << reply->error();
        delete reply;
        deleteRequest(id);
        emit requestError(id, errorString);
        return;
    }

    const QString replyString = QString::fromUtf8(reply->readAll());

    const QJsonDocument replyJsonDocument = QJsonDocument::fromJson(replyString.toUtf8());
    const QJsonObject replyJson = replyJsonDocument.object();

    QVariantList subreddits;

    if(checkAndCompareString(replyJson, "kind", "Listing")) {
        QJsonObject replyJsonData = replyJson["data"].toObject();
        QJsonArray replyJsonArray = replyJsonData["children"].toArray();
        for(int i = 0; i < replyJsonArray.size(); i++) {
            QJsonObject subredditSearchData = replyJsonArray[i].toObject()["data"].toObject();
            subreddits.append(QVariant::fromValue(T5Child(subredditSearchData)));
        }
    }

    deleteRequest(id);
    emit subredditRequest(id, subreddits);
}

void Reddit::onAccessTokenRequest(QNetworkReply* reply, quint32 id) {
    if(reply->error() != QNetworkReply::NoError) {
        qDebug() << "access token request returned an error: " << reply->error();
        delete reply;
        deleteRequest(id);
        emit linkingFailed();
        return;
    }

    const QString replyString = QString::fromUtf8(reply->readAll());

    const QJsonDocument replyJsonDocument = QJsonDocument::fromJson(replyString.toUtf8());
    const QJsonObject replyJson = replyJsonDocument.object();

    if(replyJson.contains("error")) {
        qDebug() << "access token JSON returned error: " << replyJson["error"].toString();
        delete reply;
        deleteRequest(id);
        emit linkingFailed();
        return;
    }

    if(replyJson.contains("access_token")) {
        qDebug() << "access token JSON returned access token";
        accessToken = replyJson["access_token"].toString();
    }

    if(replyJson.contains("refresh_token")) {
        qDebug() << "access token JSON returned refresh token";
        refreshToken = replyJson["refresh_token"].toString();

        emit saveRefreshToken(refreshToken);
    }

    if(replyJson.contains("expires_in")) {
        qDebug() << "access token JSON returned expiry time";
        accessTokenRefreshTimer->start(replyJson["expires_in"].toInt(10000) * 1000 * 0.9); // reddit sends it in seconds, we refresh when 10% of the time is left
        // TODO: refresh logic
    }

    if(!accessToken.isEmpty()) {
        emit linkingSucceeded();
    }
}

void Reddit::onAccessTokenRequestFailed(quint32 id) {
    // Delete the request
    deleteRequest(id);

    emit linkingFailed();
}

T5Child::T5Child(const QJsonObject& object) {
    readIfExistsString(object, "display_name_prefixed", display_name_prefixed);
    readIfExistsString(object, "icon_img", icon_img);
}
