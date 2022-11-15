#include <QDebug>
#include <QtNetwork>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include "comments.h"
#include "reddit.h"
#include "constants.h"

// JSON defines
// These just make the code for json look a little bit less cancerous
#define readIfExistsString(object, name, variable) { if(object.contains(name)) { variable = object[name].toString(); } }
#define readIfExistsInt(object, name, variable) { if(object.contains(name)) { variable = object[name].toInt(0); } }
#define readIfExistsBool(object, name, variable) { if(object.contains(name)) { variable = object[name].toBool(); } }
#define readIfExistsUInt64(object, name, variable) { if(object.contains(name)) { variable = object[name].toInteger(0); } }
#define checkAndCompareString(object, name, compared) (object.contains(name) && object[name] == compared)

// Not really a comment function, but putting it in reddit.cpp felt wrong and
// im not going to make a file for this alone
// (unless more things that are for both comments and posts pop up i guess)
quint32 Reddit::setVote(QString id, int state) {
    Request* request = new Request(Request::RequestType::Normal, manager, this);

    request->setAccessToken(accessToken);
    request->setURL(QUrl("https://oauth.reddit.com/api/vote"));
    request->setHttpType(Request::HTTPType::POST);

    request->addParameter("dir", QString::number(state));
    request->addParameter("id", id);
    request->addParameter("rank", "2");

//    currentRequests.push_back(request);

    qDebug() << "sending comments request with id " << request->ID << "; id " << id << " state " << state;
    return request->send();
}

quint32 Reddit::getComments(QString post_id) {
    Request* request = new Request(Request::RequestType::Normal, manager, this);

    QString built_url = "https://oauth.reddit.com/comments/" + post_id + "/.json?limit=500&depth=10&raw_json=1";

    request->setAccessToken(accessToken);
    request->setURL(QUrl(built_url));
    request->setHttpType(Request::HTTPType::GET);

    connect(request, SIGNAL(request_done(QNetworkReply*, quint32)), SLOT(onCommentRequest(QNetworkReply*, quint32)));

    currentRequests.push_back(request);

    qDebug() << "sending comments request with id " << request->ID;
    return request->send();
}

quint32 Reddit::getMoreComments(QString link, QVariantList children) {
    Request* request = new Request(Request::RequestType::Normal, manager, this);

    QString built_url = "https://oauth.reddit.com/api/morechildren/.json?limit=100&depth=5&api_type=json&raw_json=1&link_id=" + link + "&children=";

    for(int i = 0; i < children.size(); i++) {
        built_url += children[i].toString();
        if(i != (children.size() - 1)) { built_url += ","; }
    }

    built_url += "";

    request->setAccessToken(accessToken);
    request->setURL(QUrl(built_url));
    request->setHttpType(Request::HTTPType::GET);

    connect(request, SIGNAL(request_done(QNetworkReply*, quint32)), SLOT(onCommentRequest(QNetworkReply*, quint32)));

    currentRequests.push_back(request);

    qDebug() << "sending more comments request with id " << request->ID;
    qDebug() << "url: " << built_url;
    return request->send();
}

void Reddit::onCommentRequest(QNetworkReply* reply, quint32 id) {
    qDebug() << "got comment request with id " << id;
    if(reply->error() != QNetworkReply::NoError) {
        QString errorString = reply->errorString();
        qDebug() << "comment request returned an error: " << reply->error();
        delete reply;
        deleteRequest(id);
        emit requestError(id, errorString);
        return;
    }

    const QString replyString = QString::fromUtf8(reply->readAll());

    const QJsonDocument replyJsonDocument = QJsonDocument::fromJson(replyString.toUtf8());
    const QJsonArray replyJson = replyJsonDocument.array();
    const QJsonObject replyCommentListing = replyJson[1].toObject();

    CommentListing listing;

    if(checkAndCompareString(replyCommentListing, "kind", "Listing")) {
        qDebug() << "got comment listing";
        QJsonObject replyCommentData = replyCommentListing["data"].toObject();
        readIfExistsString(replyCommentData, "after", listing.after);
        readIfExistsString(replyCommentData, "before", listing.before);
        readIfExistsString(replyCommentData, "modhash", listing.modhash);
        readIfExistsInt(replyCommentData, "dist", listing.dist);

        QJsonArray replyCommentArray = replyCommentData["children"].toArray();
        for(int i = 0; i < replyCommentArray.size(); i++) {
            QJsonObject commentContainer = replyCommentArray[i].toObject();
            if(checkAndCompareString(commentContainer, "kind", "t1")) {
                listing.comments.append(QVariant::fromValue(T1Child(commentContainer["data"].toObject())));
            } else if(checkAndCompareString(commentContainer, "kind", "more")) {
                listing.comments.append(QVariant::fromValue(MoreCommentChild(commentContainer["data"].toObject())));
            }
        }
    }

    deleteRequest(id);
    emit commentsRequest(id, listing);
}

void Reddit::onMoreCommentsRequest(QNetworkReply* reply, quint32 id) {
    qDebug() << "got more comments request with id " << id;
    if(reply->error() != QNetworkReply::NoError) {
        QString errorString = reply->errorString();
        qDebug() << "more comments request returned an error: " << reply->error();
        delete reply;
        deleteRequest(id);
        emit requestError(id, errorString);
        return;
    }

    const QString replyString = QString::fromUtf8(reply->readAll());

    const QJsonDocument replyJsonDocument = QJsonDocument::fromJson(replyString.toUtf8());
    const QJsonArray replyJson = replyJsonDocument.array();
    const QJsonObject replyCommentListing = replyJson[1].toObject();

    qDebug() << replyString;
}

MoreCommentChild::MoreCommentChild(const QJsonObject& object) {
    readIfExistsString(object, "name", name);
    readIfExistsString(object, "id", id);
    readIfExistsString(object, "parent_id", parent_id);

    readIfExistsInt(object, "count", count);
    readIfExistsInt(object, "depth", depth);

    if(object.contains("children") && object["children"].isArray()) {
        QJsonArray childrenArray = object["children"].toArray();
        for(int i = 0; i < childrenArray.size(); i++) {
            children.append(QVariant::fromValue(childrenArray[i].toString()));
        }
    }
}

T1Child::T1Child(const QJsonObject& object) {
    readIfExistsString(object, "subreddit", subreddit);
    readIfExistsString(object, "author", author);
    readIfExistsString(object, "body", body);
    readIfExistsString(object, "body_html", body_html);
    readIfExistsString(object, "permalink", permalink);
    readIfExistsString(object, "subreddit_name_prefixed", subreddit_name_prefixed);
    readIfExistsString(object, "name", name);

    readIfExistsString(object, "author_flair_type", author_flair_type);
    readIfExistsString(object, "author_flair_text", author_flair_text);
    readIfExistsString(object, "author_flair_richtext", author_flair_richtext);

    readIfExistsInt(object, "ups", ups);
    readIfExistsInt(object, "downs", downs);
    readIfExistsInt(object, "score", score);

    if(object.contains("replies") && object["replies"].isObject()) {
        QJsonObject repliesJsonObject = object["replies"].toObject();
        if(checkAndCompareString(repliesJsonObject, "kind", "Listing")) {
            QJsonArray repliesArray = repliesJsonObject["data"].toObject()["children"].toArray();

            for(int i = 0; i < repliesArray.size(); i++) {
                QJsonObject reply = repliesArray[i].toObject();
                if(checkAndCompareString(reply, "kind", "t1")) {
                    replies.append(QVariant::fromValue(T1Child(reply["data"].toObject())));
                } else if(checkAndCompareString(reply, "kind", "more")) {
                    replies.append(QVariant::fromValue(MoreCommentChild(reply["data"].toObject())));
                }
            }
        }
    }

    // The "likes" bit is slightly complicated, as it
    //  a) requires being logged in
    //  b) can be null sometimes
    // If it doesnt exist, or is null, it should be safe
    // to say that either the user is logged out or hasnt voted
    if(!object.contains("likes") || object["likes"].isNull()) {
        upvoted = false;
        downvoted = false;
    } else {
        if(object["likes"].isBool()) {
            upvoted = object["likes"].toBool(false);
            downvoted = !object["likes"].toBool(true);
        }
    }
}
