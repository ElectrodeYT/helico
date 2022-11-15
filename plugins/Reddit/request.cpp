#include <QtNetwork>
#include "request.h"
#include "constants.h"


//
// STOLEN FROM QUICKDDIT
//
// REPLACE AT SOME POINT
QByteArray toEncodedQuery(const QHash<QString, QString> &parameters)
{
    QByteArray encodedQuery;
    QHashIterator<QString, QString> i(parameters);
    while (i.hasNext()) {
        i.next();
        encodedQuery += QUrl::toPercentEncoding(i.key()) + '=' + QUrl::toPercentEncoding(i.value()) + '&';
    }
    encodedQuery.chop(1); // chop the last '&'
    return encodedQuery;
}

quint32 Request::send() {
    // Some sanity stuff
    Q_ASSERT(reply == 0);
    if(request_type == RequestType::AccessTokenFetch) {
        Q_ASSERT(!device_id.isEmpty());
        Q_ASSERT(http_type == HTTPType::POST);
    }

    // Setup timer
    connect(timeout_timer, SIGNAL(timeout()), SLOT(onTimeoutTimerFired()));
    timeout_timer->start(10000);

    // Create request
    request.setUrl(request_url);
    request.setRawHeader("User-Agent", userAgent.toLatin1());
    if(request_type == RequestType::AccessTokenFetch) {
        // Create auth structure
        QByteArray auth_header;
        auth_header = "Basic " + (clientID.toLatin1() + ":" + client_secret.toLatin1()).toBase64();
        request.setRawHeader("Authorization", auth_header);
    } else if(request_type == RequestType::Normal) {
        if(!access_token.isEmpty()) {
            QByteArray auth_header;
            auth_header = "Bearer " + access_token.toLatin1();
            request.setRawHeader("Authorization", auth_header);
        }
    }

    if(http_type == HTTPType::POST) {
        request.setRawHeader("Content-Type", "application/x-www-form-urlencoded");
        reply = manager->post(request, toEncodedQuery(parameters));
    } else if(http_type == HTTPType::GET) {
        reply = manager->get(request);
    } else {
        qDebug() << "Request::send(): invalid http type!";
    }

    reply->setParent(this);
    connect(reply, SIGNAL(finished()), SLOT(on_request_done()));

    return ID;
}

void Request::cancelRequest() {
    reply->disconnect();
    reply->abort();
}

void Request::on_request_done() {
    if(beingAborted) { return; }
    timeout_timer->stop();
    QByteArray remaining = reply->rawHeader("X-Ratelimit-Remaining");
    QByteArray reset = reply->rawHeader("X-Ratelimit-Reset");
    qDebug() << "Reddit Rate Limit: Remaining: " << remaining.constData() << " Reset: " << reset.constData();

    emit request_done(reply, ID);
}


void Request::onTimeoutTimerFired() {
    qDebug() << "Request::onTimeoutTimerFired";
    beingAborted = true;
    reply->disconnect();
    reply->abort();

    emit request_failed(ID);
}
