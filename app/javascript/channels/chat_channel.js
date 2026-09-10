import consumer from "channels/consumer"

let subscription
export function subscribeChat(conversationId, onMessage) {
  if (subscription) subscription.unsubscribe()
  subscription = consumer.subscriptions.create(
    { channel: "ChatChannel", conversation_id: conversationId || "global" },
    { received(data) { onMessage?.(data) } }
  )
}
