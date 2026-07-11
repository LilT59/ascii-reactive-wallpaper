#include "pointertracker.h"
#include "asciirenderer.h"

#include <QQmlExtensionPlugin>
#include <qqml.h>
#include <QPointF>

class AsciiReactivePointerPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override
    {
        qRegisterMetaType<QPointF>();
        qmlRegisterSingletonType<PointerTracker>(uri, 1, 0, "PointerTracker",
            [](QQmlEngine *, QJSEngine *) -> QObject * {
                return new PointerTracker;
            });
        qmlRegisterType<AsciiRenderer>(uri, 1, 0, "AsciiRenderer");
    }
};

#include "pointerplugin.moc"
