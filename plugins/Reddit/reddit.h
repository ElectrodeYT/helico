#ifndef EXAMPLE_H
#define EXAMPLE_H

#include <QObject>
#include <QRandomGenerator>
#include <QNetworkAccessManager>
#include <QTimer>
#include <QVector>

#include "posts.h"
#include "comments.h"
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


class RedditImage {
    Q_GADGET
public:
    addStringVariableForQML(url);
    addIntVariableForQML(width);
    addIntVariableForQML(height);
};

Q_DECLARE_METATYPE(RedditImage);

class T5Child {
    Q_GADGET
public:
    T5Child(const QJsonObject& object);
    T5Child() = default;

    addStringVariableForQML(display_name_prefixed);
    addStringVariableForQML(icon_img);
};

Q_DECLARE_METATYPE(T5Child);

class Reddit : public QObject {
    Q_OBJECT

public:
    Reddit();
    ~Reddit() = default;

    Q_INVOKABLE void speak();
    Q_INVOKABLE void connectToReddit(bool anon, QString savedRefreshToken);

    Q_INVOKABLE void loginToReddit();
    Q_INVOKABLE void triggerLogout();
    Q_INVOKABLE void loginURLRespone(const QString& url);

    Q_INVOKABLE quint32 getPosts(QString url, QString sort, QString sortTime);
    Q_INVOKABLE quint32 getMorePosts(QString url, QString sort, QString sortTime, QString after);

    Q_INVOKABLE quint32 getPostsWithSearch(QString url, QString search);

    Q_INVOKABLE quint32 getSubreddits(QString search);

    Q_INVOKABLE quint32 getComments(QString post_id);
    Q_INVOKABLE quint32 getMoreComments(QString link, QVariantList children);

    Q_INVOKABLE quint32 setVote(QString id, int state);

private:
    QNetworkAccessManager* manager;
    QVector<Request*> currentRequests;

    QString deviceID = "DO_NOT_TRACK_THIS_DEVICE";

    QString accessToken = "";
    QString refreshToken = "";


    QTimer* accessTokenRefreshTimer;

    void deleteRequest(quint32 id) {
        for(int i = 0; i < currentRequests.size(); i++) {
            if(currentRequests[i]->ID == id) { delete currentRequests[i]; currentRequests.remove(i); break; }
        }
    }

private slots:

    // Request handling signals
    void onAccessTokenRequest(QNetworkReply* reply, quint32 id);
    void onAccessTokenRequestFailed(quint32 id);

    void onPostsRequest(QNetworkReply* reply, quint32 id);
    void onSubredditRequest(QNetworkReply* reply, quint32 id);
    void onCommentRequest(QNetworkReply* reply, quint32 id);
    void onMoreCommentsRequest(QNetworkReply* reply, quint32 id);

    void onRequestTimedOut(quint32 id);
Q_SIGNALS:
    void openBrowser(const QUrl& url);
    void closeBrowser();

    void saveRefreshToken(QString refreshToken);

    void linkingSucceeded();
    void linkingFailed();

    void requestError(quint32 id, QString error);

    void postsRequest(quint32 id, PostListing postListing);
    void subredditRequest(quint32 id, QVariantList subreddits);
    void commentsRequest(quint32 id, CommentListing commentListing);

    // Restarts the entire app, by going back to the main QML frame and
    // restarting the authentication process
    // Used during account login or logout
    void commandRedditRestart(bool comesWithRefreshToken, QString newRefreshToken, bool newHasLoggedIn, bool callConnect);
};

#endif
