#include "pointertracker.h"

#include <QCoreApplication>
#include <QCursor>
#include <QEvent>
#include <QMouseEvent>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>

PointerTracker::PointerTracker(QObject *parent)
    : QObject(parent)
    , m_globalPosition(QCursor::pos())
{
    qApp->installEventFilter(this);
    m_timer.setInterval(16);
    connect(&m_timer, &QTimer::timeout, this, &PointerTracker::updatePosition);
    m_timer.start();
    m_batteryTimer.setInterval(10000);
    connect(&m_batteryTimer, &QTimer::timeout, this, &PointerTracker::updateBatteryState);
    m_batteryTimer.start();
    updateBatteryState();
}

void PointerTracker::updateBatteryState()
{
    QDBusInterface properties(QStringLiteral("org.freedesktop.UPower"),
                              QStringLiteral("/org/freedesktop/UPower"),
                              QStringLiteral("org.freedesktop.DBus.Properties"),
                              QDBusConnection::systemBus());
    const QDBusReply<QVariant> reply = properties.call(QStringLiteral("Get"),
        QStringLiteral("org.freedesktop.UPower"), QStringLiteral("OnBattery"));
    if (!reply.isValid()) return;
    const bool value = reply.value().toBool();
    if (m_onBattery == value) return;
    m_onBattery = value;
    emit onBatteryChanged();
}

QPointF PointerTracker::globalPosition() const
{
    return m_globalPosition;
}

void PointerTracker::updatePosition()
{
    const QPointF position = QCursor::pos();
    if (position == m_globalPosition)
        return;

    m_globalPosition = position;
    emit globalPositionChanged();
}

bool PointerTracker::eventFilter(QObject *watched, QEvent *event)
{
    Q_UNUSED(watched)
    if (event->type() == QEvent::MouseButtonPress) {
        const auto *mouseEvent = static_cast<QMouseEvent *>(event);
        emit pressed(mouseEvent->globalPosition().x(),
                     mouseEvent->globalPosition().y(),
                     static_cast<int>(mouseEvent->button()));
    }
    return false;
}
