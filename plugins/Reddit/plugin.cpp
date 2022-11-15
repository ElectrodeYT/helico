#include <QtQml>
#include <QtQml/QQmlContext>

#include "plugin.h"
#include "reddit.h"

void RedditPlugin::registerTypes(const char *uri) {
    //@uri Example
    qmlRegisterSingletonType<Reddit>(uri, 1, 0, "Reddit", [](QQmlEngine*, QJSEngine*) -> QObject* { return new Reddit; });
}
