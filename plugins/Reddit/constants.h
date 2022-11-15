#ifndef CONSTANTS_H
#define CONSTANTS_H

#include <QString>
#include <QTime>

const QString clientID = "W1tGIl2c8_LoP8wGGXihaQ";
const QString clientScope = "identity edit flair history modconfig modflair modlog modposts modwiki mysubreddits privatemessages read report save submit subscribe vote wikiedit wikiread";
const QString clientRequestURL = "https://www.reddit.com/api/v1/authorize.compact";
const QString clientTokenURL = "https://www.reddit.com/api/v1/access_token";

const QString clientAnonGrantType = "https://oauth.reddit.com/grants/installed_client";

const QString userAgent = "helico.alexanderrichards:v" BUILD_VERSION " (Ubuntu Touch / QT Simulator) by u/austroalex";

//
// PARTIALLY STOEN FROM STACKOVERFLOW
//
static inline QString secondsToString(qint64 time_seconds) {
    const qint64 DAY = 86400;
    QTime t = QTime(0,0).addSecs(time_seconds % DAY);
    qint64 days = time_seconds / DAY;
    qint64 hours = t.hour();
    qint64 minutes = t.minute();
    qint64 seconds = t.second();
    // We go with the highest, non zero one
    if(days) {
        return QString("%1 days ago").arg(days);
    } else if(hours) {
        return QString("%1 hours ago").arg(hours);
    } else if(minutes) {
        return QString("%1 minutes ago").arg(minutes);
    } else if(seconds) {
        return QString("%1 seconds ago").arg(seconds);
    } else {
        return QString("Just now");
    }
}

#endif // CONSTANTS_H
