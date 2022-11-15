#ifndef EXAMPLE_PLUGIN_H
#define EXAMPLE_PLUGIN_H

#include <QQmlExtensionPlugin>

class RedditPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri);
};

#endif
