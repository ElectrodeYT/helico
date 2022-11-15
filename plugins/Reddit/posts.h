#ifndef POSTS_H
#define POSTS_H

#include <QObject>
#include <QRandomGenerator>
#include <QNetworkAccessManager>
#include <QTimer>
#include <QVector>
#include <QJsonObject>

#include "request.h"

#define addStringVariableForQML(name) QString name; \
    Q_PROPERTY(QString name MEMBER name CONSTANT FINAL)

#define addIntVariableForQML(name) int name = 0; \
    Q_PROPERTY(int name MEMBER name CONSTANT FINAL)

#define addBoolVariableForQML(name) bool name = false; \
    Q_PROPERTY(bool name MEMBER name CONSTANT FINAL)

#define addVarListVariableForQML(name) QVariantList name; \
    Q_PROPERTY(QVariantList name MEMBER name CONSTANT FINAL)

// Not fully complete yet
class T3Child {
    Q_GADGET
public:
    T3Child(const QJsonObject& object);
    T3Child() = default;

    // String types
    addStringVariableForQML(subreddit);
    addStringVariableForQML(selftext);
    addStringVariableForQML(title);
    addStringVariableForQML(subreddit_name_prefixed);
    addStringVariableForQML(name);
    addStringVariableForQML(link_flair_text);
    addStringVariableForQML(thumbnail);
    addStringVariableForQML(post_hint);
    addStringVariableForQML(subreddit_type);
    addStringVariableForQML(link_flair_type);
    addStringVariableForQML(link_flair_background_color);
    addStringVariableForQML(subreddit_id);
    addStringVariableForQML(author);
    addStringVariableForQML(permalink);
    addStringVariableForQML(selftext_html);
    addStringVariableForQML(id);
    addStringVariableForQML(video_url);

    // Int types
    addIntVariableForQML(num_comments);
    addIntVariableForQML(ups);
    addIntVariableForQML(downs);
    addIntVariableForQML(score);

    // Bool types
    addBoolVariableForQML(stickied);
    addBoolVariableForQML(upvoted);
    addBoolVariableForQML(downvoted);
    addBoolVariableForQML(is_video);

    addStringVariableForQML(time_ago_string);

    addVarListVariableForQML(thumbnails);
    addVarListVariableForQML(images);
};

Q_DECLARE_METATYPE(T3Child);

class PostListing{
    Q_GADGET
public:
    addStringVariableForQML(after);
    addStringVariableForQML(before);
    addIntVariableForQML(dist);
    addStringVariableForQML(modhash);

    QVariantList children;
    Q_PROPERTY(QVariantList children MEMBER children CONSTANT FINAL)
};

Q_DECLARE_METATYPE(PostListing);

#endif
