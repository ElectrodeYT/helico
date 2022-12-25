#include <QGuiApplication>
#include <QCoreApplication>
#include <QUrl>
#include <QString>
#include <QQuickView>

int main(int argc, char *argv[])
{
    QGuiApplication *app = new QGuiApplication(argc, (char**)argv);
    app->setApplicationName("helico.alexanderrichards");

    qDebug() << "Starting app from main.cpp";
    qDebug() << "Build version: " << QStringLiteral(BUILD_VERSION);

    QCoreApplication::setApplicationVersion(QStringLiteral(BUILD_VERSION));

    QQuickView *view = new QQuickView();
    view->setSource(QUrl("qrc:/Main.qml"));
    view->setResizeMode(QQuickView::SizeRootObjectToView);
    view->show();

    return app->exec();
}
