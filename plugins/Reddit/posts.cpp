#include <QObject>
#include <QRandomGenerator>
#include <QNetworkAccessManager>
#include <QTimer>
#include <QVector>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkReply>

#include "posts.h"
#include "request.h"
#include "constants.h"
#include "reddit.h"

// JSON defines
// These just make the code for json look a little bit less cancerous
#define readIfExistsString(object, name, variable) { if(object.contains(name)) { variable = object[name].toString(); } }
#define readIfExistsInt(object, name, variable) { if(object.contains(name)) { variable = object[name].toInt(0); } }
#define readIfExistsBool(object, name, variable) { if(object.contains(name)) { variable = object[name].toBool(); } }
#define readIfExistsUInt64(object, name, variable) { if(object.contains(name)) { variable = object[name].toInteger(0); } }
#define checkAndCompareString(object, name, compared) (object.contains(name) && object[name] == compared)

quint32 Reddit::getPosts(QString url, QString sort, QString sortTime = "") {
    Request* request = new Request(Request::RequestType::Normal, manager, this);

    QString built_url = "https://oauth.reddit.com/" + url + "/" + sort +  ".json?limit=50&raw_json=1";

    if(!sortTime.isEmpty()) {
        built_url += "&t=" + sortTime;
    }

    request->setAccessToken(accessToken);
    request->setURL(QUrl(built_url));
    request->setHttpType(Request::HTTPType::GET);

    connect(request, SIGNAL(request_done(QNetworkReply*, quint32)), SLOT(onPostsRequest(QNetworkReply*, quint32)));

    currentRequests.push_back(request);

    qDebug() << "sending posts request for subreddit URL " << url << " with id " << request->ID;
    return request->send();
}

quint32 Reddit::getMorePosts(QString url, QString sort, QString sortTime, QString after) {
    Request* request = new Request(Request::RequestType::Normal, manager, this);

    QString built_url = "https://oauth.reddit.com/" + url + "/" + sort + ".json?limit=50&raw_json=1&after=" + after;

    if(!sortTime.isEmpty()) {
        built_url += "&t=" + sortTime;
    }

    request->setAccessToken(accessToken);
    request->setURL(QUrl(built_url));
    request->setHttpType(Request::HTTPType::GET);

    connect(request, SIGNAL(request_done(QNetworkReply*, quint32)), SLOT(onPostsRequest(QNetworkReply*, quint32)));

    currentRequests.push_back(request);

    qDebug() << "sending posts request for subreddit URL " << url << " with id " << request->ID;
    return request->send();
}

quint32 Reddit::getPostsWithSearch(QString url, QString search) {
    Request* request = new Request(Request::RequestType::Normal, manager, this);

    QString built_url = "https://oauth.reddit.com/" + url + "/search.json?limit=50&raw_json=1&restrict_sr=on&q=\"" + search + "\"";

    request->setAccessToken(accessToken);
    request->setURL(QUrl(built_url));
    request->setHttpType(Request::HTTPType::GET);

    connect(request, SIGNAL(request_done(QNetworkReply*, quint32)), SLOT(onPostsRequest(QNetworkReply*, quint32)));

    currentRequests.push_back(request);

    qDebug() << "sending search posts request for subreddit URL " << url << " with search " << search << "and id " << request->ID;
    return request->send();
}

void Reddit::onPostsRequest(QNetworkReply* reply, quint32 id) {
    qDebug() << "got posts request with id " << id;
    if(reply->error() != QNetworkReply::NoError) {
        QString errorString = reply->errorString();
        qDebug() << "posts request returned an error: " << reply->error();
        delete reply;
        deleteRequest(id);
        emit requestError(id, errorString);
        return;
    }

    const QString replyString = QString::fromUtf8(reply->readAll());

    const QJsonDocument replyJsonDocument = QJsonDocument::fromJson(replyString.toUtf8());
    const QJsonObject replyJson = replyJsonDocument.object();

    PostListing listing;

    if(checkAndCompareString(replyJson, "kind", "Listing")) {
        qDebug() << "got listing";

        readIfExistsString(replyJson["data"].toObject(), "after", listing.after);
        readIfExistsString(replyJson["data"].toObject(), "before", listing.before);
        readIfExistsInt(replyJson["data"].toObject(), "dist", listing.dist);
        readIfExistsString(replyJson["data"].toObject(), "modhash", listing.modhash);


        if(!replyJson["data"].toObject()["children"].isArray()) {
            qDebug() << "children not array";
        } else {
            QJsonArray children = replyJson["data"].toObject()["children"].toArray();
            for(int i = 0; i < children.size(); i++) {
                QJsonObject child = children[i].toObject();
                if(child["kind"] == "t3") {
                    QJsonObject childData = child["data"].toObject();
                    listing.children.append(QVariant::fromValue(T3Child(childData)));
                }
            }
        }
    }


    deleteRequest(id);
    emit postsRequest(id, listing);
}

T3Child::T3Child(const QJsonObject& object) {
    readIfExistsString(object, "subreddit", subreddit);
    readIfExistsString(object, "selftext", selftext);
    readIfExistsString(object, "title", title);
    readIfExistsString(object, "subreddit_name_prefixed", subreddit_name_prefixed);
    readIfExistsString(object, "name", name);
    readIfExistsString(object, "link_flair_text", link_flair_text);
    readIfExistsString(object, "thumbnail", thumbnail);
    readIfExistsString(object, "post_hint", post_hint);
    readIfExistsString(object, "subreddit_type", subreddit_type);
    readIfExistsString(object, "link_flair_type", link_flair_type);
    readIfExistsString(object, "link_flair_background_color", link_flair_background_color);
    readIfExistsString(object, "subreddit_id", subreddit_id);
    readIfExistsString(object, "author", author);
    readIfExistsString(object, "permalink", permalink);
    readIfExistsString(object, "selftext_html", selftext_html)
    readIfExistsString(object, "id", id);

    readIfExistsInt(object, "num_comments", num_comments);
    readIfExistsInt(object, "ups", ups);
    readIfExistsInt(object, "downs", downs);
    readIfExistsInt(object, "score", score);

    readIfExistsBool(object, "stickied", stickied);
    readIfExistsBool(object, "is_video", is_video);

    // Calculate time of post and create string for time
    uint64_t unix_timestamp = QDateTime::currentSecsSinceEpoch();
    uint64_t created_timestamp = 0;
    // TODO: y2k23 but in Qt 5.15
    // WHen qt6 starts existing on ubuntu touch we should use the .toInteger version
    readIfExistsInt(object, "created", created_timestamp);

    time_ago_string = secondsToString(unix_timestamp - created_timestamp);

    // Create the list of acceptable thumbnails
    // We disable preview generation for image posts, as we dont use them
    if(object.contains("preview") && object["preview"].isObject() && post_hint != "image") {
        QJsonObject previewObject = object["preview"].toObject();
        if(previewObject.contains("images") && previewObject["images"].isArray()) {
            QJsonArray previewImages = previewObject["images"].toArray();
            for(int i = 0; i < previewImages.size(); i++) {
                QJsonObject imageObject = previewImages[i].toObject();
                if(imageObject.contains("resolutions") && imageObject["resolutions"].isArray()) {
                    QJsonArray imageResolutionsArray = imageObject["resolutions"].toArray();
                    for(int y = 0; y < imageResolutionsArray.size(); y++) {
                        QJsonObject imageResolution = imageResolutionsArray[y].toObject();
                        if(imageResolution.contains("url") && imageResolution["url"].isString()) {
                            thumbnails.append(QVariant::fromValue(imageResolution["url"].toString()));
                        }
                    }
                }
            }
        }
    }

    // If the post is a image post, then we generate a QVariant of all images
    if(post_hint == "image" && object.contains("preview") && object["preview"].isObject()) {
        QJsonObject previewObject = object["preview"].toObject();
        if(previewObject.contains("images") && previewObject["images"].isArray()) {
            QJsonArray previewImages = previewObject["images"].toArray();
            for(int i = 0; i < previewImages.size(); i++) {
                QJsonObject imageObject = previewImages[i].toObject();
                if(imageObject.contains("source") && imageObject["source"].isObject()) {
                    QJsonObject imageSourceObject = imageObject["source"].toObject();
                    if(imageSourceObject.contains("url") && imageSourceObject["url"].isString()) {
                        RedditImage redditImage;
                        redditImage.url = imageSourceObject["url"].toString();
                        redditImage.width = imageSourceObject["width"].toInt();
                        redditImage.height = imageSourceObject["height"].toInt();

                        images.append(QVariant::fromValue(redditImage));
                    }
                }
            }
        }
    }

    // If the post is a video (is_video is true) we check media for the video
    // For post_hint = "hosted:video" the video should be under media/reddit_video
    if(is_video) {
        if(post_hint == "hosted:video") {
            if(object.contains("media") && object["media"].isObject()) {
                QJsonObject mediaObject = object["media"].toObject();
                if(mediaObject.contains("reddit_video") && mediaObject["reddit_video"].isObject()) {
                    QJsonObject reddit_videoObject = mediaObject["reddit_video"].toObject();
                    // We currently use the fallback URL, as i do not want to figure out how DASH/HSL works lol
                    // TODO: fix this
                    if(reddit_videoObject.contains("fallback_url") && reddit_videoObject["fallback_url"].isString()) {
                        video_url = reddit_videoObject["fallback_url"].toString();
                    }
                }
            }
        } else {
            qDebug() << "Unknown video post post_hint: " << post_hint;
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
