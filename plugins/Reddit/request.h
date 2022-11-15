#ifndef REQUEST_H
#define REQUEST_H

#include <QObject>
#include <QRandomGenerator>
#include <QNetworkAccessManager>
#include <QTimer>
#include <QVector>

class Request : public QObject {
    Q_OBJECT
public:
    enum RequestType {
        Normal,
        AccessTokenFetch
    };

    enum HTTPType {
        GET,
        POST
    };

    explicit Request(const RequestType& type, QNetworkAccessManager* man, QObject* parent = 0) : QObject(parent), reply(0), request_type(type), manager(man) {
        ID = QRandomGenerator::global()->bounded(1, 100000);
        timeout_timer = new QTimer(this);
        timeout_timer->setSingleShot(true);
    }

    ~Request() {
        // we do not want to yeet manager
    }

    void addParameter(const QString& left, const QString& right) {
        parameters.insert(left, right);
    }
    void setClientSecret(const QString& id) { client_secret = id; }
    void setAccessToken(const QString& token) { access_token = token; }
    void setDeviceId(const QString& id) { device_id = id; }
    void setHttpType(const HTTPType& type) { http_type = type; }
    void setURL(const QUrl& url) { request_url = url; }
    quint32 send();
    void cancelRequest();

    // Basic auth stuff
    bool useBasicAuth;

    quint32 ID;

signals:
    void request_done(QNetworkReply* reply, quint32 id);
    void request_failed(quint32 id);
private slots:
    void on_request_done();
    void onTimeoutTimerFired();

private:
    QNetworkReply* reply;
    // The API spec _technically_ requires both, but we
    // dont have a client secret as we are a installed application
    // We "send" both for completeness
    QString client_secret;

    // Device ID to send to reddit
    QString device_id;

    // The Reddit access token
    QString access_token;

    // The parameters to use
    QHash<QString, QString> parameters;

    // The type of request
    RequestType request_type;
    HTTPType http_type;

    // Request destination
    QUrl request_url;

    // Timeout timer used to fail requests
    QTimer* timeout_timer;

    // Set when the request is being aborted
    bool beingAborted = false;

    // The manager used to talk to reddit
    QNetworkAccessManager* manager;
    QNetworkRequest request;
};

#endif
