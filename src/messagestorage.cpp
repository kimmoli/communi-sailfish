/*
  Copyright (C) 2013-2014 The Communi Project

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Communi Project nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

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

#include "messagestorage.h"
#include "messageformatter.h"
#include "messagemodel.h"
#include <IrcBuffer>

MessageStorage::MessageStorage(QObject* parent) : QObject(parent), m_highlights(0)
{
    m_baseColor = QColor::fromHsl(359, 102, 116);
}

MessageStorage* MessageStorage::instance()
{
    static MessageStorage storage;
    return &storage;
}

QObject* MessageStorage::get(IrcBuffer* buffer) const
{
    return m_models.value(buffer);
}

IrcBuffer* MessageStorage::currentBuffer() const
{
    return m_current;
}

void MessageStorage::setCurrentBuffer(IrcBuffer* buffer)
{
    if (m_current != buffer) {
        if (m_current) {
            MessageModel* model = m_models.value(m_current);
            if (model)
                model->setCurrent(false);
        }
        if (buffer) {
            MessageModel* model = m_models.value(buffer);
            if (model)
                model->setCurrent(true);
        }
        m_current = buffer;
        emit currentBufferChanged(buffer);
    }
}

int MessageStorage::activeHighlights() const
{
    return m_highlights;
}

void MessageStorage::setActiveHighlights(int highlights)
{
    if (m_highlights != highlights) {
        m_highlights = highlights;
        emit activeHighlightsChanged();
    }
}

QColor MessageStorage::baseColor() const
{
    return m_baseColor;
}

void MessageStorage::setBaseColor(const QColor& color)
{
    if (m_baseColor != color) {
        m_baseColor = color;
        foreach (MessageModel* model, m_models)
            model->formatter()->setBaseColor(color);
    }
}

void MessageStorage::add(IrcBuffer* buffer)
{
    if (buffer && !m_models.contains(buffer)) {
        buffer->setPersistent(true);
        MessageModel* model = new MessageModel(buffer);
        model->formatter()->setBaseColor(m_baseColor);
        connect(buffer, SIGNAL(destroyed(IrcBuffer*)), this, SLOT(remove(IrcBuffer*)));
        connect(model, SIGNAL(activeHighlightsChanged()), this, SLOT(updateActiveHighlights()));
        connect(model, SIGNAL(received(IrcMessage*)), this, SLOT(onReceived(IrcMessage*)));
        connect(model, SIGNAL(highlighted(IrcMessage*)), this, SLOT(onHighlighted(IrcMessage*)));
        m_models.insert(buffer, model);
    }
}

void MessageStorage::remove(IrcBuffer* buffer)
{
    if (buffer && m_models.contains(buffer))
        delete m_models.take(buffer);
}

void MessageStorage::updateActiveHighlights()
{
    int highlights = 0;
    foreach (MessageModel* model, m_models)
        highlights += model->activeHighlights();
    setActiveHighlights(highlights);
}

void MessageStorage::onReceived(IrcMessage* message)
{
    MessageModel* model = qobject_cast<MessageModel*>(sender());
    if (model) {
        IrcBuffer* buffer = model->buffer();
        if (buffer)
            emit received(buffer, message);
    }
}

void MessageStorage::onHighlighted(IrcMessage* message)
{
    MessageModel* model = qobject_cast<MessageModel*>(sender());
    if (model) {
        IrcBuffer* buffer = model->buffer();
        if (buffer)
            emit highlighted(buffer, message);
    }
}
