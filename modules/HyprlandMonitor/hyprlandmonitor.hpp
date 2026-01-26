/*Creating essentials for hyprland states monitoring and interaction*/
#pragma once
#include <QJsonArray>
#include <QJsonObject>
#include <QLocalSocket>
#include <QObject>
#include <QTimer>
#include <QVariantMap>
#include <qqmlintegration.h>

class HyprlandMonitor : public QObject {
  Q_OBJECT
  QML_ELEMENT;

  Q_PROPERTY(QJsonArray windowList READ windowList NOTIFY windowListChanged)
  Q_PROPERTY(QJsonArray workspaces READ workspaces NOTIFY workspacesChanged)
  Q_PROPERTY(QJsonArray monitors READ monitors NOTIFY monitorsChanged)
  Q_PROPERTY(QJsonObject activeWorkspace READ activeWorkspace NOTIFY
                 activeWorkspaceChanged)
  Q_PROPERTY(QJsonObject focusedMonitor READ focusedMonitor NOTIFY
                 focusedMonitorChanged)
  Q_PROPERTY(int activeWorkspaceId READ activeWorkspaceId NOTIFY
                 activeWorkspaceChanged)
  Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
  Q_PROPERTY(QVariantMap windowByAddressMap READ windowByAddressMap NOTIFY
                 windowListChanged)
  Q_PROPERTY(QVariantMap workspaceByIdMap READ workspaceByIdMap NOTIFY
                 workspacesChanged)
  Q_PROPERTY(
      QVariantList workspaceIds READ workspaceIds NOTIFY workspacesChanged)
  Q_PROPERTY(QVariantList addresses READ addresses NOTIFY windowListChanged)

public:
  explicit HyprlandMonitor(QObject *parent = nullptr);
  ~HyprlandMonitor();

  QJsonArray windowList() const { return m_windowList; }
  QJsonArray workspaces() const { return m_workspaces; }
  QJsonArray monitors() const { return m_monitors; }
  QJsonObject activeWorkspace() const { return m_activeWorkspace; }
  QJsonObject focusedMonitor() const { return m_focusedMonitor; }
  int activeWorkspaceId() const {
    return m_activeWorkspace.value("id").toInt(-1);
  }
  bool connected() const { return m_connected; }
  QVariantMap windowByAddressMap() const;
  QVariantMap workspaceByIdMap() const;
  QVariantList workspaceIds() const;
  QVariantList addresses() const;

  Q_INVOKABLE void refresh();
  Q_INVOKABLE QJsonObject windowByAddress(const QString &address);
  Q_INVOKABLE QJsonObject workspaceById(int id);
  Q_INVOKABLE QJsonObject biggestWindowForWorkspace(int workspaceId);
  Q_INVOKABLE void dispatch(const QString &command);

signals:
  void windowListChanged();
  void workspacesChanged();
  void monitorsChanged();
  void activeWorkspaceChanged();
  void focusedMonitorChanged();
  void connectedChanged();
  void hyprlandEvent(const QString &event, const QJsonObject &data);

private slots:
  void onEventSocketReadyRead();
  void connectToHyprland();
  void requestData();

private:
  void sendRequest(const QString &command);
  void sendDispatch(const QString &command);
  void processEvent(const QString &eventLine);
  void parseResponse(const QByteArray &data, const QString &type);
  void updateFocusedMonitor();
  QString getSocketPath();

  QLocalSocket *m_requestSocket;
  QLocalSocket *m_eventSocket;
  QJsonArray m_windowList;
  QJsonArray m_workspaces;
  QJsonArray m_monitors;
  QJsonObject m_activeWorkspace;
  QJsonObject m_focusedMonitor;
  QByteArray m_eventBuffer;
  bool m_connected;
  QString m_hyprlandInstance;
  QTimer *m_debounceTimer;
};
