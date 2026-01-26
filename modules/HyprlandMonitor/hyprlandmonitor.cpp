#include "hyprlandmonitor.hpp"
#include <QDebug>
#include <QDir>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <unistd.h>

HyprlandMonitor::HyprlandMonitor(QObject *parent)
    : QObject(parent), m_requestSocket(new QLocalSocket(this)),
      m_eventSocket(new QLocalSocket(this)), m_connected(false),
      m_debounceTimer(new QTimer(this)) {
  m_hyprlandInstance = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE");

  if (m_hyprlandInstance.isEmpty()) {
    QString xdgRuntime = qEnvironmentVariable("XDG_RUNTIME_DIR");
    if (xdgRuntime.isEmpty()) {
      xdgRuntime = QString("/run/user/%1").arg(getuid());
    }

    QDir hyprDir(xdgRuntime + "/hypr");
    if (hyprDir.exists()) {
      QStringList entries =
          hyprDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
      if (!entries.isEmpty()) {
        m_hyprlandInstance = entries.first();
      }
    }
  }

  if (m_hyprlandInstance.isEmpty()) {
    qWarning() << "Could not find Hyprland instance!";
    return;
  }

  m_debounceTimer->setSingleShot(true);
  m_debounceTimer->setInterval(50);
  connect(m_debounceTimer, &QTimer::timeout, this,
          &HyprlandMonitor::requestData);

  connect(m_eventSocket, &QLocalSocket::readyRead, this,
          &HyprlandMonitor::onEventSocketReadyRead);

  connectToHyprland();
}

HyprlandMonitor::~HyprlandMonitor() {
  if (m_requestSocket->state() == QLocalSocket::ConnectedState) {
    m_requestSocket->disconnectFromServer();
  }
  if (m_eventSocket->state() == QLocalSocket::ConnectedState) {
    m_eventSocket->disconnectFromServer();
  }
}

QString HyprlandMonitor::getSocketPath() {
  QString xdgRuntime = qEnvironmentVariable("XDG_RUNTIME_DIR");
  if (xdgRuntime.isEmpty()) {
    xdgRuntime = QString("/run/user/%1").arg(getuid());
  }
  return QString("%1/hypr/%2/.socket.sock").arg(xdgRuntime, m_hyprlandInstance);
}

void HyprlandMonitor::connectToHyprland() {
  QString xdgRuntime = qEnvironmentVariable("XDG_RUNTIME_DIR");
  if (xdgRuntime.isEmpty()) {
    xdgRuntime = QString("/run/user/%1").arg(getuid());
  }

  QString eventSocketPath =
      QString("%1/hypr/%2/.socket2.sock").arg(xdgRuntime, m_hyprlandInstance);

  m_eventSocket->connectToServer(eventSocketPath);
  if (!m_eventSocket->waitForConnected(1000)) {
    qWarning() << "Can't connect to event socket";
    return;
  }

  m_connected = true;
  emit connectedChanged();

  requestData();
}

void HyprlandMonitor::sendRequest(const QString &command) {
  QLocalSocket *socket = new QLocalSocket(this);
  socket->connectToServer(getSocketPath());

  if (!socket->waitForConnected(500)) {
    socket->deleteLater();
    return;
  }

  socket->write(QString("j/%1").arg(command).toUtf8());
  socket->flush();
  socket->waitForReadyRead(1000);

  QByteArray response = socket->readAll();
  socket->disconnectFromServer();
  socket->deleteLater();

  parseResponse(response, command);
}

void HyprlandMonitor::sendDispatch(const QString &command) {
  QLocalSocket socket;
  socket.connectToServer(getSocketPath());

  if (!socket.waitForConnected(500)) {
    return;
  }

  socket.write(QString("dispatch %1").arg(command).toUtf8());
  socket.flush();
  socket.waitForBytesWritten(500);
  socket.disconnectFromServer();

  QTimer::singleShot(100, this, &HyprlandMonitor::requestData);
}

void HyprlandMonitor::parseResponse(const QByteArray &data,
                                    const QString &type) {
  QJsonParseError error;
  QJsonDocument doc = QJsonDocument::fromJson(data, &error);

  if (error.error != QJsonParseError::NoError) {
    return;
  }

  if (type == "clients" && doc.isArray()) {
    m_windowList = doc.array();
    emit windowListChanged();
  } else if (type == "workspaces" && doc.isArray()) {
    m_workspaces = doc.array();
    emit workspacesChanged();
  } else if (type == "monitors" && doc.isArray()) {
    m_monitors = doc.array();
    updateFocusedMonitor();
    emit monitorsChanged();
  } else if (type == "activeworkspace" && doc.isObject()) {
    m_activeWorkspace = doc.object();
    emit activeWorkspaceChanged();
  }
}

void HyprlandMonitor::updateFocusedMonitor() {
  for (const QJsonValue &val : m_monitors) {
    QJsonObject mon = val.toObject();
    if (mon["focused"].toBool()) {
      m_focusedMonitor = mon;
      emit focusedMonitorChanged();
      return;
    }
  }
}

void HyprlandMonitor::onEventSocketReadyRead() {
  m_eventBuffer.append(m_eventSocket->readAll());

  while (m_eventBuffer.contains('\n')) {
    int newlineIndex = m_eventBuffer.indexOf('\n');
    QByteArray line = m_eventBuffer.left(newlineIndex);
    m_eventBuffer = m_eventBuffer.mid(newlineIndex + 1);

    QString eventLine = QString::fromUtf8(line).trimmed();
    if (!eventLine.isEmpty()) {
      processEvent(eventLine);
    }
  }
}

void HyprlandMonitor::processEvent(const QString &eventLine) {
  QStringList parts = eventLine.split(">>");
  if (parts.size() < 1)
    return;

  QString eventName = parts[0];

  if (eventName == "openwindow" || eventName == "closewindow" ||
      eventName == "movewindow" || eventName == "movewindowv2") {
    requestData();
  } else if (eventName == "workspace" || eventName == "focusedmon" ||
             eventName == "activewindow" || eventName == "changefloatingmode") {
    m_debounceTimer->start();
  }

  QJsonObject eventObj;
  eventObj["name"] = eventName;
  eventObj["data"] = parts.size() > 1 ? parts[1] : "";
  emit hyprlandEvent(eventName, eventObj);
}

void HyprlandMonitor::requestData() {
  sendRequest("clients");
  sendRequest("workspaces");
  sendRequest("monitors");
  sendRequest("activeworkspace");
}

void HyprlandMonitor::refresh() { requestData(); }

void HyprlandMonitor::dispatch(const QString &command) {
  sendDispatch(command);
}

QJsonObject HyprlandMonitor::windowByAddress(const QString &address) {
  for (const QJsonValue &val : m_windowList) {
    QJsonObject win = val.toObject();
    if (win["address"].toString() == address) {
      return win;
    }
  }
  return QJsonObject();
}

QJsonObject HyprlandMonitor::workspaceById(int id) {
  for (const QJsonValue &val : m_workspaces) {
    QJsonObject ws = val.toObject();
    if (ws["id"].toInt() == id) {
      return ws;
    }
  }
  return QJsonObject();
}

QJsonObject HyprlandMonitor::biggestWindowForWorkspace(int workspaceId) {
  QJsonObject biggest;
  int maxArea = 0;

  for (const QJsonValue &val : m_windowList) {
    QJsonObject win = val.toObject();
    QJsonObject workspace = win["workspace"].toObject();

    if (workspace["id"].toInt() == workspaceId) {
      QJsonArray size = win["size"].toArray();
      int area = size[0].toInt() * size[1].toInt();

      if (area > maxArea) {
        maxArea = area;
        biggest = win;
      }
    }
  }
  return biggest;
}

QVariantMap HyprlandMonitor::windowByAddressMap() const {
  QVariantMap map;
  for (const QJsonValue &val : m_windowList) {
    QJsonObject win = val.toObject();
    QString addr = win["address"].toString();
    if (!addr.isEmpty()) {
      map[addr] = win;
    }
  }
  return map;
}

QVariantMap HyprlandMonitor::workspaceByIdMap() const {
  QVariantMap map;
  for (const QJsonValue &val : m_workspaces) {
    QJsonObject ws = val.toObject();
    int id = ws["id"].toInt(-1);
    if (id != -1) {
      map[QString::number(id)] = ws;
    }
  }
  return map;
}

QVariantList HyprlandMonitor::workspaceIds() const {
  QVariantList ids;
  for (const QJsonValue &val : m_workspaces) {
    QJsonObject ws = val.toObject();
    if (ws.contains("id")) {
      ids.append(ws["id"].toInt());
    }
  }
  return ids;
}

QVariantList HyprlandMonitor::addresses() const {
  QVariantList addrs;
  for (const QJsonValue &val : m_windowList) {
    QJsonObject win = val.toObject();
    QString addr = win["address"].toString();
    if (!addr.isEmpty()) {
      addrs.append(addr);
    }
  }
  return addrs;
}
