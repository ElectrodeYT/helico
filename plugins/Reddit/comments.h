#ifndef COMMENTS_H
#define COMMENTS_H

#include <QObject>
#include <QRandomGenerator>
#include <QNetworkAccessManager>
#include <QTimer>
#include <QVector>
#include <QJsonObject>

#include "request.h"

// JSON defines for classes
// Basically to make it easier to add bullshit in the future

#define addStringVariableForQML(name) QString name; \
    Q_PROPERTY(QString name MEMBER name CONSTANT FINAL)

#define addIntVariableForQML(name) int name = 0; \
    Q_PROPERTY(int name MEMBER name CONSTANT FINAL)

#define addBoolVariableForQML(name) bool name = false; \
    Q_PROPERTY(bool name MEMBER name CONSTANT FINAL)

#define addVarListVariableForQML(name) QVariantList name; \
    Q_PROPERTY(QVariantList name MEMBER name CONSTANT FINAL)

class MoreCommentChild {
    Q_GADGET
public:
    MoreCommentChild(const QJsonObject& object);
    MoreCommentChild() = default;

    addStringVariableForQML(name);
    addStringVariableForQML(id);
    addStringVariableForQML(parent_id);


    addIntVariableForQML(count);
    addIntVariableForQML(depth);

    addVarListVariableForQML(children);

    const bool isMore = true;
    Q_PROPERTY(bool isMore MEMBER isMore CONSTANT FINAL);
};

Q_DECLARE_METATYPE(MoreCommentChild);

// Not fully complete yet
class T1Child {
    Q_GADGET
public:
    T1Child(const QJsonObject& object);
    T1Child() = default;

    // String types
    addStringVariableForQML(subreddit);
    addStringVariableForQML(author);
    addStringVariableForQML(body);
    addStringVariableForQML(body_html);
    addStringVariableForQML(permalink);
    addStringVariableForQML(subreddit_name_prefixed);
    addStringVariableForQML(name);

    addStringVariableForQML(author_flair_type);
    addStringVariableForQML(author_flair_text);
    addStringVariableForQML(author_flair_richtext);

    // Int types
    addIntVariableForQML(ups);
    addIntVariableForQML(downs);
    addIntVariableForQML(score);

    addVarListVariableForQML(replies);

    addBoolVariableForQML(upvoted);
    addBoolVariableForQML(downvoted);

    const bool isMore = false;
    Q_PROPERTY(bool isMore MEMBER isMore CONSTANT FINAL);
};

Q_DECLARE_METATYPE(T1Child);

class CommentListing {
    Q_GADGET
public:
    addStringVariableForQML(after);
    addStringVariableForQML(before);
    addIntVariableForQML(dist);
    addStringVariableForQML(modhash);

    addVarListVariableForQML(comments);
};

Q_DECLARE_METATYPE(CommentListing);

#endif

