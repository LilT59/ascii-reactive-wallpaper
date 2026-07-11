#pragma once

#include <QObject>
#include <QPointF>
#include <QTimer>

class PointerTracker : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QPointF globalPosition READ globalPosition NOTIFY globalPositionChanged)

public:
    explicit PointerTracker(QObject *parent = nullptr);
    QPointF globalPosition() const;

signals:
    void globalPositionChanged();
    void pressed(QPointF globalPosition, int button);

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

private:
    void updatePosition();

    QPointF m_globalPosition;
    QTimer m_timer;
};
