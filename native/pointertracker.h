#pragma once

#include <QObject>
#include <QPointF>
#include <QTimer>

class PointerTracker : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QPointF globalPosition READ globalPosition NOTIFY globalPositionChanged)
    Q_PROPERTY(bool onBattery READ onBattery NOTIFY onBatteryChanged)

public:
    explicit PointerTracker(QObject *parent = nullptr);
    QPointF globalPosition() const;
    bool onBattery() const { return m_onBattery; }

signals:
    void globalPositionChanged();
    void pressed(qreal x, qreal y, int button);
    void onBatteryChanged();

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

private:
    void updatePosition();
    void updateBatteryState();

    QPointF m_globalPosition;
    QTimer m_timer;
    QTimer m_batteryTimer;
    bool m_onBattery = false;
};
