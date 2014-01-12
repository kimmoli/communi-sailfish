/*
  Copyright (C) 2013-2014 Robin Burchell <robin+git@viroteck.net>
  Copyright (C) 2013-2014 J-P Nurmi <jpnurmi@gmail.com>

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.1
import harbour.communi 3.1
import Sailfish.Silica 1.0

Page {
    id: page

    property IrcBuffer buffer
    property alias contentItem: column
    readonly property alias contentHeight: view.height

    anchors.fill: parent

    Binding {
        target: MessageStorage.get(buffer)
        property: "active"
        value: Qt.application.active && page.status === PageStatus.Active
    }

    Column {
        id: column

        z: -1
        width: page.width
        height: page.height

        SilicaListView {
            id: view

            width: parent.width
            height: parent.height - entry.height

            PullDownMenu {
                id: pullDownMenu
                MenuItem {
                    text: qsTr("About IRC")
                    onClicked: pageStack.push(Qt.resolvedUrl("../dialogs/AboutDialog.qml"))
                }
                MenuItem {
                    text: qsTr("Clear messages")
                    enabled: MessageStorage.get(buffer).count
                    onClicked: {
                        // TODO: why the view position jumps?
                        MessageStorage.get(buffer).clear()
                    }
                }
                MenuItem {
                    text: qsTr("Jump to bottom")
                    onClicked: {
                        view.cancelFlick();
                        view.positionViewAtEnd();
                    }
                }
            }

            PushUpMenu {
                id: pushUpMenu
                transform: Translate { y: entry.height }
                MenuItem {
                    text: qsTr("Join a channel")
                    visible: BufferModel.connections.length > 0
                    onClicked: pageStack.push(joinDialog, {model: BufferModel.models})
                }
                MenuItem {
                    text: qsTr("Open a query")
                    visible: BufferModel.models.length > 0
                    onClicked: pageStack.push(queryDialog, {model: BufferModel.models})
                }
                MenuItem {
                    text: qsTr("Connect a network")
                    onClicked: pageStack.push(connectDialog)
                }
                MenuItem {
                    text: qsTr("Jump to top")
                    onClicked: {
                        view.cancelFlick();
                        view.positionViewAtBeginning();
                    }
                }
            }

            header: PageHeader { title: buffer ? buffer.title : "" }

            model: MessageStorage.get(buffer)

            delegate: ListItem {
                contentHeight: label.height
                Label {
                    id: label
                    text: richtext
                    anchors { left: parent.left; right: parent.right; margins: Theme.paddingLarge }
                    wrapMode: Text.Wrap
                    linkColor: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeSmall
                    onLinkActivated: Qt.openUrlExternally(link)
                    color: highlight ? Theme.highlightColor : seen ? Theme.secondaryColor : Theme.primaryColor
                }
                menu: Component {
                    ContextMenu {
                        MenuItem {
                            text: qsTr("Copy")
                            onClicked: Clipboard.text = plaintext
                        }
                    }
                }
            }

            Component.onCompleted: {
                view.positionViewAtEnd();
            }
            onCountChanged: {
                if (view.visibleArea.yPosition + view.visibleArea.heightRatio > 0.9) {
                    positioner.restart();
                }
            }

            // <workaround>
            // the RIGHT WAY would be to listen to Qt.inputMethod.animatingChanged instead
            // details: https://together.jolla.com/question/8611/bug-qinputmethodanimatingchanged-is-never-emitted/
            onHeightChanged: {
                positioner.restart();
            }
            // </workaround>

            VerticalScrollDecorator { }
        }

        TextEntry {
            id: entry
            buffer: page.buffer
            width: parent.width

            backgroundVisible: !positioner.running && !pushUpMenu.active && !view.atYEnd
            opacity: pullDownMenu.active || pushUpMenu.active ? 0.0 : 1.0
            Behavior on opacity { FadeAnimation { } }
        }
    }

    Timer {
        id: positioner
        interval: 100
        onTriggered: {
            view.cancelFlick();
            view.positionViewAtEnd();
        }
        triggeredOnStart: false
        running: false
        repeat: false
    }
}
